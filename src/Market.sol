// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title P2PMarket
 * @dev A P2P market contract for trading between two ERC20 tokens
 */
contract P2PMarket is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    // Order structure
    struct Order {
        uint256 orderId;
        address seller;
        address tokenToSell; // Token being sold
        address tokenToPay; // Token used for payment
        uint256 amountToSell; // Total amount to sell
        uint256 amountRemaining; // Remaining amount to sell
        uint256 pricePerToken; // Price in tokenToPay per unit of tokenToSell
        uint256 minOrderSize; // Minimum order size for partial fills
        uint256 createdAt;
    }

    // State variables
    uint256 private _latestOrderId;
    mapping(uint256 id => Order) public orders;

    // Events
    event OrderPlaced(
        uint256 indexed orderId,
        address indexed seller,
        address indexed tokenToSell,
        address tokenToPay,
        uint256 amountToSell,
        uint256 pricePerToken,
        uint256 minOrderSize
    );

    event OrderFilled(
        uint256 indexed orderId,
        address indexed buyer,
        uint256 amountFilled,
        uint256 paymentAmount
    );

    event OrderCancelled(uint256 indexed orderId, address indexed seller);
    event OrderUpdated(
        uint256 indexed orderId,
        uint256 newPrice,
        uint256 newMinOrderSize
    );

    modifier onlyEOA() {
        require(sendIsNotContract(), "Only EOA can call this function");
        _;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Place a new sell order
     * @param tokenToSell Address of the token being sold
     * @param tokenToPay Address of the token used for payment
     * @param amountToSell Total amount to sell
     * @param pricePerToken Price in tokenToPay per unit of tokenToSell
     * @param minOrderSize Minimum order size for partial fills
     */
    function placeOrder(
        address tokenToSell,
        address tokenToPay,
        uint256 amountToSell,
        uint256 pricePerToken,
        uint256 minOrderSize
    ) external nonReentrant whenNotPaused onlyEOA {
        require(
            tokenToSell != address(0) && tokenToPay != address(0),
            "Invalid token addresses"
        );
        require(tokenToSell != tokenToPay, "Tokens must be different");
        require(amountToSell > 0, "Amount must be greater than 0");
        require(pricePerToken > 0, "Price must be greater than 0");
        require(
            minOrderSize > 0 && minOrderSize <= amountToSell,
            "Invalid min order size"
        );

        IERC20(tokenToSell).transferFrom(
            msg.sender,
            address(this),
            amountToSell
        );

        _latestOrderId++;
        uint256 orderId = _latestOrderId;

        orders[orderId] = Order({
            orderId: orderId,
            seller: msg.sender,
            tokenToSell: tokenToSell,
            tokenToPay: tokenToPay,
            amountToSell: amountToSell,
            amountRemaining: amountToSell,
            pricePerToken: pricePerToken,
            minOrderSize: minOrderSize,
            createdAt: block.timestamp
        });

        emit OrderPlaced(
            orderId,
            msg.sender,
            tokenToSell,
            tokenToPay,
            amountToSell,
            pricePerToken,
            minOrderSize
        );
    }

    /**
     * @dev Fill an order (partially or fully)
     * @param orderId ID of the order to fill
     * @param amountToBuy Amount of tokenToSell to buy
     * @param maxPricePerToken Maximum price per token to pay. It prevents front-run and sand-wich attack.
     */
    function fillOrder(
        uint256 orderId,
        uint256 amountToBuy,
        uint256 maxPricePerToken
    ) external nonReentrant whenNotPaused {
        Order storage order = orders[orderId];
        require(amountToBuy > 0, "Amount must be greater than 0");
        require(
            amountToBuy <= order.amountRemaining,
            "Amount exceeds remaining supply"
        );
        require(
            amountToBuy >= order.minOrderSize,
            "Amount below minimum order size"
        );
        require(
            order.pricePerToken <= maxPricePerToken,
            "Price exceeds max price"
        );

        uint256 paymentAmount = (amountToBuy * order.pricePerToken) /
            (10 ** ERC20(order.tokenToSell).decimals());

        order.amountRemaining -= amountToBuy;

        if (order.amountRemaining == 0) {
            delete orders[orderId];
        }

        IERC20(order.tokenToPay).transferFrom(
            msg.sender,
            address(this),
            paymentAmount
        );
        IERC20(order.tokenToSell).transfer(msg.sender, amountToBuy);
        IERC20(order.tokenToPay).transfer(order.seller, paymentAmount);

        emit OrderFilled(orderId, msg.sender, amountToBuy, paymentAmount);
    }

    /**
     * @dev Cancel an order (seller only)
     * @param orderId ID of the order to cancel
     */
    function cancelOrder(uint256 orderId) external nonReentrant whenNotPaused {
        Order memory order = orders[orderId];
        require(order.seller == msg.sender, "Only seller can cancel");

        // Return remaining tokens to seller
        if (order.amountRemaining > 0) {
            IERC20(order.tokenToSell).transfer(
                order.seller,
                order.amountRemaining
            );
        }

        delete orders[orderId];

        emit OrderCancelled(orderId, msg.sender);
    }

    /**
     * @dev Update order price and minimum order size (seller only)
     * @param orderId ID of the order to update
     * @param newPrice New price per token
     * @param newMinOrderSize New minimum order size
     */
    function updateOrder(
        uint256 orderId,
        uint256 newPrice,
        uint256 newMinOrderSize
    ) external whenNotPaused {
        Order storage order = orders[orderId];
        require(order.seller == msg.sender, "Only seller can update");
        require(newPrice > 0, "Price must be greater than 0");
        require(
            newMinOrderSize > 0 && newMinOrderSize <= order.amountRemaining,
            "Invalid min order size"
        );

        order.pricePerToken = newPrice;
        order.minOrderSize = newMinOrderSize;

        emit OrderUpdated(orderId, newPrice, newMinOrderSize);
    }

    /**
     * @dev Get order details
     * @param orderId ID of the order
     * @return Order details
     */
    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    /**
     * @dev Get total number of orders
     * @return Total order count
     */
    function getTotalOrders() external view returns (uint256) {
        return _latestOrderId;
    }

    /**
     * @dev Emergency function to recover stuck tokens (owner only)
     * @param token Address of the token to recover
     * @param amount Amount to recover
     * @param to Address to send tokens to
     */
    function emergencyRecover(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        IERC20(token).transfer(to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function sendIsNotContract() internal view returns (bool) {
        // check size code
        // check sender == origin
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        return size == 0 && sender == tx.origin;
    }
}

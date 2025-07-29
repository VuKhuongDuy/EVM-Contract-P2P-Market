// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Market.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 tokens for testing
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract MarketTest is Test {
    P2PMarket public market;
    MockToken public tokenA;
    MockToken public tokenB;

    address public seller = address(0x1);
    address public buyer = address(0x2);
    address public feeCollector = address(0x3);

    uint256 public constant INITIAL_BALANCE = 10000 * 10 ** 18;

    function setUp() public {
        // Deploy market
        market = new P2PMarket();

        // Deploy mock tokens
        tokenA = new MockToken("Token A", "TKA");
        tokenB = new MockToken("Token B", "TKB");

        // Setup initial balances
        tokenA.transfer(seller, INITIAL_BALANCE);
        tokenB.transfer(buyer, INITIAL_BALANCE);

        // Setup users
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(feeCollector, "FeeCollector");
        vm.label(address(market), "Market");
        vm.label(address(tokenA), "TokenA");
        vm.label(address(tokenB), "TokenB");
    }

    function test_PlaceOrder() public {
        vm.startPrank(seller);

        uint256 amountToSell = 1000 * 10 ** 18;
        uint256 pricePerToken = 2 * 10 ** 18; // 2 TokenB per TokenA
        uint256 minOrderSize = 100 * 10 ** 18;

        // Approve market to spend tokens
        tokenA.approve(address(market), amountToSell);

        // Place order
        market.placeOrder(
            address(tokenA),
            address(tokenB),
            amountToSell,
            pricePerToken,
            minOrderSize
        );

        vm.stopPrank();

        // Verify order was created
        P2PMarket.Order memory order = market.getOrder(1);
        assertEq(order.seller, seller);
        assertEq(order.tokenToSell, address(tokenA));
        assertEq(order.tokenToPay, address(tokenB));
        assertEq(order.amountToSell, amountToSell);
        assertEq(order.amountRemaining, amountToSell);
        assertEq(order.pricePerToken, pricePerToken);
        assertEq(order.minOrderSize, minOrderSize);
    }

    function test_FillOrderPartially() public {
        // Setup: Place an order
        vm.startPrank(seller);
        uint256 amountToSell = 1000 * 10 ** 18;
        uint256 pricePerToken = 2 * 10 ** 18;
        uint256 minOrderSize = 100 * 10 ** 18;

        tokenA.approve(address(market), amountToSell);
        market.placeOrder(
            address(tokenA),
            address(tokenB),
            amountToSell,
            pricePerToken,
            minOrderSize
        );
        vm.stopPrank();

        // Fill order partially
        vm.startPrank(buyer);
        uint256 amountToBuy = 500 * 10 ** 18;
        uint256 expectedPayment = (amountToBuy * pricePerToken) / 1e18;

        tokenB.approve(address(market), expectedPayment);
        market.fillOrder(1, amountToBuy);
        vm.stopPrank();

        // Verify order was partially filled
        P2PMarket.Order memory order = market.getOrder(1);
        assertEq(order.amountRemaining, amountToSell - amountToBuy);
    }

    function test_FillOrderFully() public {
        // Setup: Place an order
        vm.startPrank(seller);
        uint256 amountToSell = 1000 * 10 ** 18;
        uint256 pricePerToken = 2 * 10 ** 18;
        uint256 minOrderSize = 100 * 10 ** 18;

        tokenA.approve(address(market), amountToSell);
        market.placeOrder(
            address(tokenA),
            address(tokenB),
            amountToSell,
            pricePerToken,
            minOrderSize
        );
        vm.stopPrank();

        // Fill order fully
        vm.startPrank(buyer);
        uint256 expectedPayment = (amountToSell * pricePerToken) / 1e18;

        tokenB.approve(address(market), expectedPayment);
        market.fillOrder(1, amountToSell);
        vm.stopPrank();

        // Verify order was fully filled and deactivated
        P2PMarket.Order memory order = market.getOrder(1);
        assertEq(order.amountRemaining, 0);
    }

    function test_CancelOrder() public {
        // Setup: Place an order
        vm.startPrank(seller);
        uint256 amountToSell = 1000 * 10 ** 18;
        uint256 pricePerToken = 2 * 10 ** 18;
        uint256 minOrderSize = 100 * 10 ** 18;

        tokenA.approve(address(market), amountToSell);
        market.placeOrder(
            address(tokenA),
            address(tokenB),
            amountToSell,
            pricePerToken,
            minOrderSize
        );
        vm.stopPrank();

        // Cancel order
        vm.prank(seller);
        market.cancelOrder(1);

        // Verify order was cancelled
        P2PMarket.Order memory order = market.getOrder(1);
        assertEq(order.amountRemaining, 0);
        assertEq(order.orderId, 0);

        // Verify tokens were returned to seller
        assertEq(tokenA.balanceOf(seller), INITIAL_BALANCE);
    }

    function test_UpdateOrder() public {
        // Setup: Place an order
        vm.startPrank(seller);
        uint256 amountToSell = 1000 * 10 ** 18;
        uint256 pricePerToken = 2 * 10 ** 18;
        uint256 minOrderSize = 100 * 10 ** 18;

        tokenA.approve(address(market), amountToSell);
        market.placeOrder(
            address(tokenA),
            address(tokenB),
            amountToSell,
            pricePerToken,
            minOrderSize
        );
        vm.stopPrank();

        // Update order
        vm.startPrank(seller);
        uint256 newPrice = 3 * 10 ** 18;
        uint256 newMinOrderSize = 200 * 10 ** 18;
        market.updateOrder(1, newPrice, newMinOrderSize);
        vm.stopPrank();

        // Verify order was updated
        P2PMarket.Order memory order = market.getOrder(1);
        assertEq(order.pricePerToken, newPrice);
        assertEq(order.minOrderSize, newMinOrderSize);
    }

    function test_RevertWhen_FillOrderBelowMinSize() public {
        // Setup: Place an order with minimum size
        vm.startPrank(seller);
        uint256 amountToSell = 1000 * 10 ** 18;
        uint256 pricePerToken = 2 * 10 ** 18;
        uint256 minOrderSize = 100 * 10 ** 18;

        tokenA.approve(address(market), amountToSell);
        market.placeOrder(
            address(tokenA),
            address(tokenB),
            amountToSell,
            pricePerToken,
            minOrderSize
        );
        vm.stopPrank();

        // Try to fill below minimum size (should fail)
        vm.startPrank(buyer);
        uint256 amountToBuy = 50 * 10 ** 18; // Below minOrderSize
        uint256 expectedPayment = (amountToBuy * pricePerToken) / 1e18;

        tokenB.approve(address(market), expectedPayment);
        vm.expectRevert("Amount below minimum order size");
        market.fillOrder(1, amountToBuy); // This should revert
        vm.stopPrank();
    }

    function test_PauseMarket() public {
        vm.startPrank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                seller
            )
        );
        market.pause();
        vm.stopPrank();

        market.pause();

        vm.startPrank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(Pausable.EnforcedPause.selector)
        );
        market.placeOrder(
            address(tokenA),
            address(tokenB),
            1000 * 10 ** 18,
            2 * 10 ** 18,
            100 * 10 ** 18
        );
        vm.stopPrank();
    }
}

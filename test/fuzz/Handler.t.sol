// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {P2PMarket} from "../../src/Market.sol";
import {MyERC20} from "../../src/MyERC20.sol";

contract Handler is Test {
    P2PMarket public market;
    address public alice;
    address public bob;
    address public clara;
    address public owner;
    uint public totalTokenToSell1;
    uint public totalTokenToSell2;
    address public tokenToSell1;
    address public tokenToSell2;
    address[] users;
    address[] tokens;

    constructor(
        P2PMarket _market,
        address _owner,
        address _tokenToSell1,
        address _tokenToSell2
    ) {
        market = _market;
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        clara = makeAddr("clara");
        owner = _owner;
        tokenToSell1 = _tokenToSell1;
        tokenToSell2 = _tokenToSell2;
        users = [alice, bob, clara];
        tokens = [tokenToSell1, tokenToSell2];
    }

    function createSellOrderTest(
        uint _amount,
        uint _valueInUSDC,
        uint _uIndex
    ) public returns (uint) {
        uint amount = bound(_amount, 1 * 1e9, 1_000_000_000 * 1e18);
        uint minOrderSize = bound(amount / 2, amount / 10, amount);
        uint valueInUSDC = bound(_valueInUSDC, 1 * 1e3, 1_000_000_000 * 1e6);
        uint uIndex = bound(_uIndex, 0, 2);
        address sender = users[uIndex];

        MyERC20(tokenToSell1).mint(sender, amount);
        vm.startPrank(sender);
        MyERC20(tokenToSell1).approve(address(market), amount);
        market.placeOrder(
            tokenToSell1,
            tokenToSell2,
            amount,
            valueInUSDC,
            minOrderSize
        );
        vm.stopPrank();

        return uIndex;
    }

    function updateOrder(uint _amount, uint _valueInUSDC, uint _uIndex) public {
        uint uIndex = createSellOrderTest(_amount, _valueInUSDC, _uIndex);
        uint newAmount = bound(_amount, 1 * 1e9, 1_000_000_000 * 1e18);
        uint newValueInUSDC = bound(_valueInUSDC, 1 * 1e3, 1_000_000_000 * 1e6);
        uint orderId = market.getTotalOrders();
        P2PMarket.Order memory order = market.getOrder(orderId);

        vm.startPrank(users[uIndex]);
        market.updateOrder(
            orderId,
            newAmount,
            newValueInUSDC,
            order.minOrderSize
        );
        vm.stopPrank();
    }

    function cancelSellOrder(
        uint _amount,
        uint _valueInUSDC,
        uint _uIndex
    ) public {
        uint uIndex = createSellOrderTest(_amount, _valueInUSDC, _uIndex);
        uint orderId = market.getTotalOrders();

        vm.startPrank(users[uIndex]);
        market.cancelOrder(orderId);
        vm.stopPrank();
    }

    function buyOrder(uint _amount, uint _valueInUSDC, uint _uIndex) public {
        uint sellerIndex = createSellOrderTest(_amount, _valueInUSDC, _uIndex);
        uint buyerIndex = (sellerIndex + 1) % users.length;
        uint orderId = market.getTotalOrders();
        P2PMarket.Order memory order = market.getOrder(orderId);

        uint256 amountToPay = (order.amountToSell * order.pricePerToken) /
            (10 ** MyERC20(tokenToSell2).decimals());
        if (amountToPay > 0) {
            vm.startPrank(users[buyerIndex]);
            MyERC20(tokenToSell2).mint(users[buyerIndex], amountToPay);
            MyERC20(tokenToSell2).approve(address(market), amountToPay);
            market.fillOrder(orderId, order.amountToSell, order.pricePerToken);
            vm.stopPrank();
        }
    }
}

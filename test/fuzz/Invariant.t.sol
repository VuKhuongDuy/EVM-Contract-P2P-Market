// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Handler} from "./Handler.t.sol";
import {MyERC20} from "../../src/MyERC20.sol";
import {P2PMarket} from "../../src/Market.sol";

contract OrderBookTest is Test {
    P2PMarket public market;
    Handler public handler;

    address public deployer;
    address public player1;
    address public player2;
    address public player3;
    address public maliciousActor;

    address public weth;
    address public wbtc;
    address public wsol;
    address public usdc;
    address public mono;

    // Initial game parameters for testing
    uint256 public constant INITIAL_CLAIM_FEE = 0.1 ether; // 0.1 ETH
    uint256 public constant GRACE_PERIOD = 1 days; // 1 day in seconds
    uint256 public constant FEE_INCREASE_PERCENTAGE = 10; // 10%
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 5; // 5%

    function setUp() public {
        deployer = makeAddr("deployer");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        maliciousActor = makeAddr("maliciousActor");
        weth = address(new MyERC20("WETH", "WETH", 1000000000000000000, 0));
        wbtc = address(new MyERC20("WBTC", "WBTC", 1000000000000000000, 0));
        wsol = address(new MyERC20("WSOL", "WSOL", 1000000000000000000, 0));
        usdc = address(new MyERC20("USDC", "USDC", 1000000000000000000, 0));
        mono = address(new MyERC20("MONO", "MONO", 1000000000000000000, 0));

        vm.deal(deployer, 10 ether);
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(player3, 10 ether);
        vm.deal(maliciousActor, 10 ether);

        vm.startPrank(deployer);
        market = new P2PMarket();
        market.initialize();
        vm.stopPrank();

        handler = new Handler(market, deployer, weth, mono);

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.createSellOrderTest.selector;
        selectors[1] = handler.updateOrder.selector;
        selectors[2] = handler.cancelSellOrder.selector;
        selectors[3] = handler.buyOrder.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }

    function statefulFuzz_contractBalance() public {
        uint256 totalToken1 = 0;
        uint256 totalToken2 = 0;

        for (uint256 id = 1; id <= market.getTotalOrders(); id++) {
            P2PMarket.Order memory o = market.getOrder(id);
            if (o.tokenToSell == handler.tokenToSell1()) {
                totalToken1 += o.amountToSell;
            } else if (o.tokenToSell == handler.tokenToSell2()) {
                totalToken2 += o.amountToSell;
            }
        }

        uint256 contractBalanceToken1 = MyERC20(handler.tokenToSell1())
            .balanceOf(address(market));
        uint256 contractBalanceToken2 = MyERC20(handler.tokenToSell2())
            .balanceOf(address(market));

        console2.log("Total Token 1:", totalToken1);
        console2.log("Contract Balance Token 1:", contractBalanceToken1);
        console2.log("Total Token 2:", totalToken2);
        console2.log("Contract Balance Token 2:", contractBalanceToken2);

        assert(totalToken1 == contractBalanceToken1);
        assert(totalToken2 == contractBalanceToken2);
    }
}

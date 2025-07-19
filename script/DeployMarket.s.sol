// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Market.sol";

contract DeployMarket is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the P2P Market contract
        P2PMarket market = new P2PMarket();
        
        console.log("P2P Market contract deployed at:", address(market));
        vm.stopBroadcast();
    }
} 
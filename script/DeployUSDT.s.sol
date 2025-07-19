// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/USDT.sol";

contract DeployERC20 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Token configuration
        string memory tokenName = vm.envString("TOKEN_NAME");
        string memory tokenSymbol = vm.envString("TOKEN_SYMBOL");
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");
        uint256 maxSupply = vm.envUint("MAX_SUPPLY");

        // Deploy the ERC20 token
        USDT token = new USDT(6);

        console.log("ERC20 token deployed at:", address(token));
        console.log("Token name:", tokenName);
        console.log("Token symbol:", tokenSymbol);
        console.log("Initial supply:", initialSupply);
        console.log("Max supply:", maxSupply);
        console.log("Owner:", vm.addr(deployerPrivateKey));

        // Optional: Mint additional tokens to specific addresses
        // Uncomment and modify the following lines if needed:

        // address recipient1 = vm.envAddress("RECIPIENT_1");
        // uint256 amount1 = vm.envUint("AMOUNT_1");
        // if (recipient1 != address(0) && amount1 > 0) {
        //     token.mint(recipient1, amount1);
        //     console.log("Minted", amount1, "tokens to", recipient1);
        // }

        vm.stopBroadcast();
    }
}

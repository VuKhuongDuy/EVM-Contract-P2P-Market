// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    uint8 private _decimals;

    constructor(uint8 decimals_) ERC20("USDT test", "tUSDT") {
        _decimals = decimals_;
        _mint(msg.sender, 1_000_000_000 * (10 ** decimals()));
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

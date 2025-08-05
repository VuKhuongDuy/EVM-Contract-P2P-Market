// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title MyERC20
 * @dev A complete ERC20 implementation with minting and burning functionality
 */
contract MyERC20 is ERC20, Ownable {
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event MaxSupplyUpdated(uint256 newMaxSupply);

    // Maximum supply of tokens
    uint256 public maxSupply;

    // Whether minting is enabled
    bool public mintingEnabled = true;

    /**
     * @dev Constructor to initialize the token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param initialSupply_ The initial supply of tokens
     * @param maxSupply_ The maximum supply of tokens (0 for unlimited)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        uint256 maxSupply_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        maxSupply = maxSupply_;

        if (initialSupply_ > 0) {
            _mint(msg.sender, initialSupply_);
        }
    }

    /**
     * @dev Mint new tokens (owner only)
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public {
        require(mintingEnabled, "Minting is disabled");
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");

        if (maxSupply > 0) {
            require(
                totalSupply() + amount <= maxSupply,
                "Would exceed max supply"
            );
        }

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burn tokens from caller
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Burn tokens from a specific address (owner only)
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address from, uint256 amount) public onlyOwner {
        require(from != address(0), "Cannot burn from zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(from) >= amount, "Insufficient balance");

        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    /**
     * @dev Update the maximum supply (owner only)
     * @param newMaxSupply The new maximum supply
     */
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(
            newMaxSupply == 0 || newMaxSupply >= totalSupply(),
            "Max supply cannot be less than current supply"
        );
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @dev Enable or disable minting (owner only)
     * @param enabled Whether minting should be enabled
     */
    function setMintingEnabled(bool enabled) public onlyOwner {
        mintingEnabled = enabled;
    }

    /**
     * @dev Get the remaining tokens that can be minted
     * @return The number of tokens remaining (0 if unlimited)
     */
    function remainingSupply() public view returns (uint256) {
        if (maxSupply == 0) {
            return type(uint256).max;
        }
        return maxSupply - totalSupply();
    }

    /**
     * @dev Check if the maximum supply has been reached
     * @return True if max supply is reached
     */
    function isMaxSupplyReached() public view returns (bool) {
        return maxSupply > 0 && totalSupply() >= maxSupply;
    }
}

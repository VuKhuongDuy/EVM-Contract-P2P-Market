// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyERC20.sol";

contract MyERC20Test is Test {
    MyERC20 public token;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    uint256 public constant INITIAL_SUPPLY = 1000000 * 10 ** 18;
    uint256 public constant MAX_SUPPLY = 2000000 * 10 ** 18;

    function setUp() public {
        vm.startPrank(owner);

        // Deploy token with initial supply and max supply
        token = new MyERC20("Test Token", "TEST", INITIAL_SUPPLY, MAX_SUPPLY);

        vm.stopPrank();

        // Setup user labels
        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(address(token), "Token");
    }

    function test_Constructor() public view {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.maxSupply(), MAX_SUPPLY);
        assertEq(token.owner(), owner);
        assertTrue(token.mintingEnabled());
    }

    function test_Mint() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        vm.startPrank(owner);
        token.mint(user1, mintAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function test_MintByNonOwner() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        vm.expectRevert();
        token.mint(user2, mintAmount);
        vm.stopPrank();
    }

    function test_MintWhenDisabled() public {
        // Disable minting
        vm.prank(owner);
        token.setMintingEnabled(false);

        uint256 mintAmount = 1000 * 10 ** 18;

        vm.startPrank(owner);
        vm.expectRevert("Minting is disabled");
        token.mint(user1, mintAmount);
        vm.stopPrank();
    }

    function test_MintExceedsMaxSupply() public {
        uint256 remainingSupply = token.remainingSupply();
        uint256 exceedAmount = remainingSupply + 1;

        vm.startPrank(owner);
        vm.expectRevert("Would exceed max supply");
        token.mint(user1, exceedAmount);
        vm.stopPrank();
    }

    function test_Burn() public {
        // First mint some tokens to user1
        uint256 mintAmount = 1000 * 10 ** 18;
        vm.prank(owner);
        token.mint(user1, mintAmount);

        uint256 burnAmount = 500 * 10 ** 18;

        vm.startPrank(user1);
        token.burn(burnAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), mintAmount - burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount - burnAmount);
    }

    function test_BurnInsufficientBalance() public {
        uint256 burnAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        vm.expectRevert("Insufficient balance");
        token.burn(burnAmount);
        vm.stopPrank();
    }

    function test_BurnFrom() public {
        // First mint some tokens to user1
        uint256 mintAmount = 1000 * 10 ** 18;
        vm.prank(owner);
        token.mint(user1, mintAmount);

        uint256 burnAmount = 500 * 10 ** 18;

        vm.prank(owner);
        token.burnFrom(user1, burnAmount);

        assertEq(token.balanceOf(user1), mintAmount - burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount - burnAmount);
    }

    function test_BurnFromByNonOwner() public {
        uint256 burnAmount = 500 * 10 ** 18;

        vm.startPrank(user1);
        vm.expectRevert();
        token.burnFrom(user2, burnAmount);
        vm.stopPrank();
    }

    function test_SetMaxSupply() public {
        uint256 newMaxSupply = 3000000 * 10 ** 18;

        vm.prank(owner);
        token.setMaxSupply(newMaxSupply);

        assertEq(token.maxSupply(), newMaxSupply);
    }

    function test_SetMaxSupplyByNonOwner() public {
        uint256 newMaxSupply = 3000000 * 10 ** 18;

        vm.startPrank(user1);
        vm.expectRevert();
        token.setMaxSupply(newMaxSupply);
        vm.stopPrank();
    }

    function test_SetMaxSupplyBelowCurrentSupply() public {
        uint256 newMaxSupply = INITIAL_SUPPLY - 1;

        vm.startPrank(owner);
        vm.expectRevert("Max supply cannot be less than current supply");
        token.setMaxSupply(newMaxSupply);
        vm.stopPrank();
    }

    function test_SetMintingEnabled() public {
        vm.prank(owner);
        token.setMintingEnabled(false);

        assertFalse(token.mintingEnabled());

        vm.prank(owner);
        token.setMintingEnabled(true);

        assertTrue(token.mintingEnabled());
    }

    function test_SetMintingEnabledByNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.setMintingEnabled(false);
        vm.stopPrank();
    }

    function test_RemainingSupply() public {
        uint256 expectedRemaining = MAX_SUPPLY - INITIAL_SUPPLY;
        assertEq(token.remainingSupply(), expectedRemaining);

        // Mint some tokens
        uint256 mintAmount = 1000 * 10 ** 18;
        vm.prank(owner);
        token.mint(user1, mintAmount);

        expectedRemaining = MAX_SUPPLY - INITIAL_SUPPLY - mintAmount;
        assertEq(token.remainingSupply(), expectedRemaining);
    }

    function test_IsMaxSupplyReached() public {
        assertFalse(token.isMaxSupplyReached());

        // Mint up to max supply
        uint256 remainingSupply = token.remainingSupply();
        vm.prank(owner);
        token.mint(user1, remainingSupply);

        assertTrue(token.isMaxSupplyReached());
    }

    function test_Transfer() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        vm.startPrank(owner);
        token.transfer(user1, transferAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
    }

    function test_TransferFrom() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        // Approve user1 to spend owner's tokens
        vm.startPrank(owner);
        token.approve(user1, transferAmount);
        vm.stopPrank();

        // User1 transfers from owner to user2
        vm.startPrank(user1);
        token.transferFrom(owner, user2, transferAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
    }

    function test_UnlimitedSupply() public {
        // Deploy token with unlimited supply (maxSupply = 0)
        vm.startPrank(owner);
        MyERC20 unlimitedToken = new MyERC20(
            "Unlimited Token",
            "UNLIM",
            INITIAL_SUPPLY,
            0 // Unlimited supply
        );
        vm.stopPrank();

        assertEq(unlimitedToken.maxSupply(), 0);
        assertEq(unlimitedToken.remainingSupply(), type(uint256).max);
        assertFalse(unlimitedToken.isMaxSupplyReached());

        // Should be able to mint any amount
        uint256 largeAmount = 1000000 * 10 ** 18;
        vm.prank(owner);
        unlimitedToken.mint(user1, largeAmount);

        assertEq(unlimitedToken.balanceOf(user1), largeAmount);
        assertFalse(unlimitedToken.isMaxSupplyReached());
    }
}

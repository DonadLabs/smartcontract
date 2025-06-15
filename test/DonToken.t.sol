// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DonToken} from "../src/DonToken.sol";

contract DonTokenTest is Test {
    DonToken public donToken;

    address deployer = makeAddr("deployer");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(deployer);
        donToken = new DonToken();
        vm.stopPrank();
    }

    function test_setupAliceHasNoBalance() view public {
        uint256 aliceBalance = donToken.balanceOf(alice);
        assertEq(aliceBalance, 0);
    }

    function test_userCanMintThroughFaucet() public {
        uint256 aliceInitialBalance = donToken.balanceOf(alice);
        bool aliceInitialHasMinted = donToken.userHasMinted(alice);

        vm.prank(alice);
        donToken.faucetMinting();
        vm.stopPrank();

        assertEq(aliceInitialBalance, 0);
        assertEq(aliceInitialHasMinted, false);
        assertEq(donToken.userHasMinted(alice), true);
        assertEq(donToken.balanceOf(alice), donToken.FAUCET_MINTING_AMOUNT());
    }

    function test_userCanTransferToken() public {
        uint256 transferAmount = 1_000_000;

        vm.prank(alice);
        donToken.faucetMinting();
        vm.stopPrank();

        assertEq(donToken.balanceOf(alice), donToken.FAUCET_MINTING_AMOUNT());

        vm.prank(alice);
        donToken.transfer(bob, transferAmount);
        vm.stopPrank();

        assertEq(donToken.balanceOf(alice), donToken.FAUCET_MINTING_AMOUNT() - transferAmount);
        assertEq(donToken.balanceOf(bob), transferAmount);
    }
}
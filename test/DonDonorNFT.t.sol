// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DonDonorNFT} from "../src/DonDonorNFT.sol";

contract DonDonorNFTTest is Test {
    DonDonorNFT public donorNFT;

    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public manager = makeAddr("manager");

    function setUp() public {
        vm.startPrank(deployer);
        donorNFT = new DonDonorNFT();
        vm.stopPrank();
    }

    function test_RegisterNewUser() public {
        uint256 initialAliceBalance = donorNFT.balanceOf(alice);

        vm.startPrank(alice);
        donorNFT.register();
        vm.stopPrank();

        assertEq(initialAliceBalance, 0);
        assertEq(donorNFT.balanceOf(alice), 1);
    }

    function test_ShouldUpdateDonorMilestone() public {
        test_RegisterNewUser();

        uint256 donorMilestone = 50_000_000_000;
        uint256 aliceMilestone = donorNFT.getDonorMilestone(alice);

        vm.prank(deployer);
        donorNFT.updateDonorMilestone(alice, donorMilestone);
        vm.stopPrank();

        assertEq(aliceMilestone, 0);
        assertEq(donorNFT.getDonorMilestone(alice), donorMilestone);
    }

    function test_ShouldTransferOwnershipAndUpdateDonorMilestone() public {
        test_RegisterNewUser();

        uint256 donorMilestone = 50_000_000_000;
        uint256 aliceMilestone = donorNFT.getDonorMilestone(alice);

        vm.prank(deployer);
        donorNFT.transferOwnership(manager);
        vm.stopPrank();

        vm.prank(manager);
        donorNFT.updateDonorMilestone(alice, donorMilestone);
        vm.stopPrank();

        assertEq(aliceMilestone, 0);
        assertEq(donorNFT.getDonorMilestone(alice), donorMilestone);
    }

    function test_Fail_RegisterExistingUser() public {
        test_RegisterNewUser();

        vm.startPrank(alice);
        vm.expectRevert(DonDonorNFT.DonorAlreadyRegistered.selector);
        donorNFT.register();
        vm.stopPrank();
    }

    function test_Fail_ShouldFailOnTransfer() public {
        test_RegisterNewUser();

        vm.startPrank(alice);
        vm.expectRevert(DonDonorNFT.TokenIsNonTransferable.selector);
        donorNFT.transferFrom(alice, bob, 0);
        vm.stopPrank();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DonDonorNFT} from "../src/DonDonorNFT.sol";
import {DonFundraiserNFT} from "../src/DonFundraiserNFT.sol";

contract DonFundraiserNFTTest is Test {
    DonDonorNFT public donorNFT;
    DonFundraiserNFT public fundraiserNFT;

    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public manager = makeAddr("manager");

    function setUp() public {
        vm.startPrank(deployer);
        donorNFT = new DonDonorNFT();
        fundraiserNFT = new DonFundraiserNFT(address(donorNFT));
        vm.stopPrank();

        vm.startPrank(alice);
        donorNFT.register();
        vm.stopPrank();

        uint256 donorMilestone = 100_000_000_000;

        vm.prank(deployer);
        donorNFT.updateDonorMilestone(alice, donorMilestone);
        vm.stopPrank();
    }

    function test_RegisterNewUser() public {
        uint256 initialAliceBalance = fundraiserNFT.balanceOf(alice);

        vm.startPrank(alice);
        fundraiserNFT.register();
        vm.stopPrank();

        assertEq(initialAliceBalance, 0);
        assertEq(fundraiserNFT.balanceOf(alice), 1);
    }

    function test_ShouldUpdateFundraiserMilestone() public {
        test_RegisterNewUser();

        uint256 fundraiserMilestone = 50_000_000_000;
        uint256 aliceMilestone = fundraiserNFT.getFundraiserMilestone(alice);

        vm.prank(deployer);
        fundraiserNFT.updateFundraiserMilestone(alice, fundraiserMilestone);
        vm.stopPrank();

        assertEq(aliceMilestone, 0);
        assertEq(fundraiserNFT.getFundraiserMilestone(alice), fundraiserMilestone);
    }

    function test_ShouldTransferOwnershipAndUpdateFundraiserMilestone() public {
        test_RegisterNewUser();

        uint256 fundraiserMilestone = 50_000_000_000;
        uint256 aliceMilestone = fundraiserNFT.getFundraiserMilestone(alice);

        vm.prank(deployer);
        fundraiserNFT.transferOwnership(manager);
        vm.stopPrank();

        vm.prank(manager);
        fundraiserNFT.updateFundraiserMilestone(alice, fundraiserMilestone);
        vm.stopPrank();

        assertEq(aliceMilestone, 0);
        assertEq(fundraiserNFT.getFundraiserMilestone(alice), fundraiserMilestone);
    }

    function test_RegisterBypassingDonorNFT() public {
        uint256 aliceInitialBalance = fundraiserNFT.balanceOf(alice);

        vm.startPrank(deployer);
        fundraiserNFT.registerBypassingDonorNFTForPrivateAccess(alice);
        vm.stopPrank();

        assertEq(aliceInitialBalance, 0);
        assertEq(fundraiserNFT.balanceOf(alice), 1);
    }

    function test_Fail_RegisterExistingUser() public {
        test_RegisterNewUser();

        vm.startPrank(alice);
        vm.expectRevert(DonFundraiserNFT.FundraiserAlreadyRegistered.selector);
        fundraiserNFT.register();
        vm.stopPrank();
    }

    function test_Fail_ShouldFailOnTransfer() public {
        test_RegisterNewUser();

        vm.startPrank(alice);
        vm.expectRevert(DonDonorNFT.TokenIsNonTransferable.selector);
        fundraiserNFT.transferFrom(alice, bob, 0);
        vm.stopPrank();
    }
}
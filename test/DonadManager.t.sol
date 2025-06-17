// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DonadManager} from "../src/DonadManager.sol";
import {DonToken} from "../src/DonToken.sol";
import {DonFundraiserNFT} from "../src/DonFundraiserNFT.sol";
import {DonDonorNFT} from "../src/DonDonorNFT.sol";

contract DonadManagerTest is Test {
    DonToken public donToken;
    DonDonorNFT public donDonorNFT;
    DonFundraiserNFT public donFundraiserNFT;
    DonadManager public donadManager;

    address public deployer = makeAddr("deployer");
    address public fundraiser = makeAddr("fundraiser");
    address public notFundraiser = makeAddr("notFundraiser");
    address public donor = makeAddr("donor");

    function setUp() public {
        vm.startPrank(deployer);
        donToken = new DonToken();
        donDonorNFT = new DonDonorNFT();
        donFundraiserNFT = new DonFundraiserNFT(address(donDonorNFT));
        donadManager = new DonadManager(
            address(donFundraiserNFT),
            address(donToken)
        );

        // Mint DonFundraiserNFT to Fundraiser (as initial process)
        donFundraiserNFT.registerBypassingDonorNFTForPrivateAccess(fundraiser);
        vm.stopPrank();
    }

    function test_fundraiserCanCreateFundraising() public {
        uint256[] memory initialFundraisesByFundraiser = donadManager.getFundraisesByFundraiser(fundraiser);
        // Arrange
        
        string memory _title = "Fundraiser for Charity";
        string memory _description = "This is a fundraising event to support local charities.";
        uint256 _targetAmount = 50_000 * 10**6; // 50_000 DON tokens
        uint256 _targetDate = block.timestamp + 1 days; // 1 days from now

        vm.startPrank(fundraiser);
        donadManager.createFundraising(_title, _description, _targetAmount, _targetDate);

        // Assert
        assertEq(initialFundraisesByFundraiser.length, 0);
        assertEq(donadManager.getFundraisesByFundraiser(fundraiser).length, 1);
        assertEq(donadManager.getFundraiseDetails(1).fundraiser, fundraiser);
    }

    function test_donateOnExistingFundraising() public {
        // Arrange
        test_fundraiserCanCreateFundraising();
        uint256 fundraisingId = 1; // The ID of the fundraising created in the previous test
        uint256 donationAmount = 10_000 * 10**6; // 10,000 DON tokens

        vm.startPrank(donor);
        // Mint DON tokens to donor
        donToken.faucetMinting();
        uint256 donorBalanceBefore = donToken.balanceOf(donor);

        // Approve DON tokens for donation
        vm.startPrank(donor);
        donToken.approve(address(donadManager), donationAmount);
        
        // Act
        donadManager.donate(fundraisingId, donationAmount);
        vm.stopPrank();

        uint256 donorBalanceAfter = donToken.balanceOf(donor);

        // Assert
        assertEq(donadManager.getFundraiseDetails(fundraisingId).accumulatedAmount, donationAmount);
        assertEq(donorBalanceBefore - donorBalanceAfter, donationAmount);
        assertEq(donToken.balanceOf(address(donadManager)), donationAmount);
        assertEq(donadManager.getFundraiseDetails(fundraisingId).donorsCount, 1);
        uint256 donorsCount = donadManager.getDonationHistories(1).length;
        assertEq(donorsCount, 1);
        assertEq(donadManager.userTotalDonationAmount(donor), donationAmount);
    }

    function test_twoDonorsDonateOnSameFundraising() public {
        // Arrange
        test_fundraiserCanCreateFundraising();
        uint256 fundraisingId = 1; // The ID of the fundraising created in the previous test
        uint256 donationAmount1 = 10_000 * 10**6; // 10,000 DON tokens
        uint256 donationAmount2 = 5_000 * 10**6; // 5,000 DON tokens
        address secondDonor = makeAddr("secondDonor");

        vm.startPrank(donor);
        // Mint DON tokens to donor
        donToken.faucetMinting();
        uint256 donorBalanceBefore1 = donToken.balanceOf(donor);

        // Approve DON tokens for donation
        donToken.approve(address(donadManager), donationAmount1);
        
        // Act
        donadManager.donate(fundraisingId, donationAmount1);
        
        uint256 donorBalanceAfter1 = donToken.balanceOf(donor);
        uint256 fundraiseBalanceAfter1Donation = donToken.balanceOf(address(donadManager));
        
        vm.stopPrank();

        vm.startPrank(secondDonor);
        
        // Mint DON tokens to second donor
        donToken.faucetMinting();
        uint256 secondDonorBalanceBefore = donToken.balanceOf(secondDonor);

        // Approve DON tokens for donation
        donToken.approve(address(donadManager), donationAmount2);
        
        // Act
        donadManager.donate(fundraisingId, donationAmount2);
        
        uint256 secondDonorBalanceAfter = donToken.balanceOf(secondDonor);

        // Assert
        assertEq(fundraiseBalanceAfter1Donation, donationAmount1);
        assertEq(donadManager.getFundraiseDetails(fundraisingId).accumulatedAmount, donationAmount1 + donationAmount2);
        assertEq(secondDonorBalanceBefore - secondDonorBalanceAfter, donationAmount2);
        assertEq(donorBalanceBefore1 - donorBalanceAfter1, donationAmount1);
        assertEq(donadManager.getFundraiseDetails(fundraisingId).donorsCount, 2);
    }

    function test_fundraiserShouldPartiallyWithdraw() public {
        // Arrange
        test_donateOnExistingFundraising();
        uint256 fundraisingId = 1; // The ID of the fundraising created in the previous test
        uint256 donationAmount = 10_000 * 10**6; // 10,000 DON tokens
        uint256 withdrawAmount = 5_000 * 10**6; // 5,000 DON tokens to withdraw
        string memory remarks = "Partial withdrawal for expenses";
        address withdrawTo = makeAddr("withdrawTo");

        assertEq(donadManager.getFundraiseDetails(fundraisingId).accumulatedAmount, donationAmount);

        vm.warp(block.timestamp + 2 days); // Ensure the fundraising is still active

        vm.startPrank(fundraiser);
        
        // Act
        donadManager.withdrawFundraising(
            fundraisingId,
            withdrawAmount,
            remarks,
            withdrawTo
        );
        
        vm.stopPrank();
    
        uint256 fundraiserBalanceAfter = donToken.balanceOf(withdrawTo);
        uint256 withdrawalToBalance = donToken.balanceOf(withdrawTo);
        uint256 totalWithdrawn = donadManager.getFundraiseDetails(fundraisingId).totalWithdrawAmount;
        uint256 accumulatedAmount = donadManager.getFundraiseDetails(fundraisingId).accumulatedAmount;

        // Assert
        assertEq(accumulatedAmount - withdrawAmount, totalWithdrawn);
        assertEq(fundraiserBalanceAfter, donationAmount - withdrawAmount);
        assertEq(withdrawalToBalance, withdrawAmount);
        assertEq(totalWithdrawn, withdrawAmount);
    }

    function test_shouldGetListFundraisings() public {
        // Arrange
        test_fundraiserCanCreateFundraising();
        uint256 fundraisingId = 1; // The ID of the fundraising created in the previous test

        // Act
        DonadManager.Fundraise[] memory fundraisings = donadManager.getFundraisings();

        // Assert
        assertEq(fundraisings.length, 1);
        assertEq(fundraisings[0].id, fundraisingId);
        assertEq(fundraisings[0].fundraiser, fundraiser);
    }

    function test_shouldGetFundraiseDetails() public {
        // Arrange
        test_fundraiserCanCreateFundraising();
        uint256 fundraisingId = 1; // The ID of the fundraising created in the previous test

        // Act
        DonadManager.Fundraise memory fundraiseDetails = donadManager.getFundraiseDetails(fundraisingId);

        // Assert
        assertEq(fundraiseDetails.id, fundraisingId);
        assertEq(fundraiseDetails.fundraiser, fundraiser);
        assertEq(fundraiseDetails.accumulatedAmount, 0); // No donations made yet
    }

    function test_shouldGetDonationHistories() public {
        // Arrange
        test_twoDonorsDonateOnSameFundraising();
        uint256 fundraisingId = 1; // The ID of the fundraising created in the previous test

        // Act
        DonadManager.DonationHistory[] memory donationHistories = donadManager.getDonationHistories(fundraisingId);

        // Assert
        assertEq(donationHistories.length, 2);
        assertEq(donationHistories[0].donor, donor);
        assertEq(donationHistories[0].amount, 10_000 * 10**6); // 10,000 DON tokens
    }

    function test_shouldGetFundraisesByFundraiser() public {
        // Arrange
        test_fundraiserCanCreateFundraising();
        uint256 fundraisingId = 1; // The ID of the fundraising created in the previous test

        // Act
        uint256[] memory fundraises = donadManager.getFundraisesByFundraiser(fundraiser);

        // Assert
        assertEq(fundraises.length, 1);
        assertEq(fundraises[0], fundraisingId);
    }

    function test_shouldFail_nonFundraiserCannotCreateFundraising() public {
        uint256[] memory initialFundraisesByFundraiser = donadManager.getFundraisesByFundraiser(notFundraiser);
        
        string memory _title = "Unauthorized Fundraising";
        string memory _description = "This fundraising should not be allowed.";
        uint256 _targetAmount = 50_000 * 10**6; // 50_000 DON tokens
        uint256 _targetDate = block.timestamp + 1 days; // 1 days from now

        vm.startPrank(notFundraiser);
        vm.expectRevert(DonadManager.UserIsNotFundraiser.selector);
        donadManager.createFundraising(_title, _description, _targetAmount, _targetDate);
        
        // Assert
        assertEq(initialFundraisesByFundraiser.length, 0);
    }
}
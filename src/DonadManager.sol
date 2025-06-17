// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DonFundraiserNFT} from "./DonFundraiserNFT.sol";
import {DonToken} from "./DonToken.sol";

contract DonadManager {

    /**
     * Fundraise metadata
     * targetAmount in 6 decimal format based on the DonToken
     */
    struct Fundraise {
        uint256 id;
        address fundraiser; // address of the fundraiser (should be a DonFundraiserNFT owner)
        string title;
        string description;
        uint256 targetAmount;
        uint256 targetDate;
        uint256 accumulatedAmount;
        uint256 totalWithdrawAmount;
        uint256 donorsCount; // number of unique donors
    }

    struct Withdrawal {
        uint256 fundraiseId;
        uint256 amount;
        string remarks;
        address withdrawalAddress;
        uint256 timestamp;
    }

    struct DonationHistory {
        uint256 fundraiseId;
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    DonFundraiserNFT public fundraiserNFT;
    DonToken public donToken;

    uint256 private _nextFundraiseId;
    mapping(uint256 => Fundraise) public fundraises;
    mapping(address => uint256[]) public fundraisesIdByFundraiser;
    mapping(uint256 => DonationHistory[]) public donationHistories; // fundraiseId => DonationHistory[]
    mapping(uint256 => Withdrawal[]) public withdrawalsByFundraise;
    mapping(address => uint256) public userTotalDonationAmount; // user address => total donation amount

    /*
    mapping(address => uint256) public donationMilestone;
    uint256[] public fundraisings;
    */

    event FundraisingRegistered(
        uint256 indexed fundraiseId,
        string title,
        string description,
        uint256 targetAmount,
        uint256 targetDate
    );
    event Donated(
        uint256 indexed fundraiseId,
        address indexed donor,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawalMade(
        uint256 indexed fundraiseId,
        uint256 amount,
        string remarks,
        address withdrawalAddress,
        uint256 timestamp
    );

    error UserIsNotFundraiser();
    error FundraisingTitleIsEmpty();
    error FundraisingDescriptionIsEmpty();
    error FundraisingTargetAmountIsZero();
    error FundraisingTargetDateIsPast();
    error FundraiseIdNonExistent();
    error FundraiseIsNotClosed();
    error WithdrawalAmountExceedsAccumulated();
    error WtihdrawalRemarkIsEmpty();
    error WithdrawalAddressIsZero();
    error DonationAmountIsZero();
    error UserTokenAllowanceIsLessThanAmountDonated();
    error TokenTransferFailed();

    constructor(
        address _fundraiserNFT,
        address _donToken
    ) {
        fundraiserNFT = DonFundraiserNFT(_fundraiserNFT);
        donToken = DonToken(_donToken);
    }

    modifier onlyFundraiser(address user) {
        // logic to check if user is fundraiser
        if (fundraiserNFT.balanceOf(user) == 0) {
            revert UserIsNotFundraiser();
        }
        _;
    }

    modifier fundraiseExists(uint256 fundraiseId) {
        // logic to check if the fundraiseId exists
        if (fundraiseId > _nextFundraiseId) {
            revert FundraiseIdNonExistent();
        }
        _;
    }

    /**
     * @dev Create fundraising (title, description, amount, date)
     */
    function createFundraising(
        string memory _title,
        string memory _description,
        uint256 _targetAmount,
        uint256 _targetDate
    ) public onlyFundraiser(msg.sender) returns (uint256 fundraiseId) {
        if (bytes(_title).length == 0) {
            revert FundraisingTitleIsEmpty();
        }
        if (bytes(_description).length == 0) {
            revert FundraisingDescriptionIsEmpty();
        }
        if (_targetAmount == 0) {
            revert FundraisingTargetAmountIsZero();
        }
        if (_targetDate <= block.timestamp) {
            revert FundraisingTargetDateIsPast();
        }

        fundraiseId = ++_nextFundraiseId;

        Fundraise memory _fundraise = Fundraise(
            fundraiseId,
            msg.sender,
            _title,
            _description,
            _targetAmount,
            _targetDate,
            0,
            0,
            0
        );

        fundraises[fundraiseId] = _fundraise;
        fundraisesIdByFundraiser[msg.sender].push(fundraiseId);

        emit FundraisingRegistered(
            fundraiseId,
            _title,
            _description,
            _targetAmount,
            _targetDate
        );

        return fundraiseId;
    }

    // donate => (free amount) => update milestone
    /**
     * @dev Donate enable anyone to donate the ERC20 of DON token to any
     * fundraising program that still open
     */
    function donate(uint256 fundraiseId, uint256 amount) public fundraiseExists(fundraiseId) {
        if (fundraises[fundraiseId].targetDate <= block.timestamp) {
            revert FundraisingTargetDateIsPast();
        }

        if (amount == 0) {
            revert DonationAmountIsZero();
        }

        if (donToken.allowance(msg.sender, address(this)) < amount) {
            revert UserTokenAllowanceIsLessThanAmountDonated(); // or a more specific error
        }

        // logic to transfer DON token from msg.sender to the fundraise address
        (bool success) = donToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TokenTransferFailed(); // or a more specific error
        }
        // update accumulatedAmount and milestone for the fundraiser
        fundraises[fundraiseId].accumulatedAmount += amount;
        fundraises[fundraiseId].donorsCount += 1; // increment unique donors count
        donationHistories[fundraiseId].push(
            DonationHistory(fundraiseId, msg.sender, amount, block.timestamp)
        );
        userTotalDonationAmount[msg.sender] += amount;

        // @todo update milestone for the user and for the fundraiser

        // emit event for donation
        emit Donated(
            fundraiseId,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    // withdraw => remarks, address. threshold date should be fulfilled
    /**
     * @dev Withdraw allows the fundraiser to withdraw the accumulated amount
     * from the fundraising program, provided that the target date has been reached   
     */
    function withdrawFundraising(
        uint256 fundraiseId,
        uint256 amount,
        string memory remarks,
        address withdrawalAddress
    ) public onlyFundraiser(msg.sender) fundraiseExists(fundraiseId) {
        if (bytes(remarks).length == 0) {
            revert WtihdrawalRemarkIsEmpty();
        }

        if (fundraises[fundraiseId].targetDate > block.timestamp) {
            revert FundraiseIsNotClosed();
        }

        if (withdrawalAddress == address(0)) {
            revert WithdrawalAddressIsZero();
        }

        uint256 accumulatedAmount = fundraises[fundraiseId].accumulatedAmount;
        uint256 withdrawalAmount = fundraises[fundraiseId].totalWithdrawAmount;
        if (amount + withdrawalAmount > accumulatedAmount) {
            revert WithdrawalAmountExceedsAccumulated();
        }

        Withdrawal memory withdrawal = Withdrawal(
            fundraiseId,
            amount,
            remarks,
            withdrawalAddress,
            block.timestamp
        );

        // logic to transfer DON token from the contract to the fundraiser address
        (bool success) = donToken.transfer(withdrawalAddress, amount);
        if (!success) {
            revert TokenTransferFailed();
        }

        // update totalWithdrawAmount for the fundraiser
        fundraises[fundraiseId].totalWithdrawAmount += amount;
        withdrawalsByFundraise[fundraiseId].push(withdrawal);

        emit WithdrawalMade(
            fundraiseId,
            amount,
            remarks,
            withdrawalAddress,
            withdrawal.timestamp
        );
    }
    
    // get list fundraising (general, filter by all, closed, or open) => title, description, target amount, total accumulated, donor amount, target date, fundraiser address
    /**
     * @dev Get list of fundraisings with their details
     * This function can be extended to filter by status (open, closed, all)
     * This function only returns 20 latest fundraisings
     * @return Fundraise[] - array of Fundraise structs
     */
    function getFundraisings() public view returns (Fundraise[] memory) {
        uint256 fundraiseId = _nextFundraiseId;
        uint256 count = fundraiseId;
        if (count > 20) {
            count = 20; // limit to 20 latest fundraisings
        }

        Fundraise[] memory fundraiseList = new Fundraise[](count);
        for (uint256 i = 0; i < count; i++) {
            fundraiseList[i] = fundraises[fundraiseId - i];
        }
        return fundraiseList;
    }

    // detail fundraising => amount in (donor), amount out (fundraiser)
    /**
     * @dev Get details of a specific fundraising by its ID
     * @param fundraiseId - ID of the fundraising
     * @return Fundraise - the Fundraise struct containing all details
     */
     function getFundraiseDetails(uint256 fundraiseId) public view fundraiseExists(fundraiseId) returns (Fundraise memory) {
        return fundraises[fundraiseId];
     }

     /**
      * @dev Get all withdrawals for a specific fundraising
      * @param fundraiseId - ID of the fundraising
      * @return Withdrawal[] - array of Withdrawal structs
      */
    function getWithdrawals(uint256 fundraiseId) public view fundraiseExists(fundraiseId) returns (Withdrawal[] memory) {
        return withdrawalsByFundraise[fundraiseId];
    }

    /**
     * @dev Get donor histories for a specific fundraising
     * @param fundraiseId - ID of the fundraising
     * @return DonationHistory[] - array of DonationHistory structs
     */
    function getDonationHistories(uint256 fundraiseId) public view fundraiseExists(fundraiseId) returns (DonationHistory[] memory) {
        return donationHistories[fundraiseId];
    }

    /**
     * @dev Get fundraises by a specific fundraiser
     * @param fundraiser - address of the fundraiser
     * @return uint256[] - array of fundraise IDs created by the fundraiser 
     */
    function getFundraisesByFundraiser(address fundraiser) public view returns (uint256[] memory) {
        return fundraisesIdByFundraiser[fundraiser];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {DonDonorNFT} from "./DonDonorNFT.sol";

/**
 * @dev Implementation of ERC-721. This token is Soulbound Token (SBT)
 * which is non-transferrable. It also stores metadata of fundraiser milestone.
 */
contract DonFundraiserNFT is ERC721, Ownable {

    DonDonorNFT public donorNFT;
    uint256 constant public MINIMUM_DONATION_AMOUNT_BEFORE_REGISTRATION = 100_000_000_000;
    uint256 private _nextTokenId;
    mapping(address => uint256) private fundraiserMilestone;

    event MilestoneUpdated(address indexed user, uint256 amount);

    error FundraiserAlreadyRegistered();
    error TokenIsNonTransferable();
    error AddressIsNotFundraiser();
    error AddressIsNotEliglibleToBeFundraiser();
    error NewMilestoneLessThanExistingMilestone();

    constructor(address _donDonorNFTAddress) ERC721("Donat Fundraiser NFT", "DONFUNDRAISER") Ownable(msg.sender) {
        donorNFT = DonDonorNFT(_donDonorNFTAddress);
    }

    /**
     * @dev Only Account with DonFundraiserNFT and fundraiserMilestone > 
     */
    function register() public {
        if (balanceOf(msg.sender) > 0) {
            revert FundraiserAlreadyRegistered();
        }

        if (donorNFT.getDonorMilestone(msg.sender) < MINIMUM_DONATION_AMOUNT_BEFORE_REGISTRATION) {
            revert AddressIsNotEliglibleToBeFundraiser();
        }

        uint256 tokenId = ++_nextTokenId;

        _safeMint(msg.sender, tokenId);
    }

    function registerBypassingDonorNFTForPrivateAccess(address fundraiser) public onlyOwner {
        if (balanceOf(fundraiser) > 0) {
            revert FundraiserAlreadyRegistered();
        }

        uint256 tokenId = ++_nextTokenId;

        _safeMint(fundraiser, tokenId);
    }

    /**
     * @dev Override non-transferable
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert TokenIsNonTransferable();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        revert TokenIsNonTransferable();
    }

    /**
     * @dev Only deployer can set whitelist to Milestone Manager
     */
    function updateFundraiserMilestone(address fundraiser, uint256 milestoneAmount) public onlyOwner {
        // donor non existent
        if (balanceOf(fundraiser) == 0) {
            revert AddressIsNotFundraiser();
        }

        if (milestoneAmount <= fundraiserMilestone[fundraiser]) {
            revert NewMilestoneLessThanExistingMilestone();
        }

        fundraiserMilestone[fundraiser] = milestoneAmount;
        emit MilestoneUpdated(fundraiser, milestoneAmount);
    }

    function getFundraiserMilestone(address fundraiser) public view returns (uint256) {
        return fundraiserMilestone[fundraiser];
    }
}
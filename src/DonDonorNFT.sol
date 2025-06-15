// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of ERC-721. This token is Soulbound Token (SBT)
 * which is non-transferrable. It also stores metadata of donation milestone.
 */
contract DonDonorNFT is ERC721, Ownable {

    uint256 private _nextTokenId;
    mapping(address => uint256) private donorMilestone;

    event MilestoneUpdated(address indexed user, uint256 amount);

    error DonorAlreadyRegistered();
    error TokenIsNonTransferable();
    error AddressIsNotDonor();
    error NewMilestoneLessThanExistingMilestone();

    constructor() ERC721("Donat Donor NFT", "DONDONOR") Ownable(msg.sender) {}

    /**
     * @dev One address can only regiter or mint this contract once.
     */
    function register() public {
        if (balanceOf(msg.sender) > 0) {
            revert DonorAlreadyRegistered();
        }

        uint256 tokenId = ++_nextTokenId;

        _safeMint(msg.sender, tokenId);
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
    function updateDonorMilestone(address donor, uint256 milestoneAmount) public onlyOwner {
        // donor non existent
        if (balanceOf(donor) == 0) {
            revert AddressIsNotDonor();
        }

        if (milestoneAmount <= donorMilestone[donor]) {
            revert NewMilestoneLessThanExistingMilestone();
        }

        donorMilestone[donor] = milestoneAmount;
        emit MilestoneUpdated(donor, milestoneAmount);
    }

    function getDonorMilestone(address donor) public view returns (uint256) {
        return donorMilestone[donor];
    }
}
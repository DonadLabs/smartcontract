// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {DonDonorNFT} from "../src/DonDonorNFT.sol";
import {DonFundraiserNFT} from "../src/DonFundraiserNFT.sol";

contract DonTokenScript is Script {
    DonDonorNFT public donorNFT;
    DonFundraiserNFT public fundraiserNFT;

    function setUp() public {}

    function run() public {
        vm.createSelectFork("monad-testnet");
        vm.startBroadcast();
        donorNFT = new DonDonorNFT();
        fundraiserNFT = new DonFundraiserNFT(address(donorNFT));
        vm.stopBroadcast();
    }
}
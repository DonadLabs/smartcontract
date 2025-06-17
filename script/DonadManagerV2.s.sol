// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {DonadManager} from "../src/DonadManager.sol";
import {DonToken} from "../src/DonToken.sol";
import {DonFundraiserNFT} from "../src/DonFundraiserNFT.sol";

contract DonadManagerScript is Script {
    DonToken public donToken = DonToken(0xC8897AEb22C494f8Aa427Bf5ba41737Bc29449BC);
    DonFundraiserNFT public donFundraiserNFT = DonFundraiserNFT(0x4398Db210e119C44c4fCE07b6Ba7a0c26414CFc9);
    DonadManager public donadManager;

    function setUp() public {}

    function run() public {
        vm.createSelectFork("monad-testnet");
        vm.startBroadcast();
        // deploy DonadManager
        donadManager = new DonadManager(
            address(donFundraiserNFT),
            address(donToken)
        );

        vm.stopBroadcast();
    }
}
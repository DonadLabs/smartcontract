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

        // mint DonFundraiserNFT to some address (as initial process)
        donFundraiserNFT.registerBypassingDonorNFTForPrivateAccess(0x89eDE53aD580B0386d46dc883F78c88644990ae3); // han
        donFundraiserNFT.registerBypassingDonorNFTForPrivateAccess(0x5D9458fa21D073f147734e42CBA0917BBb420311); // bento
        donFundraiserNFT.registerBypassingDonorNFTForPrivateAccess(0x8879A13078f7E7eAb30742dF819F445F7502fec1); // leo

        // transfer ownership of FundraiserNFT from deployer to DonadManager
        donFundraiserNFT.transferOwnership(address(donadManager));

        vm.stopBroadcast();
    }
}
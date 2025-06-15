// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {DonToken} from "../src/DonToken.sol";

contract DonTokenScript is Script {
    DonToken public donToken;

    function setUp() public {}

    function run() public {
        vm.createSelectFork("monad-testnet");
        vm.startBroadcast();
        donToken = new DonToken();
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {KYCSoulbound} from "../contracts/compliance/KYCSoulbound.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        address admin = msg.sender;
        new KYCSoulbound(admin);
        vm.stopBroadcast();
    }
}

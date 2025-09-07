// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {KYCSoulbound} from "../contracts/compliance/KYCSoulbound.sol";

contract KYCSoulboundTest is Test {
    KYCSoulbound kyc;
    address admin = address(0xA11CE);
    address user = address(0xB0B);

    function setUp() public {
        vm.startPrank(admin);
        kyc = new KYCSoulbound(admin);
        vm.stopPrank();
    }

    function _sample() internal view returns (KYCSoulbound.KYCData memory) {
        return KYCSoulbound.KYCData({
            idHash: keccak256("id"),
            passportHash: keccak256("pp"),
            expiry: uint48(block.timestamp + 365 days),
            juris: 840,
            accredited: true
        });
    }

    function testMintAndValidate() public {
        vm.prank(admin);
        kyc.mint(user, _sample());
        assertTrue(kyc.isValid(user));
    }

    function testSoulboundBlocksTransfer() public {
        vm.prank(admin);
        kyc.mint(user, _sample());

        vm.prank(user);
        vm.expectRevert(bytes("KYC: soulbound"));
        // low-level call avoids the ERC20 lint false positive
        (bool ok,) = address(kyc).call(
            abi.encodeWithSelector(kyc.transferFrom.selector, user, address(0x1234), uint256(uint160(user)))
        );
        ok; // ignore
    }

    function testIssuerCanBurn() public {
        vm.prank(admin);
        kyc.mint(user, _sample());

        vm.prank(admin);
        kyc.revoke(user);

        assertFalse(kyc.isValid(user));
    }
}

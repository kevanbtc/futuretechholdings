// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessRoles} from "../access/AccessRoles.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract KYCSoulbound is ERC721, AccessRoles {
    struct KYCData {
        bytes32 idHash;
        bytes32 passportHash;
        uint48 expiry; // unix seconds
        uint16 juris; // jurisdiction code (e.g., 840 = US)
        bool accredited;
    }

    // tokenId == uint160(holder)
    mapping(address => KYCData) public kycOf;
    mapping(address => bool) public locked; // soulbound flag

    constructor(address admin) ERC721("FTH KYC Pass", "KYC-PASS") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KYC_ISSUER_ROLE, admin);
    }

    function _tokenId(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }

    function mint(address to, KYCData calldata d) external onlyRole(KYC_ISSUER_ROLE) {
        uint256 id = _tokenId(to);
        require(_ownerOf(id) == address(0), "KYC: already minted");
        _safeMint(to, id);
        kycOf[to] = d;
        locked[to] = true;
    }

    // renamed to mixedCase to satisfy linter
    function updateKyc(address user, KYCData calldata d) external onlyRole(KYC_ISSUER_ROLE) {
        require(_ownerOf(_tokenId(user)) == user, "KYC: not holder");
        kycOf[user] = d;
    }

    function revoke(address user) external onlyRole(KYC_ISSUER_ROLE) {
        uint256 id = _tokenId(user);
        _burn(id);
        delete kycOf[user];
        locked[user] = false;
    }

    /// Soulbound logic:
    /// - Allow mint (no previous owner)
    /// - Block transfers
    /// - Allow burn when issuer/admin is either the token owner (auth) OR the caller (_msgSender())
    function _update(address to, uint256 id, address auth) internal override returns (address) {
        address prevOwner = _ownerOf(id);
        if (prevOwner != address(0)) {
            if (to == address(0)) {
                address caller = _msgSender();
                bool canBurn = hasRole(KYC_ISSUER_ROLE, auth) || hasRole(DEFAULT_ADMIN_ROLE, auth)
                    || hasRole(KYC_ISSUER_ROLE, caller) || hasRole(DEFAULT_ADMIN_ROLE, caller);
                require(canBurn, "KYC: only issuer/admin can burn");
            } else {
                revert("KYC: soulbound");
            }
        }
        return super._update(to, id, auth);
    }

    function isValid(address user) external view returns (bool) {
        KYCData memory d = kycOf[user];
        bool exists = _ownerOf(_tokenId(user)) == user && locked[user];
        return exists && d.expiry >= block.timestamp;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

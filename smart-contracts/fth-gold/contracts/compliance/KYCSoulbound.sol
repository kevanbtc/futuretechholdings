// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IKYCSBT} from "../interfaces/IKYCSBT.sol";

contract KYCSoulbound is ERC721, AccessControl, IKYCSBT {
    bytes32 public constant KYC_ISSUER_ROLE = keccak256("KYC_ISSUER_ROLE");

    struct KYCData {
        bytes32 idHash;
        bytes32 passportHash;
        uint48 expiry;       // unix time
        uint16 jurisdiction; // enum-coded
        bool accredited;     // true/false
    }

    mapping(address => KYCData) public kycOf;

    constructor(address admin) ERC721("FTH KYC Pass", "KYC-PASS") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KYC_ISSUER_ROLE, admin);
    }

    function tokenIdOf(address wallet) public pure returns (uint256) {
        return uint256(uint160(wallet));
    }

    function mint(address to, KYCData calldata d) external onlyRole(KYC_ISSUER_ROLE) {
        uint256 id = tokenIdOf(to);
        require(_ownerOf(id) == address(0), "KYC: already minted");
        _safeMint(to, id);
        kycOf[to] = d;
    }

    function updateKyc(address user, KYCData calldata d) external onlyRole(KYC_ISSUER_ROLE) {
        require(_ownerOf(tokenIdOf(user)) == user, "KYC: not holder");
        kycOf[user] = d;
    }

    function revoke(address to) external onlyRole(KYC_ISSUER_ROLE) {
        uint256 id = tokenIdOf(to);
        require(_ownerOf(id) != address(0), "KYC: none");
        _burn(id);
        delete kycOf[to];
    }

    // Soulbound: disallow any transfer post-mint.
    function _update(address to, uint256 id, address auth) internal override returns (address) {
        address from = _ownerOf(id);
        if (from != address(0) && to != address(0)) revert("KYC: soulbound");
        return super._update(to, id, auth);
    }

    // Required due to multiple inheritance (ERC165 in both)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    // Helper for gates
    function isValid(address user) external view returns (bool) {
        KYCData memory d = kycOf[user];
        return _ownerOf(tokenIdOf(user)) == user && d.expiry > block.timestamp;
    }
}

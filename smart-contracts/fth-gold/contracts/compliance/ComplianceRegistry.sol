// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ComplianceRegistry is AccessControl {
    bytes32 public constant COMPLIANCE_ADMIN_ROLE = keccak256("COMPLIANCE_ADMIN_ROLE");

    // Market identifiers for different jurisdictions
    bytes32 public constant MARKET_UAE_DMCC = keccak256("UAE_DMCC");
    bytes32 public constant MARKET_US_REG_D = keccak256("US_REG_D");
    bytes32 public constant MARKET_US_REG_S = keccak256("US_REG_S");
    bytes32 public constant MARKET_EU_PROFESSIONAL = keccak256("EU_PROFESSIONAL");
    bytes32 public constant MARKET_CH_SECURITY_TOKEN = keccak256("CH_SECURITY_TOKEN");
    bytes32 public constant MARKET_SG_DPT = keccak256("SG_DPT");

    struct Eligibility {
        bool kyc;
        bytes2 country;
        bytes1 investorClass; // e.g., 0x01 = Accredited, 0x02 = Professional
        uint64 expiry;
        mapping(bytes32 => bool) marketOK; // marketId -> allowed
    }

    mapping(address => Eligibility) internal _eligibility;
    mapping(bytes32 => bool) public marketEnabled; // Global market toggles

    event EligibilitySet(address indexed user, bool kyc, bytes2 country, bytes1 investorClass, uint64 expiry);
    event MarketAccessSet(address indexed user, bytes32 indexed marketId, bool allowed);
    event MarketToggled(bytes32 indexed marketId, bool enabled);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(COMPLIANCE_ADMIN_ROLE, admin);
        
        // Enable UAE/DMCC by default
        marketEnabled[MARKET_UAE_DMCC] = true;
    }

    function setEligibility(
        address user, 
        bool kyc, 
        bytes2 country, 
        bytes1 investorClass, 
        uint64 expiry
    ) external onlyRole(COMPLIANCE_ADMIN_ROLE) {
        Eligibility storage e = _eligibility[user];
        e.kyc = kyc;
        e.country = country;
        e.investorClass = investorClass;
        e.expiry = expiry;
        
        emit EligibilitySet(user, kyc, country, investorClass, expiry);
    }

    function setMarketAccess(
        address user, 
        bytes32 marketId, 
        bool allowed
    ) external onlyRole(COMPLIANCE_ADMIN_ROLE) {
        _eligibility[user].marketOK[marketId] = allowed;
        emit MarketAccessSet(user, marketId, allowed);
    }

    function toggleMarket(bytes32 marketId, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketEnabled[marketId] = enabled;
        emit MarketToggled(marketId, enabled);
    }

    function isEligible(address user, bytes32 marketId) external view returns (bool) {
        if (!marketEnabled[marketId]) return false;
        
        Eligibility storage e = _eligibility[user];
        if (!e.kyc || e.expiry < block.timestamp) return false;
        
        return e.marketOK[marketId];
    }

    function getEligibility(address user) external view returns (
        bool kyc,
        bytes2 country,
        bytes1 investorClass,
        uint64 expiry
    ) {
        Eligibility storage e = _eligibility[user];
        return (e.kyc, e.country, e.investorClass, e.expiry);
    }

    function hasMarketAccess(address user, bytes32 marketId) external view returns (bool) {
        return _eligibility[user].marketOK[marketId];
    }
}
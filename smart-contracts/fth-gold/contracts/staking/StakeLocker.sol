// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {FTHStakeReceipt} from "../token/FTHStakeReceipt.sol";
import {FTHG} from "../token/FTHG.sol";
import {IOracleManager} from "../interfaces/IOracleManager.sol";
import {IKYCSBT} from "../interfaces/IKYCSBT.sol";
import {ComplianceRegistry} from "../compliance/ComplianceRegistry.sol";
import {Parameters} from "../config/Parameters.sol";
import {Errors} from "../utils/Errors.sol";

contract StakeLocker is AccessControl {
    struct Position { uint128 kg; uint64 start; uint64 unlock; bool converted; }

    IERC20 public immutable USDT;  // 6-dec
    FTHStakeReceipt public immutable SR;
    FTHG   public immutable FTH;
    IOracleManager public immutable oracle;
    IKYCSBT public immutable sbt;
    ComplianceRegistry public immutable compliance;

    mapping(address => Position) public positions;
    uint256 public totalKgStaked;
    bool public paused;

    bytes32 public constant DESK_ROLE = keccak256("DESK");

    event Staked(address indexed user, uint256 kg, uint256 usdtPaid);
    event Converted(address indexed user, uint256 kg);

    constructor(
        IERC20 usdt, 
        FTHStakeReceipt sr, 
        FTHG fth, 
        IOracleManager o, 
        IKYCSBT s,
        ComplianceRegistry comp
    ) {
        USDT = usdt; 
        SR = sr; 
        FTH = fth; 
        oracle = o; 
        sbt = s;
        compliance = comp;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); 
    }

    function pause(bool p) external onlyRole(DEFAULT_ADMIN_ROLE) { 
        paused = p; 
    }

    /// @notice Stake exactly @ $20k/kg fixed price; mints non-transferable SR.
    function stakeKg(uint256 kg) external {
        if (paused) revert Errors.SystemPaused();
        if (!sbt.isValid(msg.sender)) revert Errors.SBTInvalid(msg.sender);
        if (!compliance.isEligible(msg.sender, compliance.MARKET_UAE_DMCC())) {
            revert Errors.NotEligible(msg.sender, compliance.MARKET_UAE_DMCC());
        }
        (uint256 cov, uint256 t) = oracle.coverageRatioBps();
        _fresh(t); 
        _coverage(cov);

        Position storage p = positions[msg.sender];
        require(p.kg == 0, "one position per wallet in MVP");

        uint256 cost = kg * Parameters.FIXED_ISSUE_PRICE_USD_PER_KG; // USDT 6-dec already
        require(USDT.transferFrom(msg.sender, address(this), cost), "USDT xfer fail");

        p.kg = uint128(kg);
        p.start = uint64(block.timestamp);
        p.unlock = uint64(block.timestamp + Parameters.LOCK_SECONDS);

        SR.mint(msg.sender, kg * 1e18);
        totalKgStaked += kg;

        emit Staked(msg.sender, kg, cost);
    }

    /// @notice After 150 days, convert SR -> FTHG 1:1 kg, gated by coverage.
    function convert() external {
        if (paused) revert Errors.SystemPaused();
        Position storage p = positions[msg.sender];
        require(p.kg > 0 && !p.converted, "no pos");
        require(block.timestamp >= p.unlock, "locked");

        (uint256 cov, uint256 t) = oracle.coverageRatioBps();
        _fresh(t); 
        _coverage(cov);

        p.converted = true;
        SR.burn(msg.sender, uint256(p.kg) * 1e18);
        FTH.mint(msg.sender, uint256(p.kg) * 1e18);
        emit Converted(msg.sender, p.kg);
    }

    function _fresh(uint256 updatedAt) internal view {
        if (block.timestamp - updatedAt > Parameters.ORACLE_STALENESS_MAX)
            revert Errors.OracleStale(updatedAt, Parameters.ORACLE_STALENESS_MAX);
    }

    function _coverage(uint256 bps) internal pure {
        if (bps < Parameters.MIN_COVERAGE_BPS) 
            revert Errors.CoverageTooLow(bps, Parameters.MIN_COVERAGE_BPS);
    }
}
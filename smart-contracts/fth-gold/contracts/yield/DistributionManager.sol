// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IOracleManager} from "../interfaces/IOracleManager.sol";
import {Errors} from "../utils/Errors.sol";
import {Parameters} from "../config/Parameters.sol";

import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";

contract DistributionManager is AccessControl {
    struct Stream { uint128 principal; uint64 lastPaid; uint128 deficit; }

    IERC20 public immutable USDT;           // cash out
    IERC20Mintable public immutable FTH;    // for principal view
    IOracleManager public immutable oracle;

    mapping(address => Stream) public streams;
    uint64  public lastEpoch;     // last global tick
    bool    public paused;
    bool    public deficitAccounting = true; // ON by default

    bytes32 public constant FUNDER_ROLE = keccak256("FUNDER"); // ops wallet funds USDT here

    event Paid(address indexed user, uint256 target, uint256 paid, uint256 newDeficit);

    constructor(IERC20 usdt, IERC20Mintable fth, IOracleManager o) {
        USDT = usdt; 
        FTH = fth; 
        oracle = o;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Called after convert: initialize stream principal
    function startStream(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 p = FTH.balanceOf(user);
        Stream storage s = streams[user];
        s.principal = uint128(p);
        if (s.lastPaid == 0) s.lastPaid = uint64(block.timestamp);
    }

    /// @notice Fund the distributor with USDT.
    function fund(uint256 amount) external onlyRole(FUNDER_ROLE) { 
        USDT.transferFrom(msg.sender, address(this), amount); 
    }

    /// @notice Pay out monthly policy (10%/mo). Partial pays become deficits if enabled.
    function tick(address[] calldata users) external {
        if (paused) revert Errors.SystemPaused();

        // oracle freshness + coverage gate
        (uint256 cov, uint256 t1) = oracle.coverageRatioBps();
        if (block.timestamp - t1 > Parameters.ORACLE_STALENESS_MAX) 
            revert Errors.OracleStale(t1, Parameters.ORACLE_STALENESS_MAX);
        if (cov < Parameters.MIN_COVERAGE_BPS) 
            revert Errors.CoverageTooLow(cov, Parameters.MIN_COVERAGE_BPS);

        for (uint256 i = 0; i < users.length; i++) {
            Stream storage s = streams[users[i]];
            if (s.principal == 0) continue;
            if (block.timestamp < s.lastPaid + Parameters.DISTRIBUTION_PERIOD) continue;

            uint256 target = (uint256(s.principal) * Parameters.MONTHLY_PAYOUT_BPS) / 10_000; // 1e18 base
            uint256 wantUSDT = target / 1e12; // convert 18-dec kg token units to 6-dec USDT notionally (policy)

            uint256 can = USDT.balanceOf(address(this));
            uint256 pay = can >= wantUSDT ? wantUSDT : (deficitAccounting ? can : 0);

            if (pay > 0) { 
                USDT.transfer(users[i], pay); 
            }
            if (deficitAccounting && pay < wantUSDT) {
                s.deficit += uint128(wantUSDT - pay);
            }
            s.lastPaid = uint64(block.timestamp);

            emit Paid(users[i], wantUSDT, pay, s.deficit);
        }
        lastEpoch = uint64(block.timestamp);
    }

    function pause(bool p) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = p;
    }

    function setDeficitAccounting(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        deficitAccounting = enabled;
    }
}
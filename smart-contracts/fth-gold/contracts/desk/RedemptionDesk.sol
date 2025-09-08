// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {FTHG} from "../token/FTHG.sol";
import {IOracleManager} from "../interfaces/IOracleManager.sol";
import {Errors} from "../utils/Errors.sol";
import {Parameters} from "../config/Parameters.sol";

contract RedemptionDesk is AccessControl {
    IERC20 public immutable USDT;
    FTHG   public immutable FTH;
    IOracleManager public immutable oracle;
    bool public paused;

    uint256 public dailyBudgetUSDT;     // ops sets per day
    uint256 public spentTodayUSDT;      // resets daily
    uint256 public lastResetDay;

    event Redeemed(address indexed user, uint256 kg, uint256 usdtOut, uint256 fee);
    event BudgetSet(uint256 usdtPerDay);

    constructor(IERC20 usdt, FTHG fth, IOracleManager o) { 
        USDT = usdt; 
        FTH = fth; 
        oracle = o; 
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); 
    }

    function pause(bool p) external onlyRole(DEFAULT_ADMIN_ROLE) { 
        paused = p; 
    }

    function setDailyBudget(uint256 usd) external onlyRole(DEFAULT_ADMIN_ROLE) { 
        dailyBudgetUSDT = usd; 
        emit BudgetSet(usd); 
    }

    function redeemKg(uint256 kg) external {
        if (paused) revert Errors.SystemPaused();
        _resetIfNewDay();

        // oracle checks
        (uint256 cov, uint256 t1) = oracle.coverageRatioBps(); 
        _fresh(t1);
        if (cov < Parameters.MIN_COVERAGE_BPS) 
            revert Errors.CoverageTooLow(cov, Parameters.MIN_COVERAGE_BPS);

        (uint256 px, uint256 t2) = oracle.xauUsdPrice(); 
        _fresh(t2);
        // price normalized to 1e8 (XAU per kg) -> map to 6-dec USDT
        uint256 navPerKg = (px / 1e2); // 1e8 -> 1e6

        uint256 gross = kg * navPerKg;
        uint256 fee   = (gross * Parameters.REDEMPTION_FEE_BPS) / 10_000;
        uint256 net   = gross - fee;

        if (spentTodayUSDT + net > dailyBudgetUSDT) 
            revert Errors.InsufficientBudget(net, dailyBudgetUSDT - spentTodayUSDT);
        if (USDT.balanceOf(address(this)) < net) 
            revert Errors.InsufficientCash(net, USDT.balanceOf(address(this)));

        // throttle vs supply cap (optional): omitted for brevity; add if you want 5%/day cap by supply

        FTH.burn(msg.sender, kg * 1e18);
        USDT.transfer(msg.sender, net);

        spentTodayUSDT += net;
        emit Redeemed(msg.sender, kg, net, fee);
    }

    function _fresh(uint256 t) internal view {
        if (block.timestamp - t > Parameters.ORACLE_STALENESS_MAX) 
            revert Errors.OracleStale(t, Parameters.ORACLE_STALENESS_MAX);
    }

    function _resetIfNewDay() internal {
        uint256 d = block.timestamp / 1 days;
        if (d != lastResetDay) { 
            lastResetDay = d; 
            spentTodayUSDT = 0; 
        }
    }
}
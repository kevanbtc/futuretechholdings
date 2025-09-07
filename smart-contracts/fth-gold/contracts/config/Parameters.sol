// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Canonical parameters for Sravan's FTH-G program.
library Parameters {
    // Economics (10%/mo policy)
    uint256 internal constant LOCK_SECONDS             = 150 days;
    uint256 internal constant MONTHLY_PAYOUT_BPS       = 1_000;     // 10% per month (policy target)
    uint256 internal constant DISTRIBUTION_PERIOD      = 30 days;   // monthly ticks

    // Safety & coverage
    uint256 internal constant MIN_COVERAGE_BPS         = 12_500;    // 125% (pilot floor)
    uint256 internal constant ORACLE_STALENESS_MAX     = 24 hours;  // PoR & XAU
    uint256 internal constant MAX_DAILY_REDEEM_BPS     = 500;       // 5% of supply/day

    // Fees & pricing
    uint256 internal constant REDEMPTION_FEE_BPS       = 100;       // 1%
    uint256 internal constant FIXED_ISSUE_PRICE_USD_PER_KG = 20_000e6; // $20k in 6-dec USDT

    // Governance
    uint256 internal constant TIMELOCK_SECONDS         = 48 hours;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
    // Compliance
    error NotEligible(address user, bytes32 market);
    error SBTInvalid(address user);

    // Oracles & coverage
    error OracleStale(uint256 lastUpdate, uint256 maxAge);
    error CoverageTooLow(uint256 coverageBps, uint256 requiredBps);

    // Redemptions & flows
    error SystemPaused();
    error Throttled(uint256 requestedBps, uint256 capBps);
    error InsufficientBudget(uint256 want, uint256 budget);
    error InsufficientCash(uint256 want, uint256 cash);

    // Admin
    error Unauthorized();
}
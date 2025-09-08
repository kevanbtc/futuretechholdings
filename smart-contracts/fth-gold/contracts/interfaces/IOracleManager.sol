// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOracleManager {
    function xauUsdPrice() external view returns (uint256 price, uint256 updatedAt); // 8 or 18-dec normalized upstream; we return 1e8
    function coverageRatioBps() external view returns (uint256 bps, uint256 updatedAt);
}
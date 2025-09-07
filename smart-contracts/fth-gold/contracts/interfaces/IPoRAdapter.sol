// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPoRAdapter {
    /// Should return (amount, lastUpdate)
    function latestProof() external view returns (uint256, uint48);
}

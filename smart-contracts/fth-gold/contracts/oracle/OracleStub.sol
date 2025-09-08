// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOracleManager} from "../interfaces/IOracleManager.sol";

contract OracleStub is IOracleManager {
    uint256 public price = 65_000e8; // $65k/kg
    uint256 public priceUpdated = block.timestamp;
    uint256 public coverageBps = 13_000;
    uint256 public covUpdated = block.timestamp;

    function setPrice(uint256 p) external { 
        price = p; 
        priceUpdated = block.timestamp; 
    }
    
    function setCoverage(uint256 bps) external { 
        coverageBps = bps; 
        covUpdated = block.timestamp; 
    }

    function xauUsdPrice() external view returns (uint256, uint256) { 
        return (price, priceUpdated); 
    }
    
    function coverageRatioBps() external view returns (uint256, uint256) { 
        return (coverageBps, covUpdated); 
    }
}
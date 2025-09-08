// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StakeLocker} from "../staking/StakeLocker.sol";

/// @title OffchainStakeOrchestrator
/// @notice Handles ETH payments with off-chain conversion to USDT for staking
/// @dev This contract coordinates with off-chain services to enable "Pay with ETH" functionality
contract OffchainStakeOrchestrator is AccessControl {
    bytes32 public constant ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    StakeLocker public immutable stakeLocker;
    IERC20 public immutable USDT;

    struct PendingStake {
        address user;
        uint256 ethAmount;
        uint256 expectedUSDT;
        uint256 kg;
        uint64 deadline;
        bytes32 quoteId;
        bool settled;
    }

    mapping(bytes32 => PendingStake) public pendingStakes;
    mapping(address => bytes32[]) public userStakes;

    event ETHQuoteRequested(
        address indexed user, 
        uint256 ethAmount, 
        uint256 expectedUSDT, 
        uint256 kg,
        bytes32 indexed quoteId,
        uint64 deadline
    );

    event ETHPaymentReceived(
        address indexed user,
        uint256 ethAmount,
        bytes32 indexed quoteId
    );

    event OffchainStakeSettled(
        address indexed user, 
        uint256 ethInWei, 
        uint256 usdtIn, 
        bytes32 indexed quoteId
    );

    event QuoteExpired(bytes32 indexed quoteId);

    constructor(address admin, StakeLocker _stakeLocker, IERC20 _usdt) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORCHESTRATOR_ROLE, admin);
        _grantRole(TREASURER_ROLE, admin);
        
        stakeLocker = _stakeLocker;
        USDT = _usdt;
    }

    /// @notice Request a quote for ETH → USDT → staking
    /// @param kg Amount of gold to stake (in kg)
    /// @param ethAmount ETH amount user wants to pay
    /// @param expectedUSDT Expected USDT after conversion (from RFQ)
    /// @param quoteId Unique quote identifier from off-chain RFQ system
    /// @param validFor Quote validity period in seconds
    function requestETHStake(
        uint256 kg,
        uint256 ethAmount,
        uint256 expectedUSDT,
        bytes32 quoteId,
        uint256 validFor
    ) external {
        require(pendingStakes[quoteId].user == address(0), "Quote already exists");
        require(kg > 0 && ethAmount > 0 && expectedUSDT > 0, "Invalid amounts");
        
        uint64 deadline = uint64(block.timestamp + validFor);
        
        pendingStakes[quoteId] = PendingStake({
            user: msg.sender,
            ethAmount: ethAmount,
            expectedUSDT: expectedUSDT,
            kg: kg,
            deadline: deadline,
            quoteId: quoteId,
            settled: false
        });
        
        userStakes[msg.sender].push(quoteId);
        
        emit ETHQuoteRequested(msg.sender, ethAmount, expectedUSDT, kg, quoteId, deadline);
    }

    /// @notice Pay with ETH for a valid quote
    /// @param quoteId The quote ID to execute
    function payWithETH(bytes32 quoteId) external payable {
        PendingStake storage stake = pendingStakes[quoteId];
        require(stake.user == msg.sender, "Not your quote");
        require(!stake.settled, "Already settled");
        require(block.timestamp <= stake.deadline, "Quote expired");
        require(msg.value == stake.ethAmount, "Incorrect ETH amount");
        
        emit ETHPaymentReceived(msg.sender, msg.value, quoteId);
        
        // ETH is held in contract; off-chain orchestrator will:
        // 1. Detect this event
        // 2. Convert ETH to USDT via DEX/RFQ
        // 3. Call settleStake() with the actual USDT received
    }

    /// @notice Settle a stake after off-chain ETH → USDT conversion
    /// @param quoteId The quote to settle
    /// @param actualUSDT The actual USDT amount received from conversion
    function settleStake(bytes32 quoteId, uint256 actualUSDT) external onlyRole(ORCHESTRATOR_ROLE) {
        PendingStake storage stake = pendingStakes[quoteId];
        require(stake.user != address(0), "Quote not found");
        require(!stake.settled, "Already settled");
        require(address(this).balance >= stake.ethAmount, "Insufficient ETH balance");
        
        // Mark as settled
        stake.settled = true;
        
        // Transfer USDT from orchestrator to this contract, then to StakeLocker
        require(USDT.transferFrom(msg.sender, address(this), actualUSDT), "USDT transfer failed");
        require(USDT.approve(address(stakeLocker), actualUSDT), "USDT approval failed");
        
        // Execute the actual staking on behalf of the user
        // Note: This requires the StakeLocker to accept staking on behalf of others
        // For now, we'll transfer USDT to the user and emit an event
        require(USDT.transfer(stake.user, actualUSDT), "USDT transfer to user failed");
        
        emit OffchainStakeSettled(stake.user, stake.ethAmount, actualUSDT, quoteId);
    }

    /// @notice Expire old quotes and refund ETH
    /// @param quoteId The quote to expire
    function expireQuote(bytes32 quoteId) external {
        PendingStake storage stake = pendingStakes[quoteId];
        require(stake.user != address(0), "Quote not found");
        require(block.timestamp > stake.deadline, "Quote not expired");
        require(!stake.settled, "Already settled");
        
        // Refund ETH if payment was made
        if (address(this).balance >= stake.ethAmount) {
            payable(stake.user).transfer(stake.ethAmount);
        }
        
        stake.settled = true;
        emit QuoteExpired(quoteId);
    }

    /// @notice Withdraw ETH after successful conversions (treasury function)
    /// @param amount Amount to withdraw
    function withdrawETH(uint256 amount) external onlyRole(TREASURER_ROLE) {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    /// @notice Emergency function to withdraw all ETH
    function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Get user's pending stakes
    /// @param user User address
    /// @return Array of quote IDs
    function getUserStakes(address user) external view returns (bytes32[] memory) {
        return userStakes[user];
    }

    /// @notice Check if quote is valid and not expired
    /// @param quoteId Quote to check
    /// @return Valid and not settled and not expired
    function isQuoteValid(bytes32 quoteId) external view returns (bool) {
        PendingStake memory stake = pendingStakes[quoteId];
        return stake.user != address(0) && 
               !stake.settled && 
               block.timestamp <= stake.deadline;
    }

    receive() external payable {
        // Accept ETH payments
    }
}
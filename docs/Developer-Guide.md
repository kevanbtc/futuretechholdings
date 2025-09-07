# Developer Guide - FTH Gold Protocol

## Getting Started

### Prerequisites

Ensure you have the following tools installed:

- **Foundry**: Smart contract development toolkit
- **Git**: Version control system  
- **Make**: Build automation tool
- **Node.js** (optional): For additional tooling

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/kevanbtc/futuretechholdings.git
cd futuretechholdings

# Setup development environment (installs dependencies, builds, tests)
make setup

# Start local blockchain for testing
make anvil
```

## Development Workflow

### Daily Development

```bash
# Format, build, and test your changes
make dev

# Run comprehensive verification before committing
make verify

# Generate gas snapshots for optimization
make snapshot
```

### Environment Configuration

Create `.env` file in `smart-contracts/fth-gold/`:

```bash
# Development Configuration
RPC_URL=http://localhost:8545
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Testnet Configuration (for actual deployment)
# RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
# PRIVATE_KEY=0x... # Never commit real private keys!

# Contract Addresses (updated after deployment)
ADMIN_ADDRESS=0x...
USDT_ADDRESS=0x...
```

## Architecture Deep Dive

### Contract Hierarchy

```
AccessRoles (Abstract)
├── FTHGold
├── FTHStakeReceipt  
├── KYCSoulbound
└── StakeLocker

External Dependencies:
├── OpenZeppelin ERC20, ERC721, AccessControl
├── OpenZeppelin Pausable, ReentrancyGuard
└── Foundry Test Framework
```

### Key Design Patterns

#### 1. Role-Based Access Control
```solidity
// Inherited from AccessRoles
bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

// Usage in contracts
modifier onlyRole(bytes32 role) {
    require(hasRole(role, msg.sender), "Unauthorized");
    _;
}
```

#### 2. Soulbound Token Pattern
```solidity
// KYCSoulbound prevents transfers but allows controlled burns
function _update(address to, uint256 id, address auth) internal override {
    if (_ownerOf(id) != address(0) && to != address(0)) {
        revert("KYC: soulbound"); // Block transfers
    }
    return super._update(to, id, auth);
}
```

#### 3. Coverage Ratio Protection
```solidity
// StakeLocker enforces minimum coverage before token issuance
uint256 outstanding = FTHG.totalSupply() / 1e18;
require((por.totalVaultedKg() * 1e4) / (outstanding + 1) >= coverageBps, "coverage");
```

## Testing Guide

### Test Structure

```
test/
├── unit/
│   ├── FTHGold.t.sol       # Token functionality
│   ├── StakeLocker.t.sol   # Staking mechanics
│   └── KYCSoulbound.t.sol  # Compliance features
├── integration/
│   ├── Stake.t.sol         # End-to-end workflows
│   └── OracleGuards.t.sol  # Oracle integration
└── helpers/
    └── TestHelpers.sol     # Shared test utilities
```

### Writing Tests

#### Basic Test Template
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {YourContract} from "../contracts/YourContract.sol";

contract YourContractTest is Test {
    YourContract contract;
    address admin = address(0xA11CE);
    address user = address(0xB0B);

    function setUp() public {
        vm.startPrank(admin);
        contract = new YourContract(admin);
        vm.stopPrank();
    }

    function testBasicFunctionality() public {
        // Test implementation
        vm.prank(user);
        // ... test code
        assertEq(actual, expected, "Test description");
    }
}
```

#### Advanced Testing Patterns
```solidity
// Time manipulation for lock period testing
vm.warp(block.timestamp + 150 days + 1);

// Multi-user testing
address[] memory users = new address[](3);
for (uint i = 0; i < users.length; i++) {
    users[i] = address(uint160(0x1000 + i));
    vm.deal(users[i], 100 ether);
}

// Oracle state manipulation
MockPoRAdapter(address(por)).setHealthy(true);
MockPoRAdapter(address(por)).setTotalVaultedKg(1000);

// Event testing
vm.expectEmit(true, true, true, true);
emit Staked(user, amount, 1);
locker.stake1Kg(amount);
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test file
cd smart-contracts/fth-gold
forge test --match-path test/Stake.t.sol -vvv

# Run specific test function
forge test --match-test testStakeAndConvertHappy -vvv

# Run with gas reporting
make test-gas

# Generate coverage report
make coverage
```

## Deployment Guide

### Local Deployment

```bash
# Start local blockchain
make anvil

# Deploy to local network (new terminal)
make deploy-local
```

### Testnet Deployment

```bash
# Configure environment
export RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"
export PRIVATE_KEY="0x..." # Use test key only

# Deploy and verify
make deploy-testnet
```

### Production Deployment Checklist

1. **Security Review**
   - [ ] External audit completed
   - [ ] All security checklist items addressed
   - [ ] Multi-signature wallets configured

2. **Environment Setup**
   - [ ] Production RPC endpoints configured
   - [ ] Hardware wallets for signing
   - [ ] Backup and recovery procedures

3. **Contract Verification**
   - [ ] Source code verification on Etherscan
   - [ ] Contract interaction testing
   - [ ] Oracle configuration validation

4. **Governance Setup**
   - [ ] Multi-signature wallet deployment
   - [ ] Role assignments and verification
   - [ ] Emergency procedures testing

## Smart Contract API Reference

### FTHGold Contract

#### Core Functions
```solidity
function mint(address to, uint256 amountKg) external onlyRole(ISSUER_ROLE)
function burn(address from, uint256 amountKg) external onlyRole(ISSUER_ROLE)
function pause() external onlyRole(GUARDIAN_ROLE)
function unpause() external onlyRole(GUARDIAN_ROLE)
```

#### View Functions
```solidity
function balanceOf(address account) external view returns (uint256)
function totalSupply() external view returns (uint256)
```

### StakeLocker Contract

#### Core Functions
```solidity
function stake1Kg(uint256 usdtAmount) external
function convert() external
function setCoverage(uint256 bps) external onlyRole(GUARDIAN_ROLE)
```

#### View Functions
```solidity
function position(address user) external view returns (Pos memory)
function coverageBps() external view returns (uint256)
```

### KYCSoulbound Contract

#### Core Functions
```solidity
function mint(address to, KYCData calldata d) external onlyRole(KYC_ISSUER_ROLE)
function updateKyc(address user, KYCData calldata d) external onlyRole(KYC_ISSUER_ROLE)
function revoke(address user) external onlyRole(KYC_ISSUER_ROLE)
```

#### View Functions
```solidity
function isValid(address user) external view returns (bool)
function kycOf(address user) external view returns (KYCData memory)
```

## Security Best Practices

### Code Review Checklist

- [ ] **Access Control**: All functions have appropriate role restrictions
- [ ] **Input Validation**: Parameters are validated and sanitized
- [ ] **State Changes**: State modifications are atomic and consistent
- [ ] **Event Emission**: Important actions emit appropriate events
- [ ] **Error Handling**: Custom errors provide clear feedback
- [ ] **Gas Optimization**: Functions are optimized for gas efficiency

### Common Pitfalls

1. **Reentrancy**: Use `nonReentrant` for external calls
2. **Integer Overflow**: Rely on Solidity 0.8+ built-in protection
3. **Access Control**: Always verify role requirements
4. **Oracle Dependency**: Handle oracle failures gracefully
5. **State Consistency**: Maintain invariants across function calls

## Debugging Guide

### Common Issues

#### Build Failures
```bash
# Clean and rebuild
make clean
make build

# Check dependencies
forge install --no-commit
```

#### Test Failures
```bash
# Run single test with maximum verbosity
forge test --match-test testName -vvvv

# Debug with console logging
import "forge-std/console.sol";
console.log("Debug value:", value);
```

#### Gas Issues
```bash
# Analyze gas usage
forge test --gas-report

# Generate gas snapshots
make snapshot
```

### Troubleshooting Tools

```bash
# Cast for blockchain interaction
cast call $CONTRACT "balanceOf(address)" $ADDRESS

# Forge for advanced debugging
forge debug test/YourTest.t.sol --match-test testFunction

# Anvil for local blockchain inspection
cast block latest --rpc-url http://localhost:8545
```

## Performance Optimization

### Gas Optimization Techniques

1. **Storage Layout**: Pack structs efficiently
2. **Function Visibility**: Use `external` vs `public` appropriately
3. **Loop Optimization**: Minimize iterations and storage access
4. **Event Usage**: Events are cheaper than storage for logs
5. **Batch Operations**: Combine multiple operations when possible

### Monitoring & Metrics

```bash
# Contract size monitoring
forge build --sizes

# Gas usage analysis
forge test --gas-report

# Performance benchmarking
forge snapshot --diff
```

## Contributing Guidelines

### Development Process

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Write** comprehensive tests for your changes
4. **Run** the verification suite (`make verify`)
5. **Commit** your changes (`git commit -m 'Add amazing feature'`)
6. **Push** to the branch (`git push origin feature/amazing-feature`)
7. **Create** a Pull Request

### Code Standards

- Follow Solidity style guide
- Write comprehensive tests (>95% coverage)
- Document all public functions
- Use meaningful variable names
- Include gas optimization considerations

### Pull Request Checklist

- [ ] All tests pass
- [ ] Code coverage maintained
- [ ] Documentation updated
- [ ] Gas usage optimized
- [ ] Security considerations addressed

---

**Developer Support**: dev@futuretechholdings.com  
**Documentation**: [Technical Documentation Link]  
**Community**: [Discord/Telegram Link]  
**Issues**: [GitHub Issues Link]
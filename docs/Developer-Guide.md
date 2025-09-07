# FTH Gold Developer Guide

Complete development workflows, testing, and API documentation for the FTH Gold protocol.

## Table of Contents

- [Quick Start](#quick-start)
- [Development Environment](#development-environment)
- [Build System](#build-system)
- [Testing Framework](#testing-framework)
- [Smart Contract Architecture](#smart-contract-architecture)
- [API Reference](#api-reference)
- [Development Workflows](#development-workflows)
- [Deployment Guide](#deployment-guide)
- [Troubleshooting](#troubleshooting)

## Quick Start

### One-Command Setup
```bash
# Clone and setup in one command
git clone https://github.com/kevanbtc/futuretechholdings.git
cd futuretechholdings
make setup
```

This will:
- Install Foundry (Forge, Cast, Anvil)
- Install all dependencies (OpenZeppelin, forge-std)
- Build all smart contracts
- Run the complete test suite
- Verify everything is working

### Daily Development Workflow
```bash
make dev    # Format code, build contracts, run tests
make verify # Full verification with coverage and gas analysis
```

## Development Environment

### Prerequisites
- **Git**: Version control
- **Make**: Build automation
- **Foundry**: Ethereum development toolkit (auto-installed)

### Required Tools (Auto-installed)
- **Forge**: Smart contract compilation and testing
- **Cast**: Ethereum RPC client
- **Anvil**: Local Ethereum node
- **Solc**: Solidity compiler (v0.8.24)

### Project Structure
```
futuretechholdings/
├── smart-contracts/fth-gold/     # Main smart contracts
│   ├── contracts/                # Solidity contracts
│   │   ├── tokens/              # FTH-G token and receipts
│   │   ├── staking/             # Staking mechanism
│   │   ├── compliance/          # KYC and regulatory
│   │   ├── oracle/              # Proof-of-reserves
│   │   ├── access/              # Role-based access
│   │   └── mocks/               # Testing mocks
│   ├── test/                    # Test suite
│   ├── script/                  # Deployment scripts
│   └── foundry.toml             # Foundry configuration
├── docs/                        # Documentation
├── Makefile                     # Build system (25+ commands)
└── README.md                    # Project overview
```

## Build System

### Core Commands

#### Setup & Maintenance
```bash
make setup           # Complete development environment setup
make install-foundry # Install/update Foundry toolkit
make install-deps    # Install/update dependencies
make upgrade         # Upgrade Foundry to latest version
make clean          # Clean build artifacts
```

#### Daily Development
```bash
make dev            # Format, build, test (daily workflow)
make build          # Compile smart contracts
make test           # Run all tests
make format         # Format Solidity code
make lint           # Check code formatting
```

#### Quality Assurance
```bash
make verify         # Comprehensive verification pipeline
make coverage       # Generate test coverage report
make gas-report     # Generate gas usage analysis
make size-check     # Check contract sizes
make security       # Run security analysis
make compliance     # Check regulatory compliance
```

#### Advanced Testing
```bash
make test-verbose   # Run tests with maximum verbosity
make test-watch     # Run tests in watch mode
make simulation     # Run economic simulations
make stress-test    # Run performance stress tests
make benchmark      # Performance benchmarks
make snapshot       # Create gas usage snapshot
```

#### Deployment
```bash
make anvil          # Start local Anvil node
make deploy-local   # Deploy to local network
make deploy-testnet # Deploy to testnet
make deploy-mainnet # Deploy to mainnet (CAUTION)
```

#### Documentation & Reports
```bash
make docs           # Generate contract documentation
make status         # Show repository status
make all            # Complete build pipeline
make ci             # Continuous integration pipeline
make release        # Prepare for release
```

### Build System Features

- **Colored Output**: Professional console output with status indicators
- **Error Handling**: Comprehensive error reporting and recovery
- **Parallel Execution**: Optimized build performance
- **Incremental Builds**: Only rebuild changed components
- **Environment Detection**: Automatic environment configuration

## Testing Framework

### Test Architecture

The test suite covers all critical functionality:

```bash
# Test coverage overview (make coverage)
Total Coverage: 46% (187/404 lines)
- FTH Gold Token: 57% coverage
- Staking System: 90% coverage  
- KYC Compliance: 85% coverage
- Proof-of-Reserves: Covered in integration tests
```

### Test Categories

#### Unit Tests
- **Token Tests**: ERC20 functionality, minting, burning
- **Staking Tests**: USDT locking, conversion mechanics
- **KYC Tests**: Soulbound NFT issuance and validation
- **Oracle Tests**: Proof-of-reserves and staleness protection

#### Integration Tests
- **System Workflow**: Complete user journey testing
- **Cross-contract**: Inter-contract communication testing
- **Economic Scenarios**: Edge cases and economic attacks

#### Security Tests
- **Access Control**: Role-based permission testing
- **Reentrancy**: Attack vector protection
- **Overflow/Underflow**: Mathematical safety
- **Oracle Manipulation**: Price feed protection

### Running Tests

```bash
# Basic testing
make test           # Run all tests (5 test suites)
make test-verbose   # Maximum verbosity output
make test-watch     # Continuous testing during development

# Coverage analysis
make coverage       # Generate coverage report with LCOV
make gas-report     # Detailed gas usage analysis

# Advanced testing
make security       # Security-focused test suite
make compliance     # Regulatory compliance tests
make stress-test    # Performance and limit testing
```

### Writing Tests

Tests use Foundry's testing framework with standard patterns:

```solidity
// test/ExampleTest.t.sol
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {FTHGold} from "../contracts/tokens/FTHGold.sol";

contract ExampleTest is Test {
    FTHGold token;
    address admin = address(0x1);
    
    function setUp() public {
        token = new FTHGold(admin);
    }
    
    function testMinting() public {
        // Test implementation
    }
}
```

## Smart Contract Architecture

### Core Contracts

#### FTH Gold Token (`contracts/tokens/FTHGold.sol`)
```solidity
// 1 token = 1 kg physical gold
contract FTHGold is ERC20, ERC20Permit, Pausable, AccessRoles {
    function mint(address to, uint256 amountKg) external onlyRole(ISSUER_ROLE);
    function burn(address from, uint256 amountKg) external onlyRole(ISSUER_ROLE);
    function pause() external onlyRole(GUARDIAN_ROLE);
}
```

**Key Features:**
- ERC20 with permit (gasless approvals)
- 1:1 backing with physical gold (1 token = 1 kg)
- Pausable for emergency situations
- Role-based access control

#### Stake Locker (`contracts/staking/StakeLocker.sol`)
```solidity
contract StakeLocker {
    function stake1Kg(address user) external returns (uint256 receiptId);
    function convert(uint256 receiptId) external;
    // 150-day lock period with coverage ratio protection
}
```

**Key Features:**
- USDT staking mechanism
- 150-day lock period
- Coverage ratio enforcement (125% minimum)
- Receipt-based system

#### KYC Soulbound (`contracts/compliance/KYCSoulbound.sol`)
```solidity
contract KYCSoulbound is ERC721 {
    function mint(address to, KYCData memory data) external onlyRole(ISSUER_ROLE);
    function isValid(address user) external view returns (bool);
    // Non-transferable compliance tokens
}
```

**Key Features:**
- Soulbound NFTs (non-transferable)
- KYC data storage
- Regulatory compliance validation

### Access Control System

Role-based permissions implemented via OpenZeppelin AccessControl:

```solidity
contract AccessRoles is AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
}
```

**Roles:**
- **ADMIN**: Full system control
- **ISSUER**: Token minting/burning rights  
- **GUARDIAN**: Emergency controls (pause/unpause)
- **ORACLE**: Proof-of-reserves updates

## API Reference

### FTH Gold Token API

#### Minting
```solidity
function mint(address to, uint256 amountKg) external onlyRole(ISSUER_ROLE)
```
Mints FTH-G tokens representing physical gold. Amount is in kilograms.

#### Burning  
```solidity
function burn(address from, uint256 amountKg) external onlyRole(ISSUER_ROLE)
```
Burns FTH-G tokens when gold is redeemed.

#### Emergency Controls
```solidity
function pause() external onlyRole(GUARDIAN_ROLE)
function unpause() external onlyRole(GUARDIAN_ROLE)
```

### Staking System API

#### Stake USDT
```solidity
function stake1Kg(address user) external returns (uint256 receiptId)
```
Stakes USDT for 150 days, returns receipt NFT ID.

#### Convert to FTH-G
```solidity
function convert(uint256 receiptId) external
```
Converts staking receipt to FTH-G tokens after lock period.

#### Position Query
```solidity
function position(uint256 receiptId) external view returns (StakePosition memory)
```
Returns stake position details.

### KYC System API

#### Issue KYC
```solidity
function mint(address to, KYCData memory data) external onlyRole(ISSUER_ROLE)
```

#### Validate KYC
```solidity
function isValid(address user) external view returns (bool)
```

#### Revoke KYC
```solidity
function revoke(uint256 tokenId) external onlyRole(ISSUER_ROLE)
```

## Development Workflows

### Feature Development

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Development Cycle**
   ```bash
   # Make changes to contracts
   make dev          # Test changes
   make verify       # Full verification
   ```

3. **Pre-merge Checklist**
   ```bash
   make all          # Complete build pipeline
   make security     # Security analysis
   make compliance   # Regulatory checks
   ```

### Testing Workflow

1. **Write Tests First** (TDD approach)
   ```bash
   # Create test file
   touch test/NewFeature.t.sol
   make test-watch   # Continuous testing
   ```

2. **Implement Feature**
   ```bash
   make dev          # Regular development cycle
   ```

3. **Validate Implementation**
   ```bash
   make coverage     # Check test coverage
   make gas-report   # Analyze gas usage
   ```

### Release Workflow

1. **Pre-release Validation**
   ```bash
   make release      # Comprehensive validation
   make audit        # Audit preparation
   ```

2. **Documentation**
   ```bash
   make docs         # Generate documentation
   ```

3. **Deployment Preparation**
   ```bash
   make deploy-local # Test local deployment
   # Prepare for testnet/mainnet deployment
   ```

## Deployment Guide

### Local Development

1. **Start Local Node**
   ```bash
   make anvil        # Terminal 1 - Keep running
   ```

2. **Deploy Contracts**
   ```bash
   make deploy-local # Terminal 2
   ```

3. **Interact with Contracts**
   ```bash
   # Use cast for contract interaction
   cast call CONTRACT_ADDRESS "balanceOf(address)" YOUR_ADDRESS
   ```

### Testnet Deployment

1. **Environment Setup**
   ```bash
   export TESTNET_RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"
   export TESTNET_PRIVATE_KEY="0x..."
   ```

2. **Deploy**
   ```bash
   make deploy-testnet
   ```

### Mainnet Deployment

⚠️ **EXTREME CAUTION REQUIRED**

1. **Final Validation**
   ```bash
   make audit        # Complete audit preparation
   make release      # Final validation
   ```

2. **Environment Setup**
   ```bash
   export MAINNET_RPC_URL="https://mainnet.infura.io/v3/YOUR_KEY"  
   export MAINNET_PRIVATE_KEY="0x..."  # Use hardware wallet
   ```

3. **Deploy**
   ```bash
   make deploy-mainnet  # IRREVERSIBLE
   ```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean and rebuild
make clean
make build

# Check foundry installation
make install-foundry
forge --version
```

#### Test Failures
```bash
# Verbose output for debugging
make test-verbose

# Run specific test
cd smart-contracts/fth-gold
forge test --match-test testSpecificFunction -vvv
```

#### Network Issues
```bash
# Check Anvil is running
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://127.0.0.1:8545
```

### Performance Optimization

#### Gas Optimization
```bash
make gas-report     # Identify expensive operations
make snapshot       # Track gas changes over time
```

#### Build Performance
```bash
make clean          # Clear cache
make build          # Fresh build with timing
```

### Debug Commands

```bash
make status         # Overall system status
make help           # All available commands
forge --version     # Tool versions
```

## Best Practices

### Code Quality
- Always run `make dev` before committing
- Maintain test coverage above 80%
- Use descriptive commit messages
- Follow Solidity style guide

### Security
- Run `make security` before releases
- Use multi-signature for admin roles
- Test all edge cases
- Regular security audits

### Performance
- Monitor gas usage with `make gas-report`
- Optimize for common use cases
- Use efficient data structures
- Profile with `make benchmark`

## Support

For questions and issues:
- Review this developer guide
- Check existing tests for examples
- Run `make help` for command reference
- Use `make status` for system diagnostics

---

**Ready for professional DeFi development with institutional-grade tooling.**
# FTH Gold (FTH-G) - Asset-Backed Gold Token System

[![CI/CD](https://github.com/kevanbtc/futuretechholdings/actions/workflows/ci.yml/badge.svg)](https://github.com/kevanbtc/futuretechholdings/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)

## 🏅 Overview

FTH Gold (FTH-G) is a sophisticated DeFi protocol that provides private, asset-backed gold tokens where **1 token equals 1 kilogram of vaulted physical gold**. The system is designed for high-net-worth individuals and institutional investors, featuring comprehensive compliance, security, and governance mechanisms.

### Key Features

- **🥇 Asset-Backed**: Each FTH-G token is backed by 1kg of physical gold held in secure vaults
- **🔒 Private & Compliant**: Invite-only system with KYC/AML through soulbound tokens
- **⏰ Staking Mechanism**: 150-day lock period with USDT staking to earn FTH-G tokens
- **📊 Proof-of-Reserves**: On-chain verification of gold backing through oracle feeds
- **🛡️ Security-First**: Multi-signature governance, pause mechanisms, and comprehensive access controls
- **🏛️ Regulatory Ready**: Built for DMCC/VARA compliance with jurisdiction-aware features

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User (USDT)   │───▶│  StakeLocker    │───▶│  FTH-G Token    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  KYC Soulbound  │    │ Stake Receipt   │    │ Proof-of-Reserves│
│     Token       │    │  (150 days)     │    │    Oracle       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Core Components

#### 1. **FTH Gold Token (`FTHGold.sol`)**
- ERC20 token representing physical gold (1 token = 1kg)
- ERC20Permit support for gasless transactions
- Pausable for emergency situations
- Role-based minting and burning

#### 2. **Staking System (`StakeLocker.sol`)**
- Users stake USDT for 150 days to earn FTH-G tokens
- Coverage ratio protection (minimum 125% initially)
- Proof-of-reserves validation before conversion
- Position tracking and conversion management

#### 3. **KYC Compliance (`KYCSoulbound.sol`)**
- Soulbound NFTs for KYC verification
- Jurisdiction and accreditation tracking
- Expiry-based validation
- Revocation capabilities for compliance

#### 4. **Proof-of-Reserves (`ChainlinkPoRAdapter.sol`)**
- Oracle integration for gold vault verification
- Staleness checks and health monitoring
- Coverage ratio enforcement

#### 5. **Access Control (`AccessRoles.sol`)**
- **GUARDIAN_ROLE**: Emergency controls and parameters
- **KYC_ISSUER_ROLE**: KYC token management
- **ISSUER_ROLE**: FTH-G token minting/burning
- **TREASURER_ROLE**: Treasury operations
- **ORACLE_ROLE**: Price and PoR data
- **UPGRADER_ROLE**: Contract upgrades

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Smart contract development toolkit
- [Git](https://git-scm.com/) - Version control
- [Make](https://www.gnu.org/software/make/) - Build automation

### Installation

```bash
# Clone the repository
git clone https://github.com/kevanbtc/futuretechholdings.git
cd futuretechholdings

# Setup development environment
make setup
```

### Building

```bash
# Build all contracts
make build

# Run tests
make test

# Generate coverage report
make coverage

# Format code
make format
```

### Testing

```bash
# Run all tests with verbose output
make test

# Run tests with gas reporting
make test-gas

# Generate gas snapshots
make snapshot
```

## 🔧 Development

### Project Structure

```
futuretechholdings/
├── smart-contracts/fth-gold/          # Core smart contracts
│   ├── contracts/
│   │   ├── access/                    # Access control contracts
│   │   ├── compliance/                # KYC and compliance
│   │   ├── oracle/                    # Price and PoR oracles
│   │   ├── staking/                   # Staking mechanisms
│   │   ├── tokens/                    # Token contracts
│   │   └── mocks/                     # Testing utilities
│   ├── test/                          # Test suite
│   ├── script/                        # Deployment scripts
│   └── foundry.toml                   # Foundry configuration
├── docs/                              # Documentation
├── .github/workflows/                 # CI/CD pipelines
└── Makefile                           # Build automation
```

### Available Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make setup` | Setup development environment |
| `make build` | Build all smart contracts |
| `make test` | Run all tests |
| `make coverage` | Generate test coverage |
| `make deploy-local` | Deploy to local network |
| `make verify` | Run comprehensive verification |

### Environment Variables

Create a `.env` file in `smart-contracts/fth-gold/`:

```bash
# Network Configuration
RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
PRIVATE_KEY=0x... # For development only

# Contract Addresses (after deployment)
USDT_ADDRESS=0x...
ADMIN_ADDRESS=0x...
```

## 🏦 How It Works

### 1. User Onboarding

1. **KYC Process**: Users complete KYC/AML verification
2. **Soulbound Token**: KYC issuer mints non-transferable KYC token
3. **Eligibility**: User becomes eligible to participate in staking

### 2. Staking Process

1. **USDT Deposit**: User stakes USDT (minimum amount TBD)
2. **Lock Period**: 150-day mandatory lock period begins
3. **Receipt Token**: User receives non-transferable stake receipt
4. **Monitoring**: System monitors proof-of-reserves and coverage ratios

### 3. Conversion to FTH-G

1. **Lock Expiry**: User waits for 150-day lock period
2. **PoR Validation**: System validates proof-of-reserves is healthy
3. **Coverage Check**: Ensures minimum coverage ratio (125%)
4. **Token Issuance**: User receives FTH-G tokens (1 token = 1kg gold)

### 4. Gold Redemption (Future)

- Physical gold delivery (1kg bars)
- USDT redemption at market rate
- Institutional settlement options

## 🔐 Security

### Multi-Layered Security

1. **Smart Contract Security**
   - OpenZeppelin battle-tested contracts
   - Comprehensive test coverage
   - Role-based access controls
   - Pause mechanisms for emergencies

2. **Oracle Security**
   - Chainlink proof-of-reserves feeds
   - Staleness and deviation checks
   - Multiple oracle redundancy

3. **Governance Security**
   - Multi-signature wallet requirement
   - Timelock for critical operations
   - Guardian role for emergency actions

### Audit Status

- **Internal Review**: ✅ Completed
- **External Audit**: 🔄 Pending
- **Bug Bounty**: 📅 Planned post-audit

## 📋 Compliance

### Regulatory Framework

- **Jurisdiction**: DMCC/VARA compliant
- **Structure**: Private placement for accredited investors
- **KYC/AML**: Soulbound token-based verification
- **Reporting**: On-chain proof-of-reserves attestations

### Compliance Features

- Jurisdiction-based access controls
- Accredited investor verification
- Sanctions list integration (planned)
- Regulatory reporting capabilities

## 📊 Testing & Quality Assurance

### Test Coverage

- **Unit Tests**: All core functions covered
- **Integration Tests**: End-to-end workflows
- **Gas Optimization**: Optimized for efficiency
- **Invariant Testing**: Critical system properties

### Quality Metrics

```bash
# Run comprehensive testing
make verify

# Generate detailed coverage report
make coverage

# Performance analysis
make test-gas
```

## 🚀 Deployment

### Local Development

```bash
# Start local blockchain
make anvil

# Deploy to local network
make deploy-local
```

### Testnet Deployment

```bash
# Set environment variables
export RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"
export PRIVATE_KEY="0x..."

# Deploy to testnet
make deploy-testnet
```

### Production Deployment

1. **Security Review**: Complete external audit
2. **Multi-sig Setup**: Configure governance wallets
3. **Oracle Configuration**: Set up Chainlink feeds
4. **Gradual Rollout**: Phased deployment approach

## 📚 Documentation

Comprehensive documentation is available in the `/docs` directory:

- [CEO Brief](docs/CEO-brief.md) - Executive overview
- [Security Checklist](docs/Security-Checklist.md) - Security requirements
- [Compliance Checklist](docs/Compliance-Checklist.md) - Regulatory requirements
- [QA Test Matrix](docs/QA-Test-Matrix.md) - Testing framework

## 🤝 Contributing

We welcome contributions from the community. Please read our contributing guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes with comprehensive tests
4. Submit a pull request

### Development Workflow

```bash
# Start development
make dev

# Before committing
make verify
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 Team & Contact

**Future Tech Holdings**
- Website: [Coming Soon]
- Email: [Contact Information]
- Documentation: [Technical Docs]

## ⚠️ Disclaimers

- This is experimental technology - use at your own risk
- Past performance does not guarantee future results
- Regulatory landscape is evolving - consult legal counsel
- Smart contracts are immutable once deployed - thorough testing required

---

*Built with ❤️ by Future Tech Holdings using Foundry and OpenZeppelin*

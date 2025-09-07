# FTH Gold Deployment Guide

Step-by-step deployment instructions for all environments (local, testnet, mainnet).

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Local Development Deployment](#local-development-deployment)
- [Testnet Deployment](#testnet-deployment)
- [Mainnet Deployment](#mainnet-deployment)
- [Post-Deployment Verification](#post-deployment-verification)
- [Contract Interaction](#contract-interaction)
- [Emergency Procedures](#emergency-procedures)
- [Monitoring & Maintenance](#monitoring--maintenance)

## Overview

The FTH Gold protocol deployment involves multiple smart contracts that must be deployed in a specific order and properly configured for institutional-grade security and compliance.

### Deployment Architecture
```
1. FTH Gold Token (ERC20)
2. KYC Soulbound (ERC721)  
3. Stake Receipt Token (ERC721)
4. Proof-of-Reserves Oracle
5. Stake Locker (Main Logic)
6. Access Control Configuration
7. Initial Parameter Setup
```

### Security Considerations
- Multi-signature wallet for admin roles
- Role-based access control
- Emergency pause mechanisms
- Oracle staleness protection
- Coverage ratio enforcement (125% minimum)

## Prerequisites

### Required Tools
```bash
# Verify installation
make setup          # Installs all required tools
forge --version     # Should show v1.3.2+
cast --version      # Should show v1.3.2+
anvil --version     # Should show v1.3.2+
```

### Required Accounts
- **Deployer Account**: For contract deployment
- **Admin Account**: Multi-sig for governance  
- **Guardian Account**: Emergency controls
- **Oracle Account**: Proof-of-reserves updates

### Environment Variables
Create `.env` file in `smart-contracts/fth-gold/`:
```bash
# Local Development
ANVIL_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Testnet (Sepolia)
TESTNET_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
TESTNET_PRIVATE_KEY=0x...  # Your testnet private key
TESTNET_ETHERSCAN_API_KEY=your_etherscan_api_key

# Mainnet (PRODUCTION)
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
MAINNET_PRIVATE_KEY=0x...  # HARDWARE WALLET RECOMMENDED
MAINNET_ETHERSCAN_API_KEY=your_etherscan_api_key

# Multi-sig addresses
ADMIN_MULTISIG=0x...      # Admin multi-sig wallet
GUARDIAN_MULTISIG=0x...   # Guardian multi-sig wallet
TREASURY_ADDRESS=0x...    # Treasury for collected fees
```

## Local Development Deployment

### Step 1: Start Local Node
```bash
# Terminal 1 - Keep this running
make anvil

# Verify anvil is running
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://127.0.0.1:8545
```

### Step 2: Deploy Contracts
```bash
# Terminal 2 - Deploy all contracts
make deploy-local

# Expected output:
# ✅ Local deployment complete
# Contract addresses will be displayed
```

### Step 3: Verify Deployment
```bash
# Check deployment status
make status

# Verify specific contracts
cd smart-contracts/fth-gold
cast call CONTRACT_ADDRESS "name()" --rpc-url http://127.0.0.1:8545
```

### Local Testing Workflow
```bash
# Complete local testing cycle
make anvil          # Terminal 1
make deploy-local   # Terminal 2
make test           # Verify deployment works
```

## Testnet Deployment

### Step 1: Environment Setup
```bash
# Set testnet environment variables
export TESTNET_RPC_URL="https://sepolia.infura.io/v3/YOUR_PROJECT_ID"
export TESTNET_PRIVATE_KEY="0x..."  # Your testnet private key

# Verify network connection
cast chain-id --rpc-url $TESTNET_RPC_URL
# Should return 11155111 for Sepolia
```

### Step 2: Pre-deployment Validation
```bash
# Run complete validation pipeline
make verify         # Full testing and verification
make security       # Security analysis
make compliance     # Regulatory compliance checks

# Check gas estimates
make gas-report     # Ensure sufficient funds
```

### Step 3: Deploy to Testnet
```bash
# Deploy with verification
make deploy-testnet

# Expected deployment cost: ~0.01 ETH on testnet
# Contracts will be verified on Etherscan automatically
```

### Step 4: Post-deployment Configuration
```bash
# Configure roles (replace with actual addresses)
cd smart-contracts/fth-gold

# Grant roles to multi-sig
cast send FTH_GOLD_ADDRESS "grantRole(bytes32,address)" \
  GUARDIAN_ROLE GUARDIAN_MULTISIG \
  --rpc-url $TESTNET_RPC_URL \
  --private-key $TESTNET_PRIVATE_KEY

# Revoke deployer roles (security best practice)
cast send FTH_GOLD_ADDRESS "revokeRole(bytes32,address)" \
  DEFAULT_ADMIN_ROLE DEPLOYER_ADDRESS \
  --rpc-url $TESTNET_RPC_URL \
  --private-key $TESTNET_PRIVATE_KEY
```

### Step 5: Testnet Validation
```bash
# Test basic functionality
cast call FTH_GOLD_ADDRESS "name()" --rpc-url $TESTNET_RPC_URL
cast call FTH_GOLD_ADDRESS "symbol()" --rpc-url $TESTNET_RPC_URL
cast call FTH_GOLD_ADDRESS "totalSupply()" --rpc-url $TESTNET_RPC_URL

# Test KYC system
cast call KYC_ADDRESS "isValid(address)" YOUR_ADDRESS --rpc-url $TESTNET_RPC_URL
```

## Mainnet Deployment

⚠️ **CRITICAL: MAINNET DEPLOYMENT IS IRREVERSIBLE**

### Step 1: Final Preparation
```bash
# Complete audit preparation
make audit          # Comprehensive audit checklist
make release        # Final validation pipeline

# Security checklist
make security       # Security analysis
make compliance     # Regulatory compliance

# Documentation check
make docs           # Generate final documentation
```

### Step 2: Hardware Wallet Setup
```bash
# RECOMMENDED: Use hardware wallet
# Configure Ledger/Trezor for deployment
# Never use private keys directly on mainnet

# Alternative: Use secure key management
export MAINNET_PRIVATE_KEY="0x..."  # ONLY if absolutely necessary
```

### Step 3: Mainnet Deployment
```bash
# FINAL WARNING: This cannot be undone
export MAINNET_RPC_URL="https://mainnet.infura.io/v3/YOUR_PROJECT_ID"

# Deploy to mainnet
make deploy-mainnet

# Expected deployment cost: 0.05-0.1 ETH
# Gas price optimization may be needed
```

### Step 4: Post-deployment Security
```bash
# IMMEDIATELY after deployment:

# 1. Transfer admin roles to multi-sig
cast send FTH_GOLD_ADDRESS "grantRole(bytes32,address)" \
  DEFAULT_ADMIN_ROLE ADMIN_MULTISIG \
  --rpc-url $MAINNET_RPC_URL

# 2. Grant guardian role to multi-sig  
cast send FTH_GOLD_ADDRESS "grantRole(bytes32,address)" \
  GUARDIAN_ROLE GUARDIAN_MULTISIG \
  --rpc-url $MAINNET_RPC_URL

# 3. Revoke deployer permissions
cast send FTH_GOLD_ADDRESS "revokeRole(bytes32,address)" \
  DEFAULT_ADMIN_ROLE DEPLOYER_ADDRESS \
  --rpc-url $MAINNET_RPC_URL

# 4. Verify role configuration
cast call FTH_GOLD_ADDRESS "hasRole(bytes32,address)" \
  DEFAULT_ADMIN_ROLE ADMIN_MULTISIG \
  --rpc-url $MAINNET_RPC_URL
```

### Step 5: Initial Parameter Configuration
```bash
# Set coverage ratio (125% minimum)
cast send STAKE_LOCKER_ADDRESS "setCoverageRatio(uint256)" \
  125 \  # 125%
  --rpc-url $MAINNET_RPC_URL

# Configure oracle parameters
cast send ORACLE_ADDRESS "setStalenessThreshold(uint256)" \
  3600 \  # 1 hour staleness limit
  --rpc-url $MAINNET_RPC_URL

# Set minimum stake amount
cast send STAKE_LOCKER_ADDRESS "setMinimumStake(uint256)" \
  1000000000 \  # $1000 USDT minimum
  --rpc-url $MAINNET_RPC_URL
```

## Post-Deployment Verification

### Contract Verification
```bash
# Verify on Etherscan (automatic with make deploy-*)
# Manual verification if needed:
cd smart-contracts/fth-gold
forge verify-contract \
  --chain-id 1 \
  --num-of-optimizations 200 \
  --constructor-args $(cast abi-encode "constructor(address)" ADMIN_ADDRESS) \
  CONTRACT_ADDRESS \
  contracts/tokens/FTHGold.sol:FTHGold \
  --etherscan-api-key $MAINNET_ETHERSCAN_API_KEY
```

### Functional Testing
```bash
# Test all critical functions
cast call FTH_GOLD_ADDRESS "name()" --rpc-url $RPC_URL
cast call FTH_GOLD_ADDRESS "decimals()" --rpc-url $RPC_URL
cast call FTH_GOLD_ADDRESS "totalSupply()" --rpc-url $RPC_URL

# Test access controls
cast call FTH_GOLD_ADDRESS "hasRole(bytes32,address)" \
  GUARDIAN_ROLE GUARDIAN_MULTISIG \
  --rpc-url $RPC_URL

# Test pause mechanism (ONLY ON TESTNET)
cast send FTH_GOLD_ADDRESS "pause()" \
  --rpc-url $TESTNET_RPC_URL \
  --private-key $GUARDIAN_PRIVATE_KEY
```

### Security Verification
```bash
# Verify multi-sig configuration
cast call ADMIN_MULTISIG "getOwners()" --rpc-url $RPC_URL
cast call ADMIN_MULTISIG "getThreshold()" --rpc-url $RPC_URL

# Verify role assignments
cast call FTH_GOLD_ADDRESS "getRoleAdmin(bytes32)" \
  ISSUER_ROLE --rpc-url $RPC_URL

# Verify oracle configuration
cast call ORACLE_ADDRESS "stalenessThreshold()" --rpc-url $RPC_URL
cast call ORACLE_ADDRESS "isHealthy()" --rpc-url $RPC_URL
```

## Contract Interaction

### User Operations

#### KYC Registration
```bash
# Mint KYC token (admin only)
cast send KYC_ADDRESS "mint(address,(string,string,uint256))" \
  USER_ADDRESS \
  "John Doe" "US" 1672531200 \  # Name, jurisdiction, timestamp
  --rpc-url $RPC_URL \
  --private-key $ADMIN_PRIVATE_KEY
```

#### Staking Process
```bash
# 1. User approves USDT
cast send USDT_ADDRESS "approve(address,uint256)" \
  STAKE_LOCKER_ADDRESS \
  1000000000 \  # $1000 USDT
  --rpc-url $RPC_URL \
  --private-key $USER_PRIVATE_KEY

# 2. Stake for 1kg gold
cast send STAKE_LOCKER_ADDRESS "stake1Kg(address)" \
  USER_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $USER_PRIVATE_KEY
```

#### Token Conversion
```bash
# After 150 days, convert receipt to FTH-G
cast send STAKE_LOCKER_ADDRESS "convert(uint256)" \
  RECEIPT_ID \
  --rpc-url $RPC_URL \
  --private-key $USER_PRIVATE_KEY
```

### Admin Operations

#### Mint FTH-G Tokens
```bash
# Mint 1 kg worth of tokens (admin only)
cast send FTH_GOLD_ADDRESS "mint(address,uint256)" \
  RECIPIENT_ADDRESS \
  1 \  # 1 kg of gold
  --rpc-url $RPC_URL \
  --private-key $ADMIN_PRIVATE_KEY
```

#### Oracle Updates
```bash
# Update proof-of-reserves (oracle role)
cast send ORACLE_ADDRESS "updateReserves(uint256)" \
  1000 \  # 1000 kg total vaulted
  --rpc-url $RPC_URL \
  --private-key $ORACLE_PRIVATE_KEY
```

### Guardian Operations

#### Emergency Pause
```bash
# Pause system in emergency
cast send FTH_GOLD_ADDRESS "pause()" \
  --rpc-url $RPC_URL \
  --private-key $GUARDIAN_PRIVATE_KEY

# Unpause when resolved
cast send FTH_GOLD_ADDRESS "unpause()" \
  --rpc-url $RPC_URL \
  --private-key $GUARDIAN_PRIVATE_KEY
```

## Emergency Procedures

### System Pause
```bash
# Emergency pause (guardian role required)
cast send FTH_GOLD_ADDRESS "pause()" \
  --rpc-url $RPC_URL \
  --private-key $GUARDIAN_PRIVATE_KEY

# Verify pause status
cast call FTH_GOLD_ADDRESS "paused()" --rpc-url $RPC_URL
```

### Oracle Emergency
```bash
# Set oracle as unhealthy if compromised
cast send ORACLE_ADDRESS "setHealthy(bool)" \
  false \
  --rpc-url $RPC_URL \
  --private-key $ORACLE_ADMIN_PRIVATE_KEY
```

### Role Revocation
```bash
# Revoke compromised role immediately
cast send FTH_GOLD_ADDRESS "revokeRole(bytes32,address)" \
  ROLE_HASH \
  COMPROMISED_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $ADMIN_PRIVATE_KEY
```

## Monitoring & Maintenance

### Key Metrics to Monitor
```bash
# Total supply
cast call FTH_GOLD_ADDRESS "totalSupply()" --rpc-url $RPC_URL

# Oracle health
cast call ORACLE_ADDRESS "isHealthy()" --rpc-url $RPC_URL
cast call ORACLE_ADDRESS "lastUpdateTime()" --rpc-url $RPC_URL

# Coverage ratio
cast call STAKE_LOCKER_ADDRESS "coverageRatio()" --rpc-url $RPC_URL

# System pause status
cast call FTH_GOLD_ADDRESS "paused()" --rpc-url $RPC_URL
```

### Regular Maintenance Tasks
```bash
# Daily checks
- Verify oracle is updating
- Monitor coverage ratio
- Check for system events

# Weekly tasks
- Review gas usage
- Monitor contract interactions
- Validate multi-sig operations

# Monthly tasks
- Security review
- Compliance audit
- Performance analysis
```

### Event Monitoring
```bash
# Monitor key events
cast logs --from-block latest \
  --address FTH_GOLD_ADDRESS \
  --signature "Transfer(address,address,uint256)" \
  --rpc-url $RPC_URL

# Monitor role changes
cast logs --from-block latest \
  --address FTH_GOLD_ADDRESS \
  --signature "RoleGranted(bytes32,address,address)" \
  --rpc-url $RPC_URL
```

## Deployment Checklist

### Pre-deployment
- [ ] Complete audit preparation (`make audit`)
- [ ] Security analysis passed (`make security`)
- [ ] Compliance checks passed (`make compliance`)
- [ ] Test coverage > 80% (`make coverage`)
- [ ] Gas optimization completed (`make gas-report`)
- [ ] Multi-sig wallets configured
- [ ] Environment variables set
- [ ] Hardware wallets ready (mainnet)

### During Deployment
- [ ] Deploy in correct order
- [ ] Verify each contract deployment
- [ ] Configure roles immediately
- [ ] Test basic functionality
- [ ] Verify on Etherscan

### Post-deployment
- [ ] Transfer admin roles to multi-sig
- [ ] Revoke deployer permissions
- [ ] Configure system parameters
- [ ] Set up monitoring
- [ ] Document deployed addresses
- [ ] Create emergency procedures
- [ ] Notify stakeholders

## Contract Addresses

### Mainnet (TO BE UPDATED)
```
FTH Gold Token: 0x...
KYC Soulbound: 0x...
Stake Receipt: 0x...
Stake Locker: 0x...
Oracle: 0x...
```

### Testnet (Sepolia)
```
FTH Gold Token: 0x...
KYC Soulbound: 0x...
Stake Receipt: 0x...
Stake Locker: 0x...
Oracle: 0x...
```

---

**Deployment guide complete. Follow all security procedures for production deployment.**
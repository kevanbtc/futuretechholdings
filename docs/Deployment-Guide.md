# Deployment Guide - FTH Gold Protocol

## Deployment Overview

This guide covers the complete deployment process for the FTH Gold protocol, from local development to production mainnet deployment.

## Prerequisites

### Required Tools
- **Foundry**: Latest version with forge, cast, and anvil
- **Git**: For repository management
- **Hardware Wallet**: For production deployments (Ledger/Trezor)
- **Multi-signature Wallet**: Gnosis Safe for governance

### Required Accounts
- **Deployer Account**: For contract deployment
- **Admin Account**: For initial role assignment
- **Guardian Account**: For emergency controls
- **Treasury Account**: For fund management

## Environment Setup

### 1. Local Development Environment

```bash
# Clone and setup
git clone https://github.com/kevanbtc/futuretechholdings.git
cd futuretechholdings
make setup

# Start local blockchain
make anvil
```

Create `smart-contracts/fth-gold/.env`:
```bash
# Local Development
RPC_URL=http://localhost:8545
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ADMIN_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### 2. Testnet Environment

Create testnet configuration:
```bash
# Ethereum Sepolia
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=0x... # Testnet private key
ADMIN_ADDRESS=0x... # Your testnet admin address
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# Polygon Mumbai (optional)
POLYGON_RPC_URL=https://polygon-mumbai.infura.io/v3/YOUR_INFURA_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_API_KEY
```

### 3. Production Environment

**⚠️ SECURITY CRITICAL ⚠️**
```bash
# Production Mainnet
RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=USE_HARDWARE_WALLET # Never store real keys in .env
ADMIN_ADDRESS=0x... # Multi-signature wallet address
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# Multi-signature wallet addresses
GNOSIS_SAFE_ADDRESS=0x...
TIMELOCK_ADDRESS=0x...
```

## Deployment Scripts

### Core Deployment Script

The main deployment script is located at `smart-contracts/fth-gold/script/Deploy.s.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {FTHGold} from "../contracts/tokens/FTHGold.sol";
import {FTHStakeReceipt} from "../contracts/tokens/FTHStakeReceipt.sol";
import {KYCSoulbound} from "../contracts/compliance/KYCSoulbound.sol";
import {StakeLocker} from "../contracts/staking/StakeLocker.sol";
import {MockUSDT} from "../contracts/mocks/MockUSDT.sol";
import {MockPoRAdapter} from "../contracts/mocks/MockPoRAdapter.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        
        vm.startBroadcast(deployerKey);
        
        // Deploy core contracts
        FTHGold fthGold = new FTHGold(admin);
        FTHStakeReceipt stakeReceipt = new FTHStakeReceipt(admin);
        KYCSoulbound kycToken = new KYCSoulbound(admin);
        
        // Deploy mock contracts (testnet only)
        MockUSDT usdt = new MockUSDT();
        MockPoRAdapter porAdapter = new MockPoRAdapter();
        
        // Deploy staking contract
        StakeLocker stakeLocker = new StakeLocker(
            admin,
            IERC20(address(usdt)),
            fthGold,
            stakeReceipt,
            IPoRAdapter(address(porAdapter))
        );
        
        // Grant required roles
        fthGold.grantRole(fthGold.ISSUER_ROLE(), address(stakeLocker));
        stakeReceipt.grantRole(stakeReceipt.ISSUER_ROLE(), address(stakeLocker));
        
        vm.stopBroadcast();
        
        // Log deployment addresses
        console.log("FTH Gold:", address(fthGold));
        console.log("Stake Receipt:", address(stakeReceipt));
        console.log("KYC Soulbound:", address(kycToken));
        console.log("Stake Locker:", address(stakeLocker));
        console.log("Mock USDT:", address(usdt));
        console.log("Mock PoR Adapter:", address(porAdapter));
    }
}
```

## Deployment Procedures

### 1. Local Deployment

```bash
# Start local blockchain (terminal 1)
make anvil

# Deploy contracts (terminal 2)
make deploy-local

# Verify deployment
cast call $FTHG_ADDRESS "name()" --rpc-url http://localhost:8545
```

### 2. Testnet Deployment

```bash
# Set environment variables
export RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"
export PRIVATE_KEY="0x..." # Testnet key only
export ADMIN_ADDRESS="0x..."

# Deploy to testnet
cd smart-contracts/fth-gold
forge script script/Deploy.s.sol \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

# Save deployment addresses
echo "FTHG_ADDRESS=0x..." >> .env.testnet
echo "STAKE_LOCKER_ADDRESS=0x..." >> .env.testnet
```

### 3. Production Deployment

**⚠️ Production deployment requires extensive preparation and multiple security checks.**

#### Pre-Deployment Checklist

- [ ] **Security Audit Completed**: External audit with clean report
- [ ] **Multi-signature Wallets**: Gnosis Safe configured and tested
- [ ] **Oracle Contracts**: Real Chainlink PoR feeds configured
- [ ] **USDT Integration**: Real USDT contract addresses
- [ ] **Role Distribution**: Clear role assignment plan
- [ ] **Emergency Procedures**: Guardian actions tested
- [ ] **Gas Estimation**: Deployment cost calculated
- [ ] **Backup Plan**: Rollback procedures documented

#### Production Deployment Steps

1. **Final Security Review**
```bash
# Run comprehensive verification
make verify

# Generate final gas report
make test-gas

# Create deployment snapshot
make snapshot
```

2. **Deploy with Hardware Wallet**
```bash
# Use Ledger/Trezor for signing
forge script script/Deploy.s.sol \
    --rpc-url $RPC_URL \
    --ledger \
    --sender $DEPLOYER_ADDRESS \
    --broadcast \
    --verify
```

3. **Post-Deployment Configuration**
```bash
# Transfer ownership to multi-sig
cast send $FTHG_ADDRESS \
    "grantRole(bytes32,address)" \
    $DEFAULT_ADMIN_ROLE \
    $GNOSIS_SAFE_ADDRESS \
    --private-key $PRIVATE_KEY

# Renounce deployer admin role
cast send $FTHG_ADDRESS \
    "renounceRole(bytes32,address)" \
    $DEFAULT_ADMIN_ROLE \
    $DEPLOYER_ADDRESS \
    --private-key $PRIVATE_KEY
```

## Post-Deployment Configuration

### 1. Oracle Configuration

For production, replace mock oracles with real Chainlink feeds:

```solidity
// Deploy real PoR adapter
ChainlinkPoRAdapter realOracle = new ChainlinkPoRAdapter(
    CHAINLINK_GOLD_POR_FEED,
    ORACLE_STALENESS_THRESHOLD
);

// Update stake locker oracle
stakeLocker.updateOracle(address(realOracle));
```

### 2. Role Management

```bash
# Grant roles to appropriate addresses
cast send $CONTRACT_ADDRESS \
    "grantRole(bytes32,address)" \
    $GUARDIAN_ROLE \
    $GUARDIAN_ADDRESS

# Verify role assignments
cast call $CONTRACT_ADDRESS \
    "hasRole(bytes32,address)" \
    $GUARDIAN_ROLE \
    $GUARDIAN_ADDRESS
```

### 3. Parameter Configuration

```bash
# Set coverage ratio (125% = 12500 basis points)
cast send $STAKE_LOCKER_ADDRESS \
    "setCoverage(uint256)" \
    12500 \
    --private-key $GUARDIAN_KEY

# Configure other parameters as needed
```

## Verification & Testing

### 1. Contract Verification

```bash
# Verify on Etherscan
forge verify-contract \
    $CONTRACT_ADDRESS \
    src/tokens/FTHGold.sol:FTHGold \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $ADMIN_ADDRESS)
```

### 2. Integration Testing

```bash
# Test basic functionality
cast send $USDT_ADDRESS "approve(address,uint256)" $STAKE_LOCKER_ADDRESS 1000000
cast send $STAKE_LOCKER_ADDRESS "stake1Kg(uint256)" 1000000

# Verify state changes
cast call $STAKE_LOCKER_ADDRESS "position(address)" $USER_ADDRESS
```

### 3. Security Validation

```bash
# Verify access controls
cast call $FTHG_ADDRESS "hasRole(bytes32,address)" $ISSUER_ROLE $STAKE_LOCKER_ADDRESS

# Test pause functionality
cast send $FTHG_ADDRESS "pause()" --private-key $GUARDIAN_KEY
```

## Monitoring & Maintenance

### 1. Contract Monitoring

Set up monitoring for:
- Coverage ratio changes
- Oracle health status
- Large transactions
- Role changes
- Emergency events

### 2. Regular Maintenance

- **Monthly**: Coverage ratio review
- **Quarterly**: Security assessment
- **Annually**: Full system audit
- **Continuous**: Oracle monitoring

### 3. Emergency Procedures

```bash
# Emergency pause (Guardian only)
cast send $FTHG_ADDRESS "pause()" --private-key $GUARDIAN_KEY

# Update coverage ratio if needed
cast send $STAKE_LOCKER_ADDRESS "setCoverage(uint256)" 15000 --private-key $GUARDIAN_KEY
```

## Upgrade Procedures

### 1. Proxy Pattern (Future)

If implementing upgradeable contracts:

```solidity
// Transparent proxy pattern
TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
    implementation,
    admin,
    initData
);
```

### 2. Migration Strategy

For non-upgradeable contracts:

1. Deploy new contract versions
2. Pause old contracts
3. Migrate state and funds
4. Update integrations
5. Verify migration success

## Troubleshooting

### Common Issues

1. **Gas Estimation Failures**
   - Check RPC endpoint connectivity
   - Verify account has sufficient ETH
   - Review contract size limits

2. **Verification Failures**
   - Ensure correct compiler version
   - Check constructor arguments
   - Verify source code matches

3. **Role Assignment Issues**
   - Confirm deployer has admin role
   - Check role hierarchy
   - Verify multi-sig configuration

### Emergency Contacts

- **Technical Lead**: tech@futuretechholdings.com
- **Security Team**: security@futuretechholdings.com
- **Operations**: ops@futuretechholdings.com

---

**⚠️ Important Security Notice**

Never commit private keys to version control. Always use hardware wallets for production deployments. Test all procedures on testnets before mainnet deployment.

**Last Updated**: [Current Date]  
**Review Schedule**: Before each deployment  
**Emergency Procedures**: Available 24/7
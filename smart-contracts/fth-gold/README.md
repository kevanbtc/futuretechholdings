# FTH-G Gold-Backed Token System

**Boss Mode Implementation**: Complete production-ready system for Sravan's FTH-G program.

## Quick Overview

- **Asset**: 1 FTHG token = 1 kg vaulted gold
- **Entry**: $20,000 USD per kg (fixed price, private placement)
- **Lock**: 150 days mandatory staking period
- **Yield**: 10% monthly distributions (policy target, deficit accounting enabled)
- **Coverage**: Minimum 125% gold reserves backing
- **Compliance**: KYC soulbound tokens, private/accredited investors only

## Core Parameters (Production Ready)

```solidity
Lock Period:        150 days
Issue Price:        $20,000 per kg (fixed)
Monthly Payout:     10% of principal (policy target)
Coverage Floor:     125% (auto-pause if breached)
Redemption Fee:     1%
Oracle Staleness:   24 hours max
```

## System Architecture

### Core Contracts

- **FTHG**: Main token (ERC-20, 18 decimals, 1 token = 1 kg)
- **FTHStakeReceipt**: Non-transferable receipt during lock period
- **StakeLocker**: $20k/kg intake, 150-day lock, coverage-gated conversion
- **DistributionManager**: 10%/mo policy payouts with deficit accounting
- **RedemptionDesk**: NAV pricing with daily budget and throttling
- **OracleStub**: Price feeds and coverage ratio monitoring

### Safety Features

- **Coverage Guards**: All operations require ≥125% gold backing
- **Oracle Staleness**: Auto-pause if price/PoR data >24h old  
- **Deficit Accounting**: Shortfalls tracked transparently, no false promises
- **Emergency Pause**: Guardian role can halt operations instantly
- **KYC Gating**: All participants must hold valid soulbound credentials

## Quick Start

```bash
# Install dependencies
forge install

# Run tests
forge test -vv

# Deploy to testnet
forge script script/Deploy.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL

# Run full system test
forge test --match-test test_full_happy_path -vvv
```

## Test Coverage

- ✅ Full happy path: stake → lock → convert → distribute → redeem
- ✅ Oracle staleness blocks all operations
- ✅ Coverage breach prevention
- ✅ Deficit accounting when funding insufficient  
- ✅ Emergency pause functionality
- ✅ Daily redemption budget throttling

## Deployment Checklist

### Pre-Launch Requirements

- [ ] Oracle feeds configured (PoR + XAU/USD)
- [ ] Coverage ratio ≥125% verified
- [ ] KYC system operational  
- [ ] Multi-sig wallet configured
- [ ] Daily redemption budgets set
- [ ] Emergency contacts established

### Production Setup

1. Deploy contracts with proper admin roles
2. Configure oracle sources and staleness limits
3. Set initial coverage parameters (125% minimum)  
4. Enable deficit accounting for distributions
5. Set daily redemption budgets
6. Test emergency pause procedures

## Risk Management

### Circuit Breakers

- **Coverage < 125%**: Auto-pause minting, maintain redemptions
- **Oracle > 24h stale**: Pause all operations, emergency procedures
- **Price deviation > 2%**: Enable redemption throttling

### Operational Controls

- **Deficit Accounting**: ON by default, tracks funding shortfalls
- **Daily Caps**: 5% of supply or budget limit for redemptions
- **Multi-sig**: 3/5 threshold for all parameter changes
- **Timelock**: 48h delay for critical operations

## Economics Model

### Target Returns
- **10% monthly** distributions from operational cashflows
- **Coverage**: 125% minimum, 140% target
- **Funding**: From mining operations, gold lending, strategic partnerships

### Sustainability Features
- Deficit accounting prevents overpromising
- Coverage guards ensure full backing
- Redemption throttling prevents bank runs
- Transparent monthly funding reports

## Compliance Framework

### Private Placement Structure
- Invite-only access via KYC soulbound tokens
- Accredited/professional investors only
- Multi-jurisdiction support (UAE, US, EU, CH, SG)
- Continuous sanctions screening

### Documentation
- Private Placement Memorandum (PPM) 
- Risk disclosure statements
- Vault certificates and attestations
- Monthly operational reports

## Integration Guide

### For Developers
```javascript
// Stake 1 kg gold
await stakeLocker.stakeKg(1, { value: 20000e6 }); // $20k USDT

// After 150 days, convert to FTHG
await stakeLocker.convert();

// Check distribution eligibility
const stream = await distributionManager.streams(userAddress);

// Redeem at NAV
await redemptionDesk.redeemKg(1); // Burns FTHG, pays USDT
```

### For Operations
- Fund distribution contract monthly
- Monitor coverage ratios continuously  
- Set redemption budgets based on liquidity
- Trigger emergency pause if needed

## Monitoring & Alerts

### Key Metrics Dashboard
- Coverage ratio (≥125% required)
- Oracle freshness (≤24h required)
- Monthly distribution funding
- Daily redemption capacity
- Total value locked (TVL)

### Alert Thresholds
- Coverage drops below 130% (warning)
- Coverage drops below 125% (critical - auto-pause)
- Oracle stale >6h (warning), >24h (critical)
- Distribution shortfall >48h (warning)

## Security

### Audits & Testing
- Comprehensive unit test suite
- Invariant testing with Foundry
- Slither static analysis 
- External security audit recommended

### Access Control
- Role-based permissions (Admin, Minter, Burner, Guardian)
- Multi-signature requirements
- Timelock for parameter changes
- Emergency pause capabilities

---

## Contact

For technical questions or operational support:
- **System Architecture**: Review `docs/POLICY_MANIFEST.json`
- **Risk Framework**: See compliance documentation
- **Emergency Procedures**: Contact ops team immediately

**This is production-ready code. Handle with appropriate security measures.**
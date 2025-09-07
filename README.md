# FTH-G: Private, Asset-Backed Gold Program
1 token = 1 kg vaulted gold. Private, invite‑only, proof‑of‑reserves. Safe by design.

Audience
- CEO (Sravan) and leadership: strategy, governance, client promise, SLAs, KPIs
- Product + Ops: lifecycle, policies, runbooks, dashboards
- Engineering + Security: architecture, contracts, tests, deployment, monitoring

---

## Executive Summary (CEO-ready)

What it is
- A private, invite-only digital gold program for accredited clients.
- 1 FTH-G token equals 1 kg of LBMA-good delivery gold vaulted in DMCC.
- Clients on-ramp in USDT, stake for 5 months, auto-convert to FTH-G, receive monthly distributions, and can redeem in USDT or take delivery of 1 kg bars.

Why it matters
- Institutional-grade compliance and redemption with live Proof-of-Reserves (PoR).
- Sustainable yield funded by real activity (streams, offtake margins, hedging carry), not issuance dynamics.
- Ring-fenced SPVs and layered safeguards make adverse outcomes hard.

Client Promise
- Transparent reserves with daily PoR dashboard.
- Clear redemption choices (digital or physical) and predictable SLAs.
- Controlled growth with coverage targets (≥125% initial).

Decisions requested (to go live)
- Primary chain for issuance (e.g., Ethereum mainnet or L2).
- Timelock window (48–72 hours recommended).
- Initial tranche size (e.g., 20–100 kg) and coverage target (>=125%).
- Gnosis Safe addresses for Admin, Upgrader, Treasurer.
- Redemption policy floors and fee schedule (digital/physical).

---

## Lifecycle Overview (Client Journey)

1) Invite-only onboarding → KYC/AML soulbound pass (non-transferable).
2) USDT stake (5 months lock) → stake receipt (non-tradable).
3) Auto-conversion at unlock → 1 FTH-G (1 kg).
4) Monthly distributions from program cash flows (USDT and/or FTH-G).
5) Redemption options:
   - Digital: USDT at NAV (fees, floors, rate limits).
   - Physical: 1 kg bars from DMCC vault (fees + shipping/insurance).
6) Proof-of-Reserves: Chainlink adapters, vault certificates, bar lists notarized on IPFS.

```mermaid
flowchart LR
  A[Private Invite] --> B[KYC/AML Onboarding]
  B --> C[Soulbound KYC Pass (ERC-721)]
  C --> D[USDT Stake (5 months lock)]
  D --> E[Stake Receipt (non-transferable)]
  E -->|unlock| F[Auto-Convert]
  F --> G[FTH-G (1 kg)]
  G --> H[Monthly Distributions]
  G --> I[Redemptions]
  H --> H1[USDT or FTH-G]
  I --> I1[USDT at NAV] --> I3[Queue + Fees + KYC Valid]
  I --> I2[Physical 1kg Bar] --> I3
```

---

## Compliance Posture (Private, Invite-Only)

- KYC/AML soulbound token (SBT) gating every cash-touching action (stake, convert, redeem, claim).
- Accreditation and jurisdiction flags: UAE hub default; toggles for US Reg D/S, EU professional, CH security token, SG DPT.
- Sanctions screening (OFAC/PEP) and allow/deny lists via SanctionsGuard.
- Policy docs, fee schedules, vault certs and bar lists notarized on IPFS and referenced on-chain.
- Ring‑fenced SPVs per mine/program; clear governing law and arbitration venue (e.g., DIFC/ICC).

---

## “No‑Blowup” Architecture (Safeguards)

- Over-collateralization: ≥125% PoR coverage initially; never below 100%.
- Oracle safety: staleness, deviation, quorum checks; dual-source optional; auto-pause on anomaly.
- Strict RBAC: separate roles; no single key can mint and redeem; multisig + timelock for high‑risk actions.
- Circuit breakers: global Guardian pause; module-level pausing.
- Pull‑payments for distributions; reentrancy guards on external flows.
- Rate limits: per-wallet and global caps; daily distribution budgets.
- Upgrade safety: UUPS with layout checks, rollback tests, timelock and Safe execution.
- Invariants enforced in tests: coverage, supply, NAV bounds, gating.

---

## System Architecture (High-Level)

Components
- KYCSoulbound (ERC-721 SBT): onboarding gate with accreditation and jurisdiction.
- ComplianceRegistry: policy switches, allow/deny lists, sanctions guard integration.
- ChainlinkPoRAdapter: vault reserves, batch attestations, staleness/quorum checks.
- PriceFeedAdapter: XAU/USD oracle with bounds and deviation checks (follow‑up).
- FTHGold (ERC-20): 1 token = 1 kg (18 decimals).
- FTHStakeReceipt: non-transferable receipt during lock.
- StakeLocker: USDT intake, 5‑month lock, PoR coverage enforcement, auto‑convert.
- DistributionManager: monthly distributions with budget guardrails (follow‑up).
- RedemptionDesk: USDT and physical redemption paths (follow‑up).
- SystemRegistry: canonical addresses, policy versions, IPFS CIDs (follow‑up).
- GuardianPausable, SanctionsGuard, UUPSAuthUpgradeable: safety and upgrades.

```mermaid
graph TD
  subgraph Client
    U[Wallet] -->|USDT| SL
  end

  subgraph Compliance
    KYC[KYC SBT] --> CR[Compliance Registry]
    SG[Sanctions Guard] --> CR
  end

  subgraph Oracles
    POR[Chainlink PoR]
    PX[Chainlink XAU/USD]
  end

  SL[StakeLocker] --> SR[FTH Stake Receipt]
  SR -->|unlock| FG[FTH-G (ERC-20)]
  POR --> SL
  POR --> FG
  PX --> RD[RedemptionDesk]
  FG --> DM[DistributionManager]
  FG --> RD
  GRD[Guardian] --> SL
  GRD --> DM
  GRD --> RD
  REG[SystemRegistry] -. addrs/policy .-> All[All Modules]
```

---

## Monorepo Layout

```
fth-infrastructure/
├─ smart-contracts/
│  └─ fth-gold/
│     ├─ contracts/
│     │  ├─ access/AccessRoles.sol
│     │  ├─ compliance/KYCSoulbound.sol
│     │  ├─ oracle/ChainlinkPoRAdapter.sol         // + mock in tests
│     │  ├─ oracle/PriceFeedAdapter.sol            // follow-up PR
│     │  ├─ tokens/FTHGold.sol
│     │  ├─ tokens/FTHStakeReceipt.sol
│     │  ├─ staking/StakeLocker.sol
│     │  ├─ payout/DistributionManager.sol         // follow-up PR
│     │  ├─ payout/RedemptionDesk.sol              // follow-up PR
│     │  ├─ registry/SystemRegistry.sol            // follow-up PR
│     │  ├─ guards/GuardianPausable.sol            // follow-up PR
│     │  └─ upgrade/UUPSAuthUpgradeable.sol        // follow-up PR
│     ├─ script/
│     │  ├─ Deploy.s.sol                           // follow-up PR
│     │  ├─ Configure.s.sol                        // follow-up PR
│     │  └─ SeedDemo.s.sol                         // follow-up PR
│     ├─ test/
│     │  ├─ Stake.t.sol
│     │  ├─ Convert.t.sol
│     │  ├─ OracleGuards.t.sol
│     │  ├─ Access.t.sol
│     │  └─ Invariants.t.sol
│     ├─ foundry.toml
│     └─ README.md (module-level)
├─ docs/
│  ├─ CEO-brief.md
│  ├─ QA-Test-Matrix.md
│  ├─ Security-Checklist.md
│  ├─ Runbook.md
│  └─ Compliance-Checklist.md
└─ README.md (this file)
```

---

## Roles & Governance (RBAC)

- DEFAULT_ADMIN_ROLE (multisig; emergency only)
- GUARDIAN_ROLE (pause/unpause; circuit breaker)
- KYC_ISSUER_ROLE (mints KYC SBTs)
- ISSUER_ROLE (mints/burns FTH-G via program)
- TREASURER_ROLE (distributions, desks, fees)
- ORACLE_ROLE (adapters management, usually automated)
- UPGRADER_ROLE (UUPS upgrades via timelock)

Governance
- Gnosis Safe for Admin/Upgrader/Treasurer; distinct signers.
- Timelock for high‑risk parameter changes and upgrades (48–72h).
- Code‑path freeze for cash‑critical math (optional).

---

## Assurance Blueprint (What we test and prove)

Unit/spec coverage
- KYC SBT: mint/revoke/expiry; soulbound; jurisdiction/accreditation flags.
- Compliance gates: SBT‑valid wallets only for stake/convert/redeem/claim.
- StakeLocker: price check hooks; lock ≥150 days; per‑wallet/global caps; pause; events.
- PoR coverage: block mint/convert if coverage < threshold or oracle unhealthy.
- FTH-G token: pause, permit (2612), no fee-on-transfer; decimals sanity.
- StakeReceipt: non‑transfer by policy; burn on convert.
- DistributionManager: monthly schedule; budget caps; pull‑payments (follow‑up).
- RedemptionDesk: NAV floors; fees; USDT path; physical queue; KYC check; halt on oracle failure (follow‑up).
- Access: role separation; no single key can mint and redeem; guardian pause system‑wide.
- UUPS/Proxy: layout safety; only via timelock + Safe; rollback test.

Adversarial & chaos
- Reentrancy on all value flows.
- Oracle anomalies: stale/deviation/zero price/quorum fail → auto‑pause.
- Rounding/precision: kg↔token mapping, dust handling.
- DoS vectors: redemption queues; claim sets; gas spikes.
- MEV: large redemptions; minOut or commit‑reveal (design option).
- L2 sequencer downtime (if on L2): halt cash ops.

Invariants (always true)
- coverage = PoR_kg / FTHG_outstanding_kg ≥ coverageBps
- FTHG_minted_kg = receipts_converted_kg (net burns/redemptions)
- NAV within oracle bounds ± tolerance
- only KYC‑valid actors touch cash paths
- paused ⇒ no state that moves value

---

## Tooling & CI/CD

Local & Tests
- Foundry: unit, fuzz, invariants
  - Run: `forge test -vvv`
  - Gas report: `forge test --gas-report`
  - Invariants: `forge test --match-test Invariant --ffi`
- Mainnet/Testnet fork
  - `anvil --fork-url $RPC` then `forge test --fork-url http://127.0.0.1:8545`
- Echidna: property‑based fuzz (`echidna.yaml`)
- Slither/Mythril: static and symbolic analysis
- Optional: Halmos/Medusa/Manticore for formal proofs on critical gates

CI pipeline (per PR)
- Lint (solhint), compile, forge test, slither
- Echidna smoke job; nightly invariants
- Gas report diff (fail on regression)
- Storage layout check (when proxies enabled)
- Build/publish ABIs and TypeChain
- Required checks to merge; CODEOWNERS on critical dirs

---

## Dev Quickstart (MVP Contracts)

Prereqs
- Foundry (forge/cast/anvil)
- Node (optional), Git
- RPC provider (Alchemy/Infura/QuickNode)

Install
```bash
cd smart-contracts/fth-gold
forge install OpenZeppelin/openzeppelin-contracts
cp .env.example .env
# fill RPC_URL, PRIVATE_KEY (dev), USDT_ADDRESS, CHAINLINK_XAU_USD_FEED, ADMIN_SAFE
```

Build & Test
```bash
forge build
forge test -vv
```

Optional fork testing
```bash
anvil --fork-url $MAINNET_RPC
forge test --fork-url http://127.0.0.1:8545 -vv
```

---

## Configuration & Deployment

Environment
```ini
RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
PRIVATE_KEY=0xabc... # dev only; prod via Safe/HSM
USDT_ADDRESS=0x...   # per network (6 decimals)
CHAINLINK_XAU_USD_FEED=0x...
ADMIN_SAFE=0x...
COVERAGE_BPS=12500
LOCK_SECONDS=12960000  # 150 days
```

Deploy (scripts in follow‑up PR)
```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
forge script script/Configure.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Seed demo (local/testnet)
```bash
forge script script/SeedDemo.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## Operations Runbook (Condensed)

Normal ops
- Onboard: mint KYC SBT (jurisdiction/accreditation/expiry).
- Stake: accept USDT; mint stake receipt; set unlock timestamp.
- Convert: after lock, check PoR health & coverage; mint FTH‑G; burn receipt.
- Distribute: monthly via pull‑payments with budget guardrails.
- Redeem: USDT at NAV (floors/fees) or physical 1 kg (escrowed, KYC re‑check).

Pausing & incidents
- Triggers: oracle anomaly, coverage breach, governance action.
- Guardian pause: stake/convert/distribute/redeem as appropriate.
- Resume: verify oracle healthy; coverage restored; post‑incident report.

Oracle anomaly
- Validate Chainlink feed; compare secondary/TWAP; check deviation and staleness thresholds.
- If out‑of‑policy, remain paused; escalate to governance; client comms.

Redemption surge
- Apply rate limits and NAV floors; manage queue; fund digital desk; track SLA.

KYC revocation
- Revoke SBT; block cash ops; notify compliance; document rationale.

Upgrades/params
- Propose via timelock; 48–72h delay; execute via Safe; broadcast change.

---

## SLAs & KPIs

SLAs
- Digital redemption: ≤ 3 business days
- Physical redemption: 5–10 business days (vault logistics)
- Oracle uptime: ≥ 99.9%; auto‑pause on failure
- Incident response: pause within minutes; client notice within 4 hours

KPIs
- Coverage ratio (≥125% initial; ≥100% always)
- NAV deviation within bounds
- Redemption queue length and SLA adherence
- Distribution on‑time rate
- Incident MTTP/MTTR
- Program AUM, default rate (zero target), VaR within limits

---

## Revenue Model (Illustrative, configurable)

- On‑/off‑ramp spread: 0.10–0.30% per leg
- Origination/arranger: 1.0–2.0% per deal
- Platform/admin: 0.30–0.80% p.a. on AUM
- Vault/redemption/storage: 0.20–0.50% (pass‑through + margin)
- Private market‑making spreads: 10–40 bps
- Streaming/royalty override: 0.5–2.0% of gross value
- Receivables finance: 1–2% per 30–90 days
- Hedging carry: programmatic; sized via risk budget

---

## Roadmap

Phase A (0–6 months)
- LBMA‑backed tranches; stake → convert
- Start distributions from streams/offtake margins/hedging carry
- Private market‑making desk; PoR dashboard live

Phase B (6–12 months)
- Increase tranche sizes; receivables tokenization; hedging program
- DistributionManager and RedemptionDesk fully online

Phase C (12+ months)
- Structured notes; gram‑rail for supply chain; ESG/offset co‑monetization

Upcoming PRs (engineering)
- DistributionManager (pull‑payments + budget)
- RedemptionDesk (USDT + physical queue)
- Chainlink PriceFeedAdapter (staleness/deviation bounds)
- SystemRegistry + Guardian + SanctionsGuard
- Deploy/config scripts; mocks; full test suites; CI workflows

---

## FAQs

Q: Is 1 FTH‑G always redeemable for 1 kg?
- Under normal operations, yes via digital NAV redemption or physical 1 kg bars subject to fees and SLAs. Program enforces PoR ≥ 100% at all times and ≥125% until steady‑state.

Q: Where are the reserves?
- DMCC vault accounts with certificates; dual‑jurisdiction standby vaults optional. All certs/bar lists hashed and posted to IPFS; Chainlink PoR adapters surface on‑chain.

Q: What funds the yield?
- Distributions target realized program cash flows: streaming premia, offtake margins, hedging carry, market‑making P&L. Budget guardrails prevent over‑distribution.

Q: What happens if the oracle fails?
- Auto‑pause of mint/convert/redeem/distribute; incident runbook executed; service resumes after health checks and governance sign‑off.

Q: How do we prevent key misuse?
- Strict RBAC; no single key controls mint and redeem; high‑risk actions gated by timelock + Gnosis Safe multisig.

---

## Legal & Compliance Note

- This is a private, invite‑only program for qualified investors. No public solicitation. Disclosures (PPM, fee schedules, risk policy, redemption policy) must be reviewed and acknowledged during onboarding. Jurisdictional toggles are enforced on‑chain via ComplianceRegistry and KYC SBT.

---

## Pointers for Review

- CEO overview: see sections Executive Summary, Lifecycle, Safeguards, SLAs/KPIs, Revenue Model, Roadmap.
- Ops: see Compliance, Runbook, SLAs, KPIs.
- Engineering: see Architecture, Monorepo Layout, Tooling/CI, Quickstart, Tests/Assurance.

---

## Getting Help

- Security incidents: trigger Guardian pause and follow Runbook.
- Oracle issues: consult Oracles section in Runbook; check dashboards.
- Governance changes: open a proposal via timelock; Safe executes after delay.

---

Appendix: Commands

Build & test
```bash
cd smart-contracts/fth-gold
forge build
forge test -vvv --gas-report
```

Fork tests
```bash
anvil --fork-url $MAINNET_RPC
forge test --fork-url http://127.0.0.1:8545 -vv
```

Deploy (scripts in follow‑up PR)
```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
forge script script/Configure.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Environment template
```ini
RPC_URL=
PRIVATE_KEY=
USDT_ADDRESS=
CHAINLINK_XAU_USD_FEED=
ADMIN_SAFE=
COVERAGE_BPS=12500
LOCK_SECONDS=12960000
```

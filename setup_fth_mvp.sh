set -euo pipefail

mkdir -p .github/workflows
mkdir -p smart-contracts/fth-gold/contracts/{access,compliance,oracle,tokens,staking,mocks}
mkdir -p smart-contracts/fth-gold/{test,script,docs}
mkdir -p docs

cat > .github/workflows/ci.yml <<'YAML'
name: fth-gold-ci
on: { push: { branches: [ main ] }, pull_request: { branches: [ main ] } }
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
        with: { version: nightly }
      - name: Build & Test
        working-directory: smart-contracts/fth-gold
        run: |
          forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
          forge build
          forge test -vv
YAML

cat > smart-contracts/fth-gold/foundry.toml <<'TOML'
[profile.default]
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 200
src = "contracts"
out = "out"
libs = ["lib"]
TOML

cat > smart-contracts/fth-gold/.gitignore <<'TXT'
out/
cache/
lib/
.env
coverage/
TXT

cat > smart-contracts/fth-gold/.env.example <<'ENV'
# RPC and deployer
RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
PRIVATE_KEY=0xabc... # dev only; use Safe/HSM for prod
USDT_ADDRESS=0x0000000000000000000000000000000000000000
ENV

# Access roles
cat > smart-contracts/fth-gold/contracts/access/AccessRoles.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
abstract contract AccessRoles is AccessControl {
    bytes32 public constant GUARDIAN_ROLE   = keccak256("GUARDIAN_ROLE");
    bytes32 public constant KYC_ISSUER_ROLE = keccak256("KYC_ISSUER_ROLE");
    bytes32 public constant ISSUER_ROLE     = keccak256("ISSUER_ROLE");
    bytes32 public constant TREASURER_ROLE  = keccak256("TREASURER_ROLE");
    bytes32 public constant ORACLE_ROLE     = keccak256("ORACLE_ROLE");
    bytes32 public constant UPGRADER_ROLE   = keccak256("UPGRADER_ROLE");
}
SOL

# KYC SBT
cat > smart-contracts/fth-gold/contracts/compliance/KYCSoulbound.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {AccessRoles} from "../access/AccessRoles.sol";
contract KYCSoulbound is ERC721, AccessRoles {
    struct KYCData { bytes32 idHash; bytes32 passportHash; uint48 expiry; uint16 juris; bool accredited; }
    mapping(address => KYCData) public kycOf;
    constructor(address admin) ERC721("FTH KYC Pass","KYC-PASS"){
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KYC_ISSUER_ROLE, admin);
    }
    function mint(address to, KYCData calldata d) external onlyRole(KYC_ISSUER_ROLE) {
        require(!_exists(uint160(to)), "Exists");
        _safeMint(to, uint160(to)); kycOf[to] = d;
    }
    function revoke(address to) external onlyRole(KYC_ISSUER_ROLE) { _burn(uint160(to)); delete kycOf[to]; }
    function isValid(address user) public view returns(bool){ KYCData memory d = kycOf[user]; return d.expiry > block.timestamp; }
    function _update(address to, uint256 id, address auth) internal override returns(address){
        if (_ownerOf(id) != address(0)) revert("SBT"); return super._update(to,id,auth);
    }
}
SOL

# PoR interface + mock
cat > smart-contracts/fth-gold/contracts/oracle/ChainlinkPoRAdapter.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
interface IPoRAdapter {
    function totalVaultedKg() external view returns (uint256);
    function lastUpdate() external view returns (uint256);
    function isHealthy() external view returns (bool);
}
SOL
cat > smart-contracts/fth-gold/contracts/mocks/MockPoRAdapter.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IPoRAdapter} from "../oracle/ChainlinkPoRAdapter.sol";
contract MockPoRAdapter is IPoRAdapter {
    uint256 public vaultedKg; uint256 public updated;
    function set(uint256 kg) external { vaultedKg = kg; updated = block.timestamp; }
    function totalVaultedKg() external view returns (uint256) { return vaultedKg; }
    function lastUpdate() external view returns (uint256) { return updated; }
    function isHealthy() external view returns (bool) { return updated + 1 hours >= block.timestamp; }
}
SOL

# FTH-G token
cat > smart-contracts/fth-gold/contracts/tokens/FTHGold.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Pausable} from "openzeppelin-contracts/utils/Pausable.sol";
import {AccessRoles} from "../access/AccessRoles.sol";
contract FTHGold is ERC20, ERC20Permit, Pausable, AccessRoles {
    constructor(address admin) ERC20("FTH Gold (1 kg)","FTH-G") ERC20Permit("FTH Gold (1 kg)"){
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
        _grantRole(GUARDIAN_ROLE, admin);
    }
    function pause() external onlyRole(GUARDIAN_ROLE){ _pause(); }
    function unpause() external onlyRole(GUARDIAN_ROLE){ _unpause(); }
    function mint(address to, uint256 amountKg) external onlyRole(ISSUER_ROLE) { _mint(to, amountKg * 1e18); }
    function burn(address from, uint256 amountKg) external onlyRole(ISSUER_ROLE) { _burn(from, amountKg * 1e18); }
    function _update(address from, address to, uint256 value) internal override whenNotPaused { super._update(from,to,value); }
}
SOL

# Stake Receipt (non-transferable)
cat > smart-contracts/fth-gold/contracts/tokens/FTHStakeReceipt.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {AccessRoles} from "../access/AccessRoles.sol";
contract FTHStakeReceipt is ERC20, AccessRoles {
    mapping(address => bool) public transferable;
    constructor(address admin) ERC20("FTH Stake Receipt","FTH-SR"){
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
    }
    function mint(address to, uint256 amount) external onlyRole(ISSUER_ROLE){ _mint(to, amount); }
    function burn(address from, uint256 amount) external onlyRole(ISSUER_ROLE){ _burn(from, amount); }
    function setTransferable(address a, bool t) external onlyRole(DEFAULT_ADMIN_ROLE){ transferable[a]=t; }
    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && !transferable[from]) revert("NON_TRANSFERABLE");
        super._update(from, to, value);
    }
}
SOL

# Mock USDT
cat > smart-contracts/fth-gold/contracts/mocks/MockUSDT.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
contract MockUSDT {
    string public name = "Mock USDT"; string public symbol = "USDT"; uint8 public decimals = 6;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address to, uint256 amt) external { balanceOf[to]+=amt; emit Transfer(address(0),to,amt); }
    function approve(address s, uint256 v) external returns(bool){ allowance[msg.sender][s]=v; emit Approval(msg.sender,s,v); return true; }
    function transfer(address to, uint256 v) external returns(bool){ _transfer(msg.sender,to,v); return true; }
    function transferFrom(address f,address t,uint256 v) external returns(bool){
        uint256 a=allowance[f][msg.sender]; require(a>=v,"allow"); allowance[f][msg.sender]=a-v; _transfer(f,t,v); return true;
    }
    function _transfer(address f,address t,uint256 v) internal { require(balanceOf[f]>=v,"bal"); balanceOf[f]-=v; balanceOf[t]+=v; emit Transfer(f,t,v); }
}
SOL

# Stake Locker
cat > smart-contracts/fth-gold/contracts/staking/StakeLocker.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AccessRoles} from "../access/AccessRoles.sol";
import {FTHGold} from "../tokens/FTHGold.sol";
import {FTHStakeReceipt} from "../tokens/FTHStakeReceipt.sol";
import {IPoRAdapter} from "../oracle/ChainlinkPoRAdapter.sol";
interface IERC20 { function transferFrom(address,address,uint256) external returns(bool); }
contract StakeLocker is AccessRoles {
    IERC20 public immutable USDT;
    FTHGold public immutable FTHG;
    FTHStakeReceipt public immutable RECEIPT;
    IPoRAdapter public por;
    uint256 public constant LOCK_SECONDS = 150 days;
    uint256 public coverageBps = 12500;
    struct Pos { uint128 amountKg; uint48 start; uint48 unlock; }
    mapping(address=>Pos) public position;
    event Staked(address indexed user, uint256 usdtPaid, uint256 kg);
    event Converted(address indexed user, uint256 kg);
    constructor(address admin, IERC20 usdt, FTHGold fthg, FTHStakeReceipt receipt, IPoRAdapter _por){
        _grantRole(DEFAULT_ADMIN_ROLE, admin); _grantRole(GUARDIAN_ROLE, admin);
        USDT = usdt; FTHG = fthg; RECEIPT = receipt; por = _por;
    }
    function stake1Kg(uint256 usdtAmount) external {
        require(usdtAmount > 0, "bad amount");
        require(position[msg.sender].amountKg == 0, "already");
        USDT.transferFrom(msg.sender, address(this), usdtAmount);
        position[msg.sender] = Pos({amountKg: 1, start: uint48(block.timestamp), unlock: uint48(block.timestamp + LOCK_SECONDS)});
        RECEIPT.mint(msg.sender, 1e18);
        emit Staked(msg.sender, usdtAmount, 1);
    }
    function convert() external {
        Pos memory p = position[msg.sender];
        require(p.amountKg > 0, "no pos");
        require(block.timestamp >= p.unlock, "locked");
        require(por.isHealthy(), "por stale");
        uint256 outstanding = FTHG.totalSupply()/1e18;
        require((por.totalVaultedKg()*1e4) / (outstanding + 1) >= coverageBps, "coverage");
        RECEIPT.burn(msg.sender, 1e18);
        FTHG.mint(msg.sender, 1);
        delete position[msg.sender];
        emit Converted(msg.sender, 1);
    }
    function setCoverage(uint256 bps) external onlyRole(GUARDIAN_ROLE){ require(bps>=10000,"min=100%"); coverageBps=bps; }
}
SOL

# Tests
cat > smart-contracts/fth-gold/test/Stake.t.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Test.sol";
import "../contracts/tokens/FTHGold.sol";
import "../contracts/tokens/FTHStakeReceipt.sol";
import "../contracts/staking/StakeLocker.sol";
import "../contracts/mocks/MockUSDT.sol";
import "../contracts/mocks/MockPoRAdapter.sol";
contract StakeTest is Test {
    FTHGold fthg; FTHStakeReceipt receipt; StakeLocker locker; MockUSDT usdt; MockPoRAdapter por;
    address admin = address(0xA11CE); address user  = address(0xB0B);
    function setUp() public {
        fthg = new FTHGold(admin); receipt = new FTHStakeReceipt(admin);
        usdt = new MockUSDT(); por = new MockPoRAdapter();
        locker = new StakeLocker(admin, IERC20(address(usdt)), fthg, receipt, IPoRAdapter(address(por)));
        vm.startPrank(admin); receipt.grantRole(receipt.ISSUER_ROLE(), address(locker)); fthg.grantRole(fthg.ISSUER_ROLE(), address(locker)); vm.stopPrank();
        usdt.mint(user, 20_000 * 1e6);
    }
    function testStakeAndConvertHappy() public {
        por.set(1000);
        vm.startPrank(user);
        usdt.approve(address(locker), type(uint256).max);
        locker.stake1Kg(20_000 * 1e6);
        vm.warp(block.timestamp + 151 days);
        locker.convert();
        vm.stopPrank();
        assertEq(fthg.balanceOf(user), 1e18);
        assertEq(fthg.totalSupply(), 1e18);
    }
}
SOL

cat > smart-contracts/fth-gold/test/OracleGuards.t.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Test.sol";
import "../contracts/tokens/FTHGold.sol";
import "../contracts/tokens/FTHStakeReceipt.sol";
import "../contracts/staking/StakeLocker.sol";
import "../contracts/mocks/MockUSDT.sol";
import "../contracts/mocks/MockPoRAdapter.sol";
contract OracleGuardsTest is Test {
    FTHGold fthg; FTHStakeReceipt receipt; StakeLocker locker; MockUSDT usdt; MockPoRAdapter por;
    address admin = address(0xA11CE); address user  = address(0xB0B);
    function setUp() public {
        fthg = new FTHGold(admin); receipt = new FTHStakeReceipt(admin);
        usdt = new MockUSDT(); por = new MockPoRAdapter();
        locker = new StakeLocker(admin, IERC20(address(usdt)), fthg, receipt, IPoRAdapter(address(por)));
        vm.startPrank(admin); receipt.grantRole(receipt.ISSUER_ROLE(), address(locker)); fthg.grantRole(fthg.ISSUER_ROLE(), address(locker)); vm.stopPrank();
        usdt.mint(user, 20_000 * 1e6);
    }
    function testRevertsIfPoRStale() public {
        vm.startPrank(user);
        usdt.approve(address(locker), type(uint256).max);
        locker.stake1Kg(20_000 * 1e6);
        vm.warp(block.timestamp + 151 days);
        vm.expectRevert();
        locker.convert();
    }
}
SOL

# Scripts
cat > smart-contracts/fth-gold/script/Deploy.s.sol <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import "../contracts/tokens/FTHGold.sol";
import "../contracts/tokens/FTHStakeReceipt.sol";
import "../contracts/staking/StakeLocker.sol";
import "../contracts/mocks/MockUSDT.sol";
import "../contracts/mocks/MockPoRAdapter.sol";
contract Deploy is Script {
    function run() external {
        address admin = vm.envAddress("ADMIN", msg.sender);
        vm.startBroadcast();
        FTHGold fthg = new FTHGold(admin);
        FTHStakeReceipt sr = new FTHStakeReceipt(admin);
        MockUSDT usdt = new MockUSDT();
        MockPoRAdapter por = new MockPoRAdapter();
        StakeLocker locker = new StakeLocker(admin, IERC20(address(usdt)), fthg, sr, IPoRAdapter(address(por)));
        sr.grantRole(sr.ISSUER_ROLE(), address(locker));
        fthg.grantRole(fthg.ISSUER_ROLE(), address(locker));
        vm.stopBroadcast();
    }
}
SOL

# Top-level docs
cat > README.md <<'MD'
# FTH-G: Private, Asset-Backed Gold Program
1 token = 1 kg vaulted gold. Private, invite-only, proof-of-reserves. Safe by design.
See `docs/` and `smart-contracts/fth-gold/` for details.
MD
cat > docs/CEO-brief.md <<'MD'
# CEO Brief — FTH-G Private Placement (1 token = 1 kg)
Client USDT → 5-month lock (stake receipt) → converts to FTH-G with on-chain PoR checks.
Redemption: USDT or 1 kg bar. Coverage guard, AML/KYC gating, pause/circuit-breakers, multisig governance.
MD
cat > docs/Compliance-Checklist.md <<'MD'
# Compliance Checklist (Private)
Invite-only; SBT after KYC/AML (accreditation & jurisdiction flags); DMCC/VARA hub; PoR attestations; IPFS-notarized PPM/fees; sanctions lists.
MD
cat > docs/Security-Checklist.md <<'MD'
# Security Checklist (Pre-Launch)
Gnosis Safe + timelock; reentrancy guards; pausability; oracle staleness/deviation checks; coverage guard >=100% (125% early); caps.
MD
cat > docs/QA-Test-Matrix.md <<'MD'
# QA & Invariants Matrix
Stake lifecycle; PoR guard; KYC gates; access controls; pause behavior; invariants for coverage & supply; price NAV tests (when price adapter added).
MD

echo "✅ Scaffold created."

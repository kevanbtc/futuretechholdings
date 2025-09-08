// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/token/FTHG.sol";
import "../contracts/token/FTHStakeReceipt.sol";
import "../contracts/staking/StakeLocker.sol";
import "../contracts/yield/DistributionManager.sol";
import "../contracts/desk/RedemptionDesk.sol";
import "../contracts/oracle/OracleStub.sol";
import "../contracts/compliance/KYCSoulbound.sol";
import "../contracts/compliance/ComplianceRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FTHGSystemTest is Test {
    FTHG public token;
    FTHStakeReceipt public sr;
    StakeLocker public locker;
    DistributionManager public dist;
    RedemptionDesk public redemption;
    OracleStub public oracle;
    MockUSDT public usdt;
    KYCSoulbound public kyc;
    ComplianceRegistry public compliance;
    
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address admin = address(this);

    function setUp() public {
        // Deploy base contracts
        usdt = new MockUSDT();
        token = new FTHG();
        kyc = new KYCSoulbound(admin);
        compliance = new ComplianceRegistry(admin);
        oracle = new OracleStub();
        
        // Deploy main system contracts first
        locker = new StakeLocker(
            IERC20(address(usdt)),
            FTHStakeReceipt(address(0)), // placeholder
            token,
            oracle,
            kyc,
            compliance
        );
        
        // Deploy stake receipt with admin
        sr = new FTHStakeReceipt(admin);
        
        // Update locker reference (in a real deployment this would be done in constructor)
        // For testing, we'll create a new locker with the correct SR
        locker = new StakeLocker(
            IERC20(address(usdt)),
            sr,
            token,
            oracle,
            kyc,
            compliance
        );
        
        dist = new DistributionManager(
            IERC20(address(usdt)),
            token,
            oracle
        );
        
        redemption = new RedemptionDesk(
            IERC20(address(usdt)),
            token,
            oracle
        );

        // Set up roles and permissions
        token.grantRole(token.MINTER_ROLE(), address(locker));
        token.grantRole(token.BURNER_ROLE(), address(redemption));
        dist.grantRole(dist.FUNDER_ROLE(), address(this));
        sr.grantRole(sr.ISSUER_ROLE(), address(locker));

        // Fund test users with USDT
        usdt.mint(alice, 100_000e6); // $100k
        usdt.mint(bob, 100_000e6);
        usdt.mint(address(this), 1_000_000e6); // For distributions
        usdt.mint(address(redemption), 1_000_000e6); // For redemptions

        // Set up redemption parameters
        redemption.setDailyBudget(100_000e6);

        // Set up KYC and compliance for test users
        _setupKYCAndCompliance(alice);
        _setupKYCAndCompliance(bob);

        // Approve USDT spending
        vm.prank(alice);
        usdt.approve(address(locker), type(uint256).max);
        vm.prank(bob);
        usdt.approve(address(locker), type(uint256).max);
        usdt.approve(address(dist), type(uint256).max);
    }

    function _setupKYCAndCompliance(address user) internal {
        // Mint KYC SBT
        KYCSoulbound.KYCData memory kycData = KYCSoulbound.KYCData({
            idHash: keccak256(abi.encodePacked(user, "id")),
            passportHash: keccak256(abi.encodePacked(user, "passport")),
            expiry: uint48(block.timestamp + 365 days),
            jurisdiction: 784, // UAE
            accredited: true
        });
        kyc.mint(user, kycData);

        // Set compliance eligibility
        compliance.setEligibility(
            user,
            true, // kyc
            bytes2("AE"), // country UAE
            bytes1(0x01), // accredited
            uint64(block.timestamp + 365 days) // expiry
        );

        // Grant market access
        compliance.setMarketAccess(user, compliance.MARKET_UAE_DMCC(), true);
    }

    function test_fullSystemFlow() public {
        // 1. Alice stakes 1 kg @ $20k
        vm.prank(alice);
        locker.stakeKg(1);
        
        assertEq(sr.balanceOf(alice), 1e18);
        assertEq(usdt.balanceOf(alice), 80_000e6); // 100k - 20k
        
        // 2. Warp to unlock period (151 days)
        vm.warp(block.timestamp + 151 days);
        
        // Update oracle timestamps to prevent staleness
        oracle.setPrice(oracle.price());
        oracle.setCoverage(oracle.coverageBps());
        
        // 3. Alice converts SR to FTHG
        vm.prank(alice);
        locker.convert();
        
        assertEq(token.balanceOf(alice), 1e18);
        assertEq(sr.balanceOf(alice), 0);
        
        // 4. Start distribution stream for Alice
        dist.startStream(alice);
        
        // 5. Fund distribution contract with sufficient USDT
        dist.fund(50_000e6); // $50k for distributions
        
        // 6. Warp 31 days and trigger distribution
        vm.warp(block.timestamp + 31 days);
        
        // Update oracle timestamps again
        oracle.setPrice(oracle.price());
        oracle.setCoverage(oracle.coverageBps());
        
        address[] memory users = new address[](1);
        users[0] = alice;
        dist.tick(users);
        
        // Alice should receive 10% monthly payout in USDT
        // 1 kg * 10% = 0.1 kg worth of USDT (policy calculation)
        uint256 aliceUSDTAfterDistribution = usdt.balanceOf(alice);
        assertGt(aliceUSDTAfterDistribution, 80_000e6);
        
        // 7. Test redemption at NAV
        uint256 aliceUSDTBefore = usdt.balanceOf(alice);
        
        // Update oracle timestamps before redemption
        oracle.setPrice(oracle.price());
        oracle.setCoverage(oracle.coverageBps());
        
        vm.prank(alice);
        redemption.redeemKg(1);
        
        // Alice should receive NAV minus 1% fee
        assertEq(token.balanceOf(alice), 0);
        assertGt(usdt.balanceOf(alice), aliceUSDTBefore);
    }

    function test_oracleStalenessPreventsOperations() public {
        // Set up Alice's position first
        vm.prank(alice);
        locker.stakeKg(1);
        
        // Make oracle stale (>24 hours)
        vm.warp(block.timestamp + 25 hours);
        
        // Should revert on convert due to stale oracle
        vm.warp(block.timestamp + 151 days - 25 hours);
        vm.prank(alice);
        vm.expectRevert();
        locker.convert();
        
        // Should revert on distribution
        dist.startStream(alice);
        address[] memory users = new address[](1);
        users[0] = alice;
        vm.expectRevert();
        dist.tick(users);

        // Should revert on redemption
        vm.expectRevert();
        redemption.redeemKg(1);
    }

    function test_coverageGuardPreventsOperations() public {
        // Set coverage below minimum (125%)
        oracle.setCoverage(12_000); // 120% < 125% minimum
        
        // Should revert on stake
        vm.prank(alice);
        vm.expectRevert();
        locker.stakeKg(1);
        
        // Reset coverage and stake
        oracle.setCoverage(13_000);
        vm.prank(alice);
        locker.stakeKg(1);
        
        // Lower coverage again
        oracle.setCoverage(12_000);
        
        vm.warp(block.timestamp + 151 days);
        vm.prank(alice);
        vm.expectRevert();
        locker.convert();

        // Should also block redemptions
        vm.expectRevert();
        redemption.redeemKg(1);
    }

    function test_deficitAccounting() public {
        // Stake and convert
        vm.prank(alice);
        locker.stakeKg(1);
        
        vm.warp(block.timestamp + 151 days);
        
        // Update oracle timestamps
        oracle.setPrice(oracle.price());
        oracle.setCoverage(oracle.coverageBps());
        
        vm.prank(alice);
        locker.convert();
        
        dist.startStream(alice);
        
        // Fund with insufficient amount for full 10% payout
        dist.fund(50e6); // Only $50 instead of full 10% policy amount
        
        vm.warp(block.timestamp + 31 days);
        
        // Update oracle timestamps again
        oracle.setPrice(oracle.price());
        oracle.setCoverage(oracle.coverageBps());
        
        address[] memory users = new address[](1);
        users[0] = alice;
        dist.tick(users);
        
        // Check deficit was recorded
        (,, uint128 deficit) = dist.streams(alice);
        assertGt(deficit, 0);
        
        // Alice should still receive what was available
        assertGt(usdt.balanceOf(alice), 80_000e6);
    }

    function test_pauseFunctionality() public {
        // Stake first
        vm.prank(alice);
        locker.stakeKg(1);
        
        // Pause the system
        locker.pause(true);
        dist.pause(true);
        redemption.pause(true);
        
        // All operations should fail when paused
        vm.warp(block.timestamp + 151 days);
        vm.prank(alice);
        vm.expectRevert();
        locker.convert();
        
        address[] memory users = new address[](1);
        users[0] = alice;
        vm.expectRevert();
        dist.tick(users);
        
        vm.expectRevert();
        redemption.redeemKg(1);
    }

    function test_kycComplianceGating() public {
        // Revoke Alice's KYC
        kyc.revoke(alice);
        
        // Should not be able to stake without valid KYC
        vm.prank(alice);
        vm.expectRevert();
        locker.stakeKg(1);
        
        // Re-issue KYC but without compliance eligibility
        KYCSoulbound.KYCData memory kycData = KYCSoulbound.KYCData({
            idHash: keccak256(abi.encodePacked(alice, "id")),
            passportHash: keccak256(abi.encodePacked(alice, "passport")),
            expiry: uint48(block.timestamp + 365 days),
            jurisdiction: 784,
            accredited: true
        });
        kyc.mint(alice, kycData);
        
        // Remove market access
        compliance.setMarketAccess(alice, compliance.MARKET_UAE_DMCC(), false);
        
        // Should still fail due to compliance
        vm.prank(alice);
        vm.expectRevert();
        locker.stakeKg(1);
    }

    function test_soulboundBehavior() public {
        // KYC tokens should be non-transferable
        uint256 tokenId = kyc.tokenIdOf(alice);
        
        vm.prank(alice);
        vm.expectRevert(bytes("KYC: soulbound"));
        kyc.transferFrom(alice, bob, tokenId);
        
        // Stake receipts should be non-transferable
        vm.prank(alice);
        locker.stakeKg(1);
        
        vm.prank(alice);
        vm.expectRevert(bytes("SBT"));
        sr.transfer(bob, 1e18);
    }

    function test_redemptionBudgetThrottling() public {
        // Set a low daily budget
        redemption.setDailyBudget(1000e6); // $1k
        
        // Stake and convert for Alice and Bob
        vm.prank(alice);
        locker.stakeKg(1);
        vm.prank(bob);
        locker.stakeKg(1);
        
        vm.warp(block.timestamp + 151 days);
        
        // Update oracle timestamps
        oracle.setPrice(oracle.price());
        oracle.setCoverage(oracle.coverageBps());
        
        vm.prank(alice);
        locker.convert();
        vm.prank(bob);
        locker.convert();
        
        // Alice redeems successfully within budget
        vm.prank(alice);
        redemption.redeemKg(1);
        
        // Bob should fail due to budget exceeded
        vm.prank(bob);
        vm.expectRevert();
        redemption.redeemKg(1);
    }
}

// Mock USDT contract for testing
contract MockUSDT is IERC20 {
    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 6;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function totalSupply() external view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view returns (uint256) { return _balances[account]; }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) { 
        return _allowances[owner][spender]; 
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "USDT: allowance exceeded");
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }
    
    function mint(address to, uint256 amount) external { 
        _balances[to] += amount; 
        _totalSupply += amount; 
    }
}
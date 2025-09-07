// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/compliance/KYCSoulbound.sol";
import "../contracts/compliance/ComplianceRegistry.sol";
import "../contracts/token/FTHG.sol";
import "../contracts/token/FTHStakeReceipt.sol";
import "../contracts/staking/StakeLocker.sol";
import "../contracts/yield/DistributionManager.sol";
import "../contracts/desk/RedemptionDesk.sol";
import "../contracts/oracle/OracleStub.sol";
import "../contracts/payment/OffchainStakeOrchestrator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deploy is Script {
    
    struct DeploymentAddresses {
        address admin;
        address usdt;
        KYCSoulbound kyc;
        ComplianceRegistry compliance;
        FTHG fthg;
        FTHStakeReceipt stakeReceipt;
        StakeLocker stakeLocker;
        DistributionManager distributionManager;
        RedemptionDesk redemptionDesk;
        OracleStub oracle;
        OffchainStakeOrchestrator orchestrator;
    }

    function run() external {
        // Get deployment parameters from environment or use defaults
        address admin = vm.envOr("ADMIN", msg.sender);
        address usdt = vm.envOr("USDT_ADDRESS", address(0));
        
        // If no USDT address provided, we'll need to deploy a mock (for testing)
        bool deployMockUSDT = usdt == address(0);
        
        vm.startBroadcast();

        DeploymentAddresses memory deployed;
        deployed.admin = admin;

        console.log("=== FTH-G Gold System Deployment ===");
        console.log("Admin:", admin);
        console.log("Deployer:", msg.sender);

        // Deploy mock USDT if needed (testnet only)
        if (deployMockUSDT) {
            console.log("Deploying Mock USDT...");
            MockUSDT mockUSDT = new MockUSDT();
            deployed.usdt = address(mockUSDT);
            console.log("Mock USDT deployed at:", deployed.usdt);
        } else {
            deployed.usdt = usdt;
            console.log("Using USDT at:", deployed.usdt);
        }

        // Deploy core compliance contracts
        console.log("Deploying KYC Soulbound...");
        deployed.kyc = new KYCSoulbound(admin);
        console.log("KYCSoulbound deployed at:", address(deployed.kyc));

        console.log("Deploying Compliance Registry...");
        deployed.compliance = new ComplianceRegistry(admin);
        console.log("ComplianceRegistry deployed at:", address(deployed.compliance));

        // Deploy oracle (use mock for now, replace with Chainlink in production)
        console.log("Deploying Oracle...");
        deployed.oracle = new OracleStub();
        console.log("Oracle deployed at:", address(deployed.oracle));

        // Deploy token contracts
        console.log("Deploying FTH-G Token...");
        deployed.fthg = new FTHG();
        console.log("FTHG deployed at:", address(deployed.fthg));

        console.log("Deploying Stake Receipt...");
        deployed.stakeReceipt = new FTHStakeReceipt(admin);
        console.log("FTHStakeReceipt deployed at:", address(deployed.stakeReceipt));

        // Deploy main system contracts
        console.log("Deploying Stake Locker...");
        deployed.stakeLocker = new StakeLocker(
            IERC20(deployed.usdt),
            deployed.stakeReceipt,
            deployed.fthg,
            deployed.oracle,
            deployed.kyc,
            deployed.compliance
        );
        console.log("StakeLocker deployed at:", address(deployed.stakeLocker));

        console.log("Deploying Distribution Manager...");
        deployed.distributionManager = new DistributionManager(
            IERC20(deployed.usdt),
            deployed.fthg,
            deployed.oracle
        );
        console.log("DistributionManager deployed at:", address(deployed.distributionManager));

        console.log("Deploying Redemption Desk...");
        deployed.redemptionDesk = new RedemptionDesk(
            IERC20(deployed.usdt),
            deployed.fthg,
            deployed.oracle
        );
        console.log("RedemptionDesk deployed at:", address(deployed.redemptionDesk));

        console.log("Deploying Offchain Stake Orchestrator...");
        deployed.orchestrator = new OffchainStakeOrchestrator(
            admin,
            deployed.stakeLocker,
            IERC20(deployed.usdt)
        );
        console.log("OffchainStakeOrchestrator deployed at:", address(deployed.orchestrator));

        // Setup roles and permissions
        console.log("Setting up roles and permissions...");
        
        // FTHG roles
        deployed.fthg.grantRole(deployed.fthg.MINTER_ROLE(), address(deployed.stakeLocker));
        deployed.fthg.grantRole(deployed.fthg.BURNER_ROLE(), address(deployed.redemptionDesk));
        
        // StakeReceipt roles  
        deployed.stakeReceipt.grantRole(deployed.stakeReceipt.ISSUER_ROLE(), address(deployed.stakeLocker));
        
        // DistributionManager roles
        deployed.distributionManager.grantRole(deployed.distributionManager.FUNDER_ROLE(), admin);

        // Set initial parameters
        console.log("Setting initial parameters...");
        
        // Set redemption budget (example: $100k daily)
        deployed.redemptionDesk.setDailyBudget(100_000e6);
        
        console.log("=== Deployment Complete ===");
        console.log("");
        console.log("Contract Addresses:");
        console.log("USDT:", deployed.usdt);
        console.log("KYCSoulbound:", address(deployed.kyc));
        console.log("ComplianceRegistry:", address(deployed.compliance));
        console.log("FTHG:", address(deployed.fthg));
        console.log("FTHStakeReceipt:", address(deployed.stakeReceipt));
        console.log("StakeLocker:", address(deployed.stakeLocker));
        console.log("DistributionManager:", address(deployed.distributionManager));
        console.log("RedemptionDesk:", address(deployed.redemptionDesk));
        console.log("Oracle:", address(deployed.oracle));
        console.log("OffchainStakeOrchestrator:", address(deployed.orchestrator));
        
        console.log("");
        console.log("Next Steps:");
        console.log("1. Configure oracle feeds (replace OracleStub with Chainlink)");
        console.log("2. Set up compliance jurisdictions and KYC processes");
        console.log("3. Fund DistributionManager and RedemptionDesk");
        console.log("4. Configure monitoring and alerts");
        console.log("5. Set up multi-signature governance");

        vm.stopBroadcast();
    }
}

// Mock USDT for testing
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SmartTokens.sol";

contract DeploySmartTokens is Script {
    SmartTokens public smartTokens;
    
    // Default deployment parameters
    address public treasury;
    uint256 public icoStartTime;
    uint256 public icoEndTime;
    
    function setUp() public {
        // Load environment variables or set defaults
        treasury = vm.envOr("TREASURY_ADDRESS", address(0x1234567890123456789012345678901234567890));
        icoStartTime = vm.envOr("ICO_START_TIME", block.timestamp + 1 days);
        icoEndTime = vm.envOr("ICO_END_TIME", block.timestamp + 90 days);
        
        // Validate parameters
        require(treasury != address(0), "Treasury address cannot be zero");
        require(icoStartTime > block.timestamp, "ICO start time must be in the future");
        require(icoEndTime > icoStartTime, "ICO end time must be after start time");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying SmartTokens ICO contract...");
        console.log("Deployer:", deployer);
        console.log("Treasury:", treasury);
        console.log("ICO Start Time:", icoStartTime);
        console.log("ICO End Time:", icoEndTime);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SmartTokens contract
        smartTokens = new SmartTokens(
            treasury,
            icoStartTime,
            icoEndTime
        );
        
        console.log("SmartTokens deployed at:", address(smartTokens));
        
        // Setup initial phases
        _setupInitialPhases();
        
        // Log deployment details
        _logDeploymentDetails();
        
        vm.stopBroadcast();
        
        // Save deployment info
        _saveDeploymentInfo();
    }
    
    function _setupInitialPhases() internal {
        console.log("Setting up initial ICO phases...");
        
        // Phase 1: Private Sale (30% discount)
        smartTokens.createPhase(
            1,
            icoStartTime,
            icoStartTime + 14 days,
            0.0007 ether, // 30% discount from base price
            100000000 * 10**18, // 100M tokens
            1000000 * 10**18, // 1M tokens per individual
            true // Requires whitelist
        );
        
        // Phase 2: Pre-Sale (20% discount)
        smartTokens.createPhase(
            2,
            icoStartTime + 14 days,
            icoStartTime + 44 days,
            0.0008 ether, // 20% discount
            150000000 * 10**18, // 150M tokens
            500000 * 10**18, // 500K tokens per individual
            false // No whitelist required
        );
        
        // Phase 3: Public Sale (base price)
        smartTokens.createPhase(
            3,
            icoStartTime + 44 days,
            icoEndTime,
            0.001 ether, // Base price
            150000000 * 10**18, // 150M tokens
            100000 * 10**18, // 100K tokens per individual
            false // No whitelist required
        );
        
        // Set current phase to 1
        smartTokens.setCurrentPhase(1);
        
        console.log("Initial phases configured successfully");
    }
    
    function _logDeploymentDetails() internal view {
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Contract Address:", address(smartTokens));
        console.log("Token Name:", smartTokens.name());
        console.log("Token Symbol:", smartTokens.symbol());
        console.log("Total Supply:", smartTokens.TOTAL_SUPPLY() / 10**18, "tokens");
        console.log("ICO Supply:", smartTokens.ICO_SUPPLY() / 10**18, "tokens");
        console.log("Current Phase:", smartTokens.currentPhase());
        console.log("Treasury Address:", smartTokens.treasury());
        console.log("Owner:", smartTokens.owner());
        console.log("==========================\n");
    }
    
    function _saveDeploymentInfo() internal {
        string memory deploymentInfo = string.concat(
            "SmartTokens ICO Deployment\n",
            "Contract Address: ", vm.toString(address(smartTokens)), "\n",
            "Network: Sepolia Testnet\n",
            "Deployer: ", vm.toString(msg.sender), "\n",
            "Treasury: ", vm.toString(treasury), "\n",
            "ICO Start: ", vm.toString(icoStartTime), "\n",
            "ICO End: ", vm.toString(icoEndTime), "\n"
        );
        
        // vm.writeFile("deployment-info.txt", deploymentInfo);
        console.log("Deployment info saved to deployment-info.txt");
    }
}

// Deployment configuration helper
contract DeploymentConfig is Script {
    struct Config {
        address treasury;
        uint256 icoStartTime;
        uint256 icoEndTime;
        uint256 privatePhasePrice;
        uint256 preSalePhasePrice;
        uint256 publicPhasePrice;
    }
    
    function getConfig() public view returns (Config memory) {
        uint256 chainId = block.chainid;
        
        if (chainId == 11155111) { // Sepolia
            return Config({
                treasury: 0x1234567890123456789012345678901234567890, // Replace with actual treasury
                icoStartTime: block.timestamp + 1 hours,
                icoEndTime: block.timestamp + 30 days,
                privatePhasePrice: 0.0007 ether,
                preSalePhasePrice: 0.0008 ether,
                publicPhasePrice: 0.001 ether
            });
        } else if (chainId == 1) { // Mainnet
            return Config({
                treasury: address(0), // Set mainnet treasury
                icoStartTime: 1704067200, // Set actual start time
                icoEndTime: 1735689600, // Set actual end time
                privatePhasePrice: 0.0007 ether,
                preSalePhasePrice: 0.0008 ether,
                publicPhasePrice: 0.001 ether
            });
        } else {
            revert("Unsupported network");
        }
    }
}
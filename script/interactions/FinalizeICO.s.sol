// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/SmartTokens.sol";

contract FinalizeICO is Script {
    
    function finalizeICO() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        console.log("Finalizing ICO...");
        console.log("Smart Tokens Address:", smartTokensAddress);
        
        // Check current status
        uint256 totalRaised = token.totalRaised();
        uint256 contractBalance = address(token).balance;
        uint256 remainingTokens = token.balanceOf(address(token));
        bool isFinalized = token.icoFinalized();
        uint256 icoEndTime = token.icoEndTime();
        
        console.log("Current Status:");
        console.log("- Total Raised:", totalRaised / 1e18, "ETH");
        console.log("- Contract ETH Balance:", contractBalance / 1e18, "ETH");
        console.log("- Remaining Tokens:", remainingTokens / 1e18, "SMART");
        console.log("- ICO End Time:", icoEndTime);
        console.log("- Current Time:", block.timestamp);
        console.log("- Already Finalized:", isFinalized);
        
        if (block.timestamp <= icoEndTime) {
            console.log("WARNING: ICO has not ended yet!");
            console.log("ICO ends at:", icoEndTime);
            console.log("Current time:", block.timestamp);
            return;
        }
        
        if (isFinalized) {
            console.log("ICO is already finalized!");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Finalize the ICO
        token.finalizeICO();
        
        console.log("ICO finalized successfully!");
        console.log("Remaining tokens burned:", remainingTokens / 1e18, "SMART");
        
        vm.stopBroadcast();
    }
    
    function withdrawFunds() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        uint256 contractBalance = address(token).balance;
        address treasury = token.treasury();
        uint256 treasuryBalanceBefore = treasury.balance;
        
        console.log("Withdrawing funds to treasury...");
        console.log("Contract Balance:", contractBalance / 1e18, "ETH");
        console.log("Treasury Address:", treasury);
        console.log("Treasury Balance Before:", treasuryBalanceBefore / 1e18, "ETH");
        
        if (contractBalance == 0) {
            console.log("No funds to withdraw!");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        token.emergencyWithdraw();
        
        vm.stopBroadcast();
        
        uint256 treasuryBalanceAfter = treasury.balance;
        console.log("Treasury Balance After:", treasuryBalanceAfter / 1e18, "ETH");
        console.log("Funds withdrawn successfully!");
    }
    
    function createVestingSchedules() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        console.log("Creating vesting schedules for team...");
        
        // Team vesting schedules
        address[] memory teamMembers = new address[](4);
        teamMembers[0] = 0x1111111111111111111111111111111111111111; // CEO
        teamMembers[1] = 0x2222222222222222222222222222222222222222; // CTO
        teamMembers[2] = 0x3333333333333333333333333333333333333333; // COO
        teamMembers[3] = 0x4444444444444444444444444444444444444444; // CMO
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 50_000_000 * 10**18; // CEO - 50M tokens
        amounts[1] = 40_000_000 * 10**18; // CTO - 40M tokens
        amounts[2] = 30_000_000 * 10**18; // COO - 30M tokens
        amounts[3] = 20_000_000 * 10**18; // CMO - 20M tokens
        
        string[] memory roles = new string[](4);
        roles[0] = "CEO";
        roles[1] = "CTO";
        roles[2] = "COO";
        roles[3] = "CMO";
        
        uint256 vestingStart = block.timestamp + 30 days; // Start vesting 30 days after ICO
        uint256 vestingDuration = 4 * 365 days; // 4 years vesting
        uint256 cliffDuration = 365 days; // 1 year cliff
        
        vm.startBroadcast(deployerPrivateKey);
        
        for (uint i = 0; i < teamMembers.length; i++) {
            token.createVestingSchedule(
                teamMembers[i],
                amounts[i],
                vestingStart,
                vestingDuration,
                cliffDuration
            );
            
            console.log("Created vesting for", roles[i], ":", vm.toString(teamMembers[i]));
            console.log("- Amount:", amounts[i] / 1e18, "SMART tokens");
        }
        
        vm.stopBroadcast();
        
        console.log("All vesting schedules created!");
        console.log("Vesting Details:");
        console.log("- Start Time:", vestingStart);
        console.log("- Duration:", vestingDuration / 365 days, "years");
        console.log("- Cliff Duration:", cliffDuration / 365 days, "year");
    }
    
    function getICOSummary() external view {
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        console.log("=== ICO SUMMARY ===");
        console.log("Contract Address:", smartTokensAddress);
        console.log("Token Name:", token.name());
        console.log("Token Symbol:", token.symbol());
        console.log("Total Supply:", token.totalSupply() / 1e18, "tokens");
        console.log("ICO Supply:", token.ICO_SUPPLY() / 1e18, "tokens");
        console.log("Total Raised:", token.totalRaised() / 1e18, "ETH");
        console.log("Current Phase:", token.currentPhase());
        console.log("ICO Start:", token.icoStartTime());
        console.log("ICO End:", token.icoEndTime());
        console.log("ICO Finalized:", token.icoFinalized());
        console.log("Owner:", token.owner());
        console.log("Treasury:", token.treasury());
        console.log("Contract ETH Balance:", address(token).balance / 1e18, "ETH");
        console.log("Remaining ICO Tokens:", token.balanceOf(address(token)) / 1e18, "tokens");
        console.log("==================");
    }
    
    function emergencyPause() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        console.log("EMERGENCY: Pausing the contract...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        token.pause();
        
        vm.stopBroadcast();
        
        console.log("Contract paused successfully!");
    }
    
    function emergencyUnpause() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        console.log("Unpausing the contract...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        token.unpause();
        
        vm.stopBroadcast();
        
        console.log("Contract unpaused successfully!");
    }
}
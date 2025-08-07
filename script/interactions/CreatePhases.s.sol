// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/SmartTokens.sol";

contract CreatePhases is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        console.log("Creating additional ICO phases...");
        console.log("Smart Tokens Address:", smartTokensAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get ICO timeline
        uint256 icoStart = token.icoStartTime();
        uint256 icoEnd = token.icoEndTime();
        
        console.log("ICO Start Time:", icoStart);
        console.log("ICO End Time:", icoEnd);
        
        // Phase 1: Early Bird (First 7 days, 40% discount)
        token.createPhase(
            1,
            icoStart,
            icoStart + 7 days,
            0.0006 ether, // 40% discount
            50_000_000 * 10**18, // 50M tokens
            2_000_000 * 10**18, // 2M individual cap
            true // Requires whitelist
        );
        console.log("Created Phase 1: Early Bird");
        
        // Phase 2: Private Sale (Days 7-21, 30% discount)
        token.createPhase(
            2,
            icoStart + 7 days,
            icoStart + 21 days,
            0.0007 ether, // 30% discount
            100_000_000 * 10**18, // 100M tokens
            1_000_000 * 10**18, // 1M individual cap
            true // Requires whitelist
        );
        console.log("Created Phase 2: Private Sale");
        
        // Phase 3: Pre-Sale (Days 21-45, 20% discount)
        token.createPhase(
            3,
            icoStart + 21 days,
            icoStart + 45 days,
            0.0008 ether, // 20% discount
            150_000_000 * 10**18, // 150M tokens
            500_000 * 10**18, // 500K individual cap
            false // No whitelist required
        );
        console.log("Created Phase 3: Pre-Sale");
        
        // Phase 4: Public Sale (Days 45-end, base price)
        token.createPhase(
            4,
            icoStart + 45 days,
            icoEnd,
            0.001 ether, // Base price
            100_000_000 * 10**18, // 100M tokens
            100_000 * 10**18, // 100K individual cap
            false // No whitelist required
        );
        console.log("Created Phase 4: Public Sale");
        
        // Set initial phase
        token.setCurrentPhase(1);
        console.log("Set current phase to 1");
        
        vm.stopBroadcast();
        
        console.log("All phases created successfully!");
    }
    
    function updatePhasePrice(uint256 phaseId, uint256 newPrice) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        token.updatePhase(phaseId, newPrice, 0, 0, true);
        console.log("Updated phase", phaseId, "price to", newPrice);
        
        vm.stopBroadcast();
    }
}
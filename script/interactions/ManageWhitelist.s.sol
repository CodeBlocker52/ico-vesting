// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/SmartTokens.sol";

contract ManageWhitelist is Script {
    
    function addToWhitelist() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        // Define addresses to whitelist
        address[] memory whitelistAddresses = new address[](5);
        whitelistAddresses[0] = 0x1234567890123456789012345678901234567890;
        whitelistAddresses[1] = 0x2345678901234567890123456789012345678901;
        whitelistAddresses[2] = 0x3456789012345678901234567890123456789012;
        whitelistAddresses[3] = 0x4567890123456789012345678901234567890123;
        whitelistAddresses[4] = 0x5678901234567890123456789012345678901234;
        
        console.log("Adding addresses to whitelist...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        token.updateWhitelist(whitelistAddresses, true);
        
        vm.stopBroadcast();
        
        // Verify addresses are whitelisted
        for (uint i = 0; i < whitelistAddresses.length; i++) {
            bool isWhitelisted = token.isWhitelisted(whitelistAddresses[i]);
            console.log("Address", vm.toString(whitelistAddresses[i]), "whitelisted:", isWhitelisted);
        }
        
        console.log("Whitelist update completed!");
    }
    
    function removeFromWhitelist() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        // Define addresses to remove from whitelist
        address[] memory removeAddresses = new address[](2);
        removeAddresses[0] = 0x1234567890123456789012345678901234567890;
        removeAddresses[1] = 0x2345678901234567890123456789012345678901;
        
        console.log("Removing addresses from whitelist...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        token.updateWhitelist(removeAddresses, false);
        
        vm.stopBroadcast();
        
        // Verify addresses are removed
        for (uint i = 0; i < removeAddresses.length; i++) {
            bool isWhitelisted = token.isWhitelisted(removeAddresses[i]);
            console.log("Address", vm.toString(removeAddresses[i]), "whitelisted:", isWhitelisted);
        }
        
        console.log("Whitelist removal completed!");
    }
    
    function addBulkWhitelist() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        console.log("Adding bulk addresses to whitelist...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Add in batches to avoid gas limits
        address[] memory batch1 = new address[](50);
        for (uint i = 0; i < 50; i++) {
            batch1[i] = address(uint160(10000 + i));
        }
        token.updateWhitelist(batch1, true);
        console.log("Added batch 1 (50 addresses)");
        
        address[] memory batch2 = new address[](50);
        for (uint i = 0; i < 50; i++) {
            batch2[i] = address(uint160(10050 + i));
        }
        token.updateWhitelist(batch2, true);
        console.log("Added batch 2 (50 addresses)");
        
        vm.stopBroadcast();
        
        console.log("Bulk whitelist addition completed!");
    }
    
    function manageBlacklist() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        // Define addresses to blacklist (suspicious addresses)
        address[] memory blacklistAddresses = new address[](3);
        blacklistAddresses[0] = address(0x00BADBADBADBADBADBADBADBADBADBADBADBAD);
        blacklistAddresses[1] = address(0x00DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF);
        blacklistAddresses[2] = address(0x0000000000000000000000000000000000000001);
        
        console.log("Adding addresses to blacklist...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        token.updateBlacklist(blacklistAddresses, true);
        
        vm.stopBroadcast();
        
        // Verify addresses are blacklisted
        for (uint i = 0; i < blacklistAddresses.length; i++) {
            bool isBlacklisted = token.isBlacklisted(blacklistAddresses[i]);
            console.log("Address", vm.toString(blacklistAddresses[i]), "blacklisted:", isBlacklisted);
        }
        
        console.log("Blacklist update completed!");
    }
    
    function checkWhitelistStatus(address userAddress) external view {
        address payable smartTokensAddress = payable(vm.envAddress("SMART_TOKENS_ADDRESS"));
        SmartTokens token = SmartTokens(smartTokensAddress);
        
        bool isWhitelisted = token.isWhitelisted(userAddress);
        bool isBlacklisted = token.isBlacklisted(userAddress);
        
        console.log("Address:", vm.toString(userAddress));
        console.log("Whitelisted:", isWhitelisted);
        console.log("Blacklisted:", isBlacklisted);
    }
}
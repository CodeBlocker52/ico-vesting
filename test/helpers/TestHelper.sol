// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../src/SmartTokens.sol";

contract TestHelper is Test {
    SmartTokens public token;
    
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public user3 = address(0x5);
    
    uint256 public icoStartTime;
    uint256 public icoEndTime;
    
    // Events for testing
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 price, uint256 phase);
    event PhaseCreated(uint256 indexed phaseId, uint256 startTime, uint256 endTime, uint256 price);
    event WhitelistUpdated(address indexed user, bool status);
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
    
    function deployToken() internal {
        icoStartTime = block.timestamp + 1 days;
        icoEndTime = block.timestamp + 90 days;
        
        vm.prank(owner);
        token = new SmartTokens(treasury, icoStartTime, icoEndTime);
        
        // Fund test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
    }
    
    function setupPhases() internal {
        vm.startPrank(owner);
        
        // Phase 1: Private Sale (whitelisted)
        token.createPhase(
            1,
            icoStartTime,
            icoStartTime + 14 days,
            0.0005 ether, // Lower price for private sale
            100_000_000 * 10**18, // 100M tokens
            1_000_000 * 10**18, // 1M cap per individual
            true // Requires whitelist
        );
        
        // Phase 2: Public Sale
        token.createPhase(
            2,
            icoStartTime + 14 days,
            icoEndTime,
            0.001 ether, // Regular price
            300_000_000 * 10**18, // 300M tokens
            100_000 * 10**18, // 100K cap per individual
            false // No whitelist required
        );
        
        vm.stopPrank();
    }
    
    function addToWhitelist(address user) internal {
        address[] memory users = new address[](1);
        users[0] = user;
        
        vm.prank(owner);
        token.updateWhitelist(users, true);
    }
    
    function addMultipleToWhitelist(address[] memory users) internal {
        vm.prank(owner);
        token.updateWhitelist(users, true);
    }
    
    function startICO() internal {
        vm.warp(icoStartTime);
    }
    
    function moveToPhase(uint256 phaseId) internal {
        vm.prank(owner);
        token.setCurrentPhase(phaseId);
        
        if (phaseId == 1) {
            vm.warp(icoStartTime);
        } else if (phaseId == 2) {
            vm.warp(icoStartTime + 14 days);
        }
    }
    
    function endICO() internal {
        vm.warp(icoEndTime + 1);
    }
    
    function buyTokensAs(address buyer, uint256 ethAmount) internal returns (uint256 tokenAmount) {
        uint256 balanceBefore = token.balanceOf(buyer);
        
        vm.prank(buyer);
        token.buyTokens{value: ethAmount}();
        
        uint256 balanceAfter = token.balanceOf(buyer);
        tokenAmount = balanceAfter - balanceBefore;
    }
    
    function expectRevertWithError(bytes4 selector) internal {
        vm.expectRevert(selector);
    }
    
    // Helper to calculate expected token amount
    function calculateTokenAmount(uint256 ethAmount, uint256 price) internal pure returns (uint256) {
        return (ethAmount * 10**18) / price;
    }
    
    // Helper to get current phase info
    function getCurrentPhaseInfo() internal view returns (
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        uint256 tokensAvailable,
        uint256 tokensSold,
        uint256 individualCap,
        bool requiresWhitelist,
        bool isActive
    ) {
        return token.getCurrentPhaseInfo();
    }
    
    // Assertion helpers
    function assertTokenBalance(address account, uint256 expectedBalance, string memory message) internal view {
        assertEq(token.balanceOf(account), expectedBalance, message);
    }
    
    function assertEthBalance(address account, uint256 expectedBalance, string memory message) internal view{
        assertEq(account.balance, expectedBalance, message);
    }
    
    function assertPhaseTokensSold(uint256 phaseId, uint256 expectedSold, string memory message) internal view  {
        (, , , , uint256 tokensSold, , , ) = token.getCurrentPhaseInfo();
        if (token.currentPhase() == phaseId) {
            assertEq(tokensSold, expectedSold, message);
        }
    }
}
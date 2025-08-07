// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/SmartTokens.sol";
import "./helpers/TestHelper.sol";

contract SmartTokensIntegrationTest is TestHelper {
    
    function setUp() public {
        deployToken();
        setupPhases();
    }
    
    // ============ FULL ICO LIFECYCLE TESTS ============
    
    function testFullICOLifecycle() public {
        // Setup: Add users to whitelist for private phase
        address[] memory whitelistUsers = new address[](2);
        whitelistUsers[0] = user1;
        whitelistUsers[1] = user2;
        addMultipleToWhitelist(whitelistUsers);
        
        // Phase 1: Private Sale
        moveToPhase(1);
        
        uint256 user1PrivateTokens = buyTokensAs(user1, 2 ether);
        uint256 user2PrivateTokens = buyTokensAs(user2, 1 ether);
        
        assertGt(user1PrivateTokens, 0, "User1 should receive private tokens");
        assertGt(user2PrivateTokens, 0, "User2 should receive private tokens");
        
        // Track total raised in private phase
        uint256 privatePhaseRaised = 3 ether;
        assertEq(token.totalRaised(), privatePhaseRaised);
        
        // Phase 2: Public Sale
        moveToPhase(2);
        
        uint256 user1PublicTokens = buyTokensAs(user1, 1 ether);
        uint256 user2PublicTokens = buyTokensAs(user2, 1 ether);
        uint256 user3PublicTokens = buyTokensAs(user3, 2 ether); // user3 not whitelisted but can buy in public phase
        
        // Verify total raised
        uint256 totalExpectedRaised = privatePhaseRaised + 4 ether;
        assertEq(token.totalRaised(), totalExpectedRaised);
        
        // Verify individual balances
        assertEq(token.balanceOf(user1), user1PrivateTokens + user1PublicTokens);
        assertEq(token.balanceOf(user2), user2PrivateTokens + user2PublicTokens);
        assertEq(token.balanceOf(user3), user3PublicTokens);
        
        // End ICO and finalize
        endICO();
        
        vm.prank(owner);
        token.finalizeICO();
        
        assertTrue(token.icoFinalized());
        
        // Withdraw funds to treasury
        uint256 contractBalance = address(token).balance;
        uint256 treasuryBalanceBefore = treasury.balance;
        
        vm.prank(owner);
        token.emergencyWithdraw();
        
        assertEq(treasury.balance, treasuryBalanceBefore + contractBalance);
    }
    
    function testComplexVestingScenario() public {
        // Create vesting schedules for multiple beneficiaries
        uint256 amount1 = 1_000_000 * 10**18;
        uint256 amount2 = 2_000_000 * 10**18;
        uint256 startTime = block.timestamp + 30 days;
        uint256 duration = 365 days;
        uint256 cliff = 90 days;
        
        vm.startPrank(owner);
        token.createVestingSchedule(user1, amount1, startTime, duration, cliff);
        token.createVestingSchedule(user2, amount2, startTime, duration, cliff);
        vm.stopPrank();
        
        // Fast forward past cliff (120 days)
        vm.warp(startTime + 120 days);
        
        // Calculate expected vested amounts (120/365 of total)
        uint256 expectedVested1 = (amount1 * 120) / 365;
        uint256 expectedVested2 = (amount2 * 120) / 365;
        
        assertEq(token.getVestedAmount(user1), expectedVested1);
        assertEq(token.getVestedAmount(user2), expectedVested2);
        
        // Release vested tokens
        uint256 user1BalanceBefore = token.balanceOf(user1);
        uint256 user2BalanceBefore = token.balanceOf(user2);
        
        vm.prank(user1);
        token.releaseVestedTokens();
        
        vm.prank(user2);
        token.releaseVestedTokens();
        
        assertEq(token.balanceOf(user1), user1BalanceBefore + expectedVested1);
        assertEq(token.balanceOf(user2), user2BalanceBefore + expectedVested2);
        
        // Fast forward to full vesting
        vm.warp(startTime + duration + 1);
        
        // Release remaining tokens
        uint256 remainingVested1 = token.getReleasableAmount(user1);
        uint256 remainingVested2 = token.getReleasableAmount(user2);
        
        vm.prank(user1);
        token.releaseVestedTokens();
        
        vm.prank(user2);
        token.releaseVestedTokens();
        
        // Verify full amounts are released
        assertEq(token.balanceOf(user1), user1BalanceBefore + amount1);
        assertEq(token.balanceOf(user2), user2BalanceBefore + amount2);
    }
    
    function testMultiPhaseWithDifferentPrices() public {
        // Create additional phases with different prices
        vm.startPrank(owner);
        
        // Phase 3: Bonus phase (even lower price)
        token.createPhase(
            3,
            icoStartTime + 60 days,
            icoStartTime + 75 days,
            0.0003 ether, // Super low price for bonus
            50_000_000 * 10**18,
            2_000_000 * 10**18,
            true // Requires whitelist
        );
        
        // Phase 4: Final phase (highest price)
        token.createPhase(
            4,
            icoStartTime + 75 days,
            icoEndTime,
            0.0015 ether, // Highest price
            100_000_000 * 10**18,
            50_000 * 10**18,
            false
        );
        
        vm.stopPrank();
        
        addToWhitelist(user1);
        
        // Buy in each phase and track token amounts
        uint256[] memory tokensBought = new uint256[](4);
        
        // Phase 1
        moveToPhase(1);
        tokensBought[0] = buyTokensAs(user1, 1 ether);
        
        // Phase 2
        moveToPhase(2);
        tokensBought[1] = buyTokensAs(user1, 1 ether);
        
        // Phase 3
        vm.prank(owner);
        token.setCurrentPhase(3);
        vm.warp(icoStartTime + 60 days);
        tokensBought[2] = buyTokensAs(user1, 1 ether);
        
        // Phase 4
        vm.prank(owner);
        token.setCurrentPhase(4);
        vm.warp(icoStartTime + 75 days);
        tokensBought[3] = buyTokensAs(user1, 1 ether);
        
        // Verify different amounts due to different prices
        // Phase 3 should give most tokens (lowest price)
        // Phase 4 should give least tokens (highest price)
        assertGt(tokensBought[2], tokensBought[0]); // Phase 3 > Phase 1
        assertGt(tokensBought[0], tokensBought[1]); // Phase 1 > Phase 2
        assertGt(tokensBought[1], tokensBought[3]); // Phase 2 > Phase 4
        
        // Verify total purchase history
        SmartTokens.Purchase[] memory purchases = token.getUserPurchases(user1);
        assertEq(purchases.length, 4);
        
        uint256 totalTokens = tokensBought[0] + tokensBought[1] + tokensBought[2] + tokensBought[3];
        assertEq(token.balanceOf(user1), totalTokens);
    }
    
    function testLargeScaleICOWithManyUsers() public {
        moveToPhase(2); // Public phase
        
        // Create multiple users
        address[] memory users = new address[](10);
        for (uint i = 0; i < 10; i++) {
            users[i] = address(uint160(1000 + i));
            vm.deal(users[i], 10 ether);
        }
        
        uint256 totalTokensBought = 0;
        uint256 totalEthSpent = 0;
        
        // Each user buys different amounts
        for (uint i = 0; i < 10; i++) {
            uint256 ethAmount = (i + 1) * 0.5 ether; // 0.5, 1.0, 1.5, ... 5.0 ETH
            uint256 tokensBought = buyTokensAs(users[i], ethAmount);
            
            totalTokensBought += tokensBought;
            totalEthSpent += ethAmount;
            
            assertEq(token.userTotalPurchased(users[i]), tokensBought);
        }
        
        assertEq(token.totalRaised(), totalEthSpent);
        
        // Verify phase tokens sold
        (, , , , uint256 tokensSold, , , ) = getCurrentPhaseInfo();
        assertEq(tokensSold, totalTokensBought);
    }
    
    function testEmergencyScenarios() public {
        moveToPhase(2);
        
        // Normal operation
        buyTokensAs(user1, 2 ether);
        
        // Emergency: Pause the contract
        vm.prank(owner);
        token.pause();
        
        // Should not be able to buy when paused
        vm.expectRevert();
        buyTokensAs(user2, 1 ether);
        
        // Admin can still withdraw funds during pause
        vm.prank(owner);
        token.emergencyWithdraw();
        
        assertEq(address(token).balance, 0);
        
        // Unpause and continue
        vm.prank(owner);
        token.unpause();
        
        // Should work again
        buyTokensAs(user2, 1 ether);
        
        // Test blacklisting
        address[] memory blacklistUsers = new address[](1);
        blacklistUsers[0] = user1;
        
        vm.prank(owner);
        token.updateBlacklist(blacklistUsers, true);
        
        // Blacklisted user cannot buy
        vm.expectRevert("Address is blacklisted");
        buyTokensAs(user1, 1 ether);
        
        // But can still transfer existing tokens
        vm.prank(user1);
        token.transfer(user3, 100 * 10**18);
    }
    
    function testTokenDistribution() public {
        // Verify initial token distribution
        uint256 totalSupply = token.totalSupply();
        uint256 icoSupply = token.ICO_SUPPLY();
        uint256 teamSupply = token.TEAM_SUPPLY();
        uint256 reserveSupply = token.RESERVE_SUPPLY();
        
        assertEq(totalSupply, 1_000_000_000 * 10**18);
        assertEq(icoSupply, 400_000_000 * 10**18);
        assertEq(teamSupply, 200_000_000 * 10**18);
        assertEq(reserveSupply, 400_000_000 * 10**18);
        assertEq(icoSupply + teamSupply + reserveSupply, totalSupply);
        
        // ICO tokens are in contract
        assertEq(token.balanceOf(address(token)), icoSupply);
        
        // Team + Reserve tokens are with owner initially
        assertEq(token.balanceOf(owner), teamSupply + reserveSupply);
        
        // After ICO, remaining tokens should be burned
        moveToPhase(2);
        buyTokensAs(user1, 1 ether); // Buy some tokens
        
        endICO();
        
        uint256 remainingBeforeFinalize = token.balanceOf(address(token));
        
        vm.prank(owner);
        token.finalizeICO();
        
        // Remaining tokens should be burned
        assertEq(token.balanceOf(address(token)), 0);
        assertEq(token.totalSupply(), totalSupply - remainingBeforeFinalize);
    }
    
    function testPurchaseTracking() public {
        moveToPhase(2);
        
        // Make multiple purchases
        buyTokensAs(user1, 1 ether);
        vm.warp(block.timestamp + 1 hours);
        buyTokensAs(user1, 0.5 ether);
        vm.warp(block.timestamp + 1 hours);
        buyTokensAs(user1, 2 ether);
        
        SmartTokens.Purchase[] memory purchases = token.getUserPurchases(user1);
        assertEq(purchases.length, 3);
        
        // Verify purchase details
        assertEq(purchases[0].price, 0.001 ether);
        assertEq(purchases[1].price, 0.001 ether);
        assertEq(purchases[2].price, 0.001 ether);
        assertEq(purchases[0].phase, 2);
        assertEq(purchases[1].phase, 2);
        assertEq(purchases[2].phase, 2);
        
        // Verify timestamps are different
        assertLt(purchases[0].timestamp, purchases[1].timestamp);
        assertLt(purchases[1].timestamp, purchases[2].timestamp);
        
        // Verify total purchased
        uint256 expectedTotal = purchases[0].amount + purchases[1].amount + purchases[2].amount;
        assertEq(token.userTotalPurchased(user1), expectedTotal);
        assertEq(token.balanceOf(user1), expectedTotal);
    }
    
    function testGasOptimization() public {
        moveToPhase(2);
        
        // Measure gas for different operations
        uint256 gasBefore;
        uint256 gasAfter;
        
        // Single purchase
        gasBefore = gasleft();
        buyTokensAs(user1, 1 ether);
        gasAfter = gasleft();
        uint256 buyGas = gasBefore - gasAfter;
        
        // Whitelist update
        gasBefore = gasleft();
        address[] memory users = new address[](1);
        users[0] = user2;
        vm.prank(owner);
        token.updateWhitelist(users, true);
        gasAfter = gasleft();
        uint256 whitelistGas = gasBefore - gasAfter;
        
        // Phase creation
        gasBefore = gasleft();
        vm.prank(owner);
        token.createPhase(99, block.timestamp + 1, block.timestamp + 2, 0.001 ether, 1000 * 10**18, 100 * 10**18, false);
        gasAfter = gasleft();
        uint256 phaseGas = gasBefore - gasAfter;
        
        console.log("Buy tokens gas:", buyGas);
        console.log("Whitelist update gas:", whitelistGas);
        console.log("Phase creation gas:", phaseGas);
        
        // These are just informational - actual optimization would require analysis
        assertTrue(buyGas > 0);
        assertTrue(whitelistGas > 0);
        assertTrue(phaseGas > 0);
    }
}
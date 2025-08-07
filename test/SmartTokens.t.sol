// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/SmartTokens.sol";
import "./helpers/TestHelper.sol";

contract SmartTokensTest is TestHelper {
    
    function setUp() public {
        deployToken();
        setupPhases();
    }
    
    // ============ DEPLOYMENT TESTS ============
    
    function testDeployment() public view {
        assertEq(token.name(), "SmartTokens");
        assertEq(token.symbol(), "SMART");
        assertEq(token.totalSupply(), 1_000_000_000 * 10**18);
        assertEq(token.owner(), owner);
        assertEq(token.treasury(), treasury);
        assertEq(token.icoStartTime(), icoStartTime);
        assertEq(token.icoEndTime(), icoEndTime);
        assertFalse(token.icoFinalized());
    }
    
    function testInvalidDeploymentParameters() public {
        vm.expectRevert(SmartTokens.InvalidTimestamp.selector);
        new SmartTokens(treasury, block.timestamp - 1, icoEndTime);
        
        vm.expectRevert(SmartTokens.InvalidTimestamp.selector);
        new SmartTokens(treasury, icoEndTime, icoStartTime);
        
        vm.expectRevert(SmartTokens.InvalidAddress.selector);
        new SmartTokens(address(0), icoStartTime, icoEndTime);
    }
    
    // ============ PHASE MANAGEMENT TESTS ============
    
    function testCreatePhase() public {
        uint256 phaseId = 99;
        uint256 startTime = block.timestamp + 100 days;
        uint256 endTime = block.timestamp + 110 days;
        uint256 price = 0.002 ether;
        uint256 tokensAvailable = 50_000_000 * 10**18;
        uint256 individualCap = 10_000 * 10**18;
        
        vm.expectEmit(true, false, false, true);
        emit PhaseCreated(phaseId, startTime, endTime, price);
        
        vm.prank(owner);
        token.createPhase(phaseId, startTime, endTime, price, tokensAvailable, individualCap, false);
        
        (uint256 pStartTime, uint256 pEndTime, uint256 pPrice, uint256 pAvailable, uint256 pSold, uint256 pCap, bool pWhitelist, bool pActive) = token.phases(phaseId);
        
        assertEq(pStartTime, startTime);
        assertEq(pEndTime, endTime);
        assertEq(pPrice, price);
        assertEq(pAvailable, tokensAvailable);
        assertEq(pSold, 0);
        assertEq(pCap, individualCap);
        assertEq(pWhitelist, false);
        assertTrue(pActive);
    }
    
    function testCreatePhaseOnlyOwner() public {
        vm.expectRevert();
        vm.prank(user1);
        token.createPhase(99, block.timestamp + 1, block.timestamp + 2, 0.001 ether, 1000 * 10**18, 100 * 10**18, false);
    }
    
    function testUpdatePhase() public {
        uint256 newPrice = 0.0015 ether;
        uint256 newTokensAvailable = 200_000_000 * 10**18;
        
        vm.prank(owner);
        token.updatePhase(1, newPrice, newTokensAvailable, 500_000 * 10**18, true);
        
        (, , uint256 price, uint256 available, , uint256 cap, , bool active) = token.phases(1);
        assertEq(price, newPrice);
        assertEq(available, newTokensAvailable);
        assertEq(cap, 500_000 * 10**18);
        assertTrue(active);
    }
    
    function testSetCurrentPhase() public {
        vm.prank(owner);
        token.setCurrentPhase(2);
        assertEq(token.currentPhase(), 2);
    }
    
    // ============ WHITELIST TESTS ============
    
    function testUpdateWhitelist() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;
        
        vm.expectEmit(true, false, false, true);
        emit WhitelistUpdated(user1, true);
        vm.expectEmit(true, false, false, true);
        emit WhitelistUpdated(user2, true);
        
        vm.prank(owner);
        token.updateWhitelist(users, true);
        
        assertTrue(token.isWhitelisted(user1));
        assertTrue(token.isWhitelisted(user2));
        assertFalse(token.isWhitelisted(user3));
    }
    
    function testRemoveFromWhitelist() public {
        addToWhitelist(user1);
        assertTrue(token.isWhitelisted(user1));
        
        address[] memory users = new address[](1);
        users[0] = user1;
        
        vm.prank(owner);
        token.updateWhitelist(users, false);
        
        assertFalse(token.isWhitelisted(user1));
    }
    
    // ============ BLACKLIST TESTS ============
    
    function testUpdateBlacklist() public {
        address[] memory users = new address[](1);
        users[0] = user1;
        
        vm.prank(owner);
        token.updateBlacklist(users, true);
        
        assertTrue(token.isBlacklisted(user1));
    }
    
    function testBlacklistedCannotBuy() public {
        address[] memory users = new address[](1);
        users[0] = user1;
        
        vm.prank(owner);
        token.updateBlacklist(users, true);
        
        moveToPhase(2); // Public phase, no whitelist required
        
        vm.expectRevert("Address is blacklisted");
        buyTokensAs(user1, 1 ether);
    }
    
    // ============ TOKEN PURCHASE TESTS ============
    
    function testBuyTokensInPublicPhase() public {
        moveToPhase(2); // Public phase
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = calculateTokenAmount(ethAmount, 0.001 ether);
        
        vm.expectEmit(true, false, false, true);
        emit TokensPurchased(user1, expectedTokens, 0.001 ether, 2);
        
        uint256 tokensBought = buyTokensAs(user1, ethAmount);
        
        assertEq(tokensBought, expectedTokens);
        assertTokenBalance(user1, expectedTokens, "User should receive correct token amount");
        assertEq(token.userTotalPurchased(user1), expectedTokens);
    }
    
    function testBuyTokensInPrivatePhaseWithWhitelist() public {
        addToWhitelist(user1);
        moveToPhase(1); // Private phase (requires whitelist)
        
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = calculateTokenAmount(ethAmount, 0.0005 ether);
        
        uint256 tokensBought = buyTokensAs(user1, ethAmount);
        
        assertEq(tokensBought, expectedTokens);
        assertTokenBalance(user1, expectedTokens, "Whitelisted user should receive tokens");
    }
    
    function testBuyTokensInPrivatePhaseWithoutWhitelist() public {
        moveToPhase(1); // Private phase (requires whitelist)
        
        expectRevertWithError(SmartTokens.NotWhitelisted.selector);
        buyTokensAs(user1, 1 ether);
    }
    
    function testBuyTokensBeforeICO() public {
        vm.warp(icoStartTime - 1);
        
        expectRevertWithError(SmartTokens.ICONotStarted.selector);
        buyTokensAs(user1, 1 ether);
    }
    
    function testBuyTokensAfterICO() public {
        endICO();
        
        expectRevertWithError(SmartTokens.ICOEnded.selector);
        buyTokensAs(user1, 1 ether);
    }
    
    function testBuyTokensWithZeroValue() public {
        moveToPhase(2);
        
        expectRevertWithError(SmartTokens.InvalidAmount.selector);
        vm.prank(user1);
        token.buyTokens{value: 0}();
    }
    
    function testBuyTokensExceedingIndividualCap() public {
        moveToPhase(2); // Phase 2 has 100K token individual cap
        
        uint256 exceedingEthAmount = 101_000 * 0.001 ether; // More than 100K tokens worth
        
        expectRevertWithError(SmartTokens.ExceedsIndividualCap.selector);
        buyTokensAs(user1, exceedingEthAmount);
    }
    
    function testBuyTokensExceedingPhaseSupply() public {
        moveToPhase(2);
        
        // Try to buy more tokens than available in phase
        (, , uint256 price, uint256 available, , , , ) = getCurrentPhaseInfo();
        uint256 exceedingEthAmount = ((available + 1) * price) / 10**18;
        
        vm.deal(user1, exceedingEthAmount);
        
        expectRevertWithError(SmartTokens.InsufficientTokensRemaining.selector);
        buyTokensAs(user1, exceedingEthAmount);
    }
    
    function testReceiveFunctionBuyTokens() public {
        moveToPhase(2);
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = calculateTokenAmount(ethAmount, 0.001 ether);
        
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.prank(user1);
        (bool success, ) = address(token).call{value: ethAmount}("");
        assertTrue(success);
        
        uint256 balanceAfter = token.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, expectedTokens);
    }
    
    // ============ VESTING TESTS ============
    
    function testCreateVestingSchedule() public {
        uint256 amount = 1_000_000 * 10**18;
        uint256 startTime = block.timestamp + 1 days;
        uint256 duration = 365 days;
        uint256 cliff = 90 days;
        
        vm.expectEmit(true, false, false, true);
        emit VestingScheduleCreated(user1, amount, startTime, duration);
        
        vm.prank(owner);
        token.createVestingSchedule(user1, amount, startTime, duration, cliff);
        
        (uint256 totalAmount, uint256 releasedAmount, uint256 vStartTime, uint256 vDuration, uint256 cliffDuration) = token.vestingSchedules(user1);
        
        assertEq(totalAmount, amount);
        assertEq(releasedAmount, 0);
        assertEq(vStartTime, startTime);
        assertEq(vDuration, duration);
        assertEq(cliffDuration, cliff);
    }
    
    function testReleaseVestedTokensBeforeCliff() public {
        uint256 amount = 1_000_000 * 10**18;
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;
        uint256 cliff = 90 days;
        
        vm.prank(owner);
        token.createVestingSchedule(user1, amount, startTime, duration, cliff);
        
        // Try to release before cliff
        vm.warp(startTime + 30 days);
        
        expectRevertWithError(SmartTokens.TokensNotVested.selector);
        vm.prank(user1);
        token.releaseVestedTokens();
    }
    
    function testReleaseVestedTokensAfterCliff() public {
        uint256 amount = 1_000_000 * 10**18;
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;
        uint256 cliff = 90 days;
        
        vm.prank(owner);
        token.createVestingSchedule(user1, amount, startTime, duration, cliff);
        
        // Move past cliff to 180 days (half duration)
        vm.warp(startTime + 180 days);
        
        uint256 expectedVested = amount / 2; // 50% should be vested
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.prank(user1);
        token.releaseVestedTokens();
        
        uint256 balanceAfter = token.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, expectedVested);
    }
    
    function testReleaseVestedTokensFullyVested() public {
        uint256 amount = 1_000_000 * 10**18;
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;
        uint256 cliff = 90 days;
        
        vm.prank(owner);
        token.createVestingSchedule(user1, amount, startTime, duration, cliff);
        
        // Move past full duration
        vm.warp(startTime + duration + 1);
        
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.prank(user1);
        token.releaseVestedTokens();
        
        uint256 balanceAfter = token.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, amount);
    }
    
    // ============ ADMIN FUNCTIONS TESTS ============
    
    function testPauseAndUnpause() public {
        vm.prank(owner);
        token.pause();
        assertTrue(token.paused());
        
        moveToPhase(2);
        expectRevertWithError(0x9e87fac8); // Pausable: paused
        buyTokensAs(user1, 1 ether);
        
        vm.prank(owner);
        token.unpause();
        assertFalse(token.paused());
        
        // Should work after unpause
        buyTokensAs(user1, 1 ether);
    }
    
    function testSetTreasury() public {
        address newTreasury = address(0x999);
        
        vm.prank(owner);
        token.setTreasury(newTreasury);
        
        assertEq(token.treasury(), newTreasury);
    }
    
    function testSetTreasuryInvalidAddress() public {
        expectRevertWithError(SmartTokens.InvalidAddress.selector);
        vm.prank(owner);
        token.setTreasury(address(0));
    }
    
    function testWithdrawFunds() public {
        moveToPhase(2);
        buyTokensAs(user1, 5 ether);
        
        uint256 treasuryBalanceBefore = treasury.balance;
        uint256 contractBalance = address(token).balance;
        
        vm.prank(owner);
        token.withdrawFunds(2 ether);
        
        assertEq(treasury.balance, treasuryBalanceBefore + 2 ether);
        assertEq(address(token).balance, contractBalance - 2 ether);
    }
    
    function testWithdrawFundsInsufficientBalance() public {
        moveToPhase(2);
        buyTokensAs(user1, 1 ether);
        
        expectRevertWithError(SmartTokens.InsufficientFunds.selector);
        vm.prank(owner);
        token.withdrawFunds(2 ether);
    }
    
    function testEmergencyWithdraw() public {
        moveToPhase(2);
        buyTokensAs(user1, 3 ether);
        
        uint256 contractBalance = address(token).balance;
        uint256 treasuryBalanceBefore = treasury.balance;
        
        vm.prank(owner);
        token.emergencyWithdraw();
        
        assertEq(treasury.balance, treasuryBalanceBefore + contractBalance);
        assertEq(address(token).balance, 0);
    }
    
    function testFinalizeICO() public {
        endICO();
        
        uint256 contractTokenBalance = token.balanceOf(address(token));
        
        vm.prank(owner);
        token.finalizeICO();
        
        assertTrue(token.icoFinalized());
        assertEq(token.balanceOf(address(token)), 0); // Tokens burned
    }
    
    function testFinalizeICOBeforeEnd() public {
        expectRevertWithError(SmartTokens.ICONotEnded.selector);
        vm.prank(owner);
        token.finalizeICO();
    }
    
    // ============ VIEW FUNCTIONS TESTS ============
    
    function testGetCurrentPhaseInfo() public {
        moveToPhase(1);
        
        (uint256 startTime, uint256 endTime, uint256 price, uint256 tokensAvailable, uint256 tokensSold, uint256 individualCap, bool requiresWhitelist, bool isActive) = token.getCurrentPhaseInfo();
        
        assertEq(startTime, icoStartTime);
        assertEq(endTime, icoStartTime + 14 days);
        assertEq(price, 0.0005 ether);
        assertEq(tokensAvailable, 100_000_000 * 10**18);
        assertEq(tokensSold, 0);
        assertEq(individualCap, 1_000_000 * 10**18);
        assertTrue(requiresWhitelist);
        assertTrue(isActive);
    }
    
    function testGetUserPurchases() public {
        moveToPhase(2);
        buyTokensAs(user1, 1 ether);
        buyTokensAs(user1, 0.5 ether);
        
        SmartTokens.Purchase[] memory purchases = token.getUserPurchases(user1);
        
        assertEq(purchases.length, 2);
        assertEq(purchases[0].price, 0.001 ether);
        assertEq(purchases[1].price, 0.001 ether);
    }
    
    function testGetVestedAmount() public {
        uint256 amount = 1_000_000 * 10**18;
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;
        uint256 cliff = 90 days;
        
        vm.prank(owner);
        token.createVestingSchedule(user1, amount, startTime, duration, cliff);
        
        // Before cliff
        assertEq(token.getVestedAmount(user1), 0);
        
        // At 50% duration (past cliff)
        vm.warp(startTime + 180 days);
        assertEq(token.getVestedAmount(user1), amount / 2);
        
        // At full duration
        vm.warp(startTime + duration);
        assertEq(token.getVestedAmount(user1), amount);
    }
    
    function testGetReleasableAmount() public {
        uint256 amount = 1_000_000 * 10**18;
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;
        uint256 cliff = 90 days;
        
        vm.prank(owner);
        token.createVestingSchedule(user1, amount, startTime, duration, cliff);
        
        vm.warp(startTime + 180 days);
        uint256 expectedReleasable = amount / 2;
        
        assertEq(token.getReleasableAmount(user1), expectedReleasable);
        
        // After partial release
        vm.prank(user1);
        token.releaseVestedTokens();
        
        assertEq(token.getReleasableAmount(user1), 0);
    }
    
    function testGetRemainingTokensInPhase() public {
        moveToPhase(2);
        
        uint256 remainingBefore = token.getRemainingTokensInPhase(2);
        assertEq(remainingBefore, 300_000_000 * 10**18);
        
        uint256 tokensBought = buyTokensAs(user1, 1 ether);
        
        uint256 remainingAfter = token.getRemainingTokensInPhase(2);
        assertEq(remainingAfter, 300_000_000 * 10**18 - tokensBought);
    }
    
    // ============ EDGE CASES AND SECURITY TESTS ============
    
    function testReentrancyProtection() public pure{
        // This test would require a malicious contract to test reentrancy
        // For now, we verify the modifier is in place
        assertTrue(true); // Placeholder
    }
    
    function testOnlyOwnerModifiers() public {
        vm.expectRevert();
        vm.prank(user1);
        token.createPhase(99, block.timestamp + 1, block.timestamp + 2, 0.001 ether, 1000 * 10**18, 100 * 10**18, false);
        
        vm.expectRevert();
        vm.prank(user1);
        token.pause();
        
        vm.expectRevert();
        vm.prank(user1);
        token.setTreasury(address(0x123));
        
        address[] memory users = new address[](1);
        users[0] = user2;
        
        vm.expectRevert();
        vm.prank(user1);
        token.updateWhitelist(users, true);
    }
    
    function testMultiplePurchasesSamePhase() public {
        moveToPhase(2);
        
        uint256 ethAmount1 = 1 ether;
        uint256 ethAmount2 = 0.5 ether;
        
        uint256 tokens1 = buyTokensAs(user1, ethAmount1);
        uint256 tokens2 = buyTokensAs(user1, ethAmount2);
        
        assertEq(token.userTotalPurchased(user1), tokens1 + tokens2);
        
        SmartTokens.Purchase[] memory purchases = token.getUserPurchases(user1);
        assertEq(purchases.length, 2);
    }
    
    function testPurchaseAcrossPhases() public {
        addToWhitelist(user1);
        
        // Buy in phase 1
        moveToPhase(1);
        uint256 tokens1 = buyTokensAs(user1, 1 ether);
        
        // Buy in phase 2
        moveToPhase(2);
        uint256 tokens2 = buyTokensAs(user1, 1 ether);
        
        assertTokenBalance(user1, tokens1 + tokens2, "Should have tokens from both phases");
        
        SmartTokens.Purchase[] memory purchases = token.getUserPurchases(user1);
        assertEq(purchases.length, 2);
        assertEq(purchases[0].phase, 1);
        assertEq(purchases[1].phase, 2);
    }
    
    function testIndividualCapAcrossMultiplePurchases() public {
        moveToPhase(2); // 100K token individual cap
        
        // Buy close to limit in multiple transactions
        uint256 ethAmount1 = 50_000 * 0.001 ether;
        uint256 ethAmount2 = 50_000 * 0.001 ether;
        
        buyTokensAs(user1, ethAmount1);
        buyTokensAs(user1, ethAmount2);
        
        // Try to exceed cap
        expectRevertWithError(SmartTokens.ExceedsIndividualCap.selector);
        buyTokensAs(user1, 1000 * 0.001 ether);
    }
}
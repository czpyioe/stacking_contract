// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Stacking, IERC20} from "../src/Stacking.sol";
import {Token} from "../src/Token.sol";

contract StackingTest is Test {
    Stacking public stacking;
    Token public token;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public owner = address(this);
    
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 constant DEPOSIT_AMOUNT = 1000 * 10**18;
    
    function setUp() public {
        token = new Token(INITIAL_SUPPLY, "Stacking Token", "STK");
        
        stacking = new Stacking(IERC20(address(token)));
        
        token.transfer(user1, 10_000 * 10**18);
        token.transfer(user2, 10_000 * 10**18);
        
        token.transfer(address(stacking), 100_000 * 10**18);
    }

    function test_Deployment() public {
        assertEq(address(stacking.token()), address(token));
        assertEq(stacking.total_stacked(), 0);
        assertEq(stacking.rewardsPerHour(), 100);
    }

    function test_Deposit() public {
        vm.startPrank(user1);
        
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        
        stacking.deposit(DEPOSIT_AMOUNT);
        
        assertEq(stacking.balanceOf(user1), DEPOSIT_AMOUNT);
        assertEq(stacking.total_stacked(), DEPOSIT_AMOUNT);
        assertEq(token.balanceOf(user1), 10_000 * 10**18 - DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function test_DepositEmitsEvent() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        
        vm.expectEmit(true, true, true, true);
        emit Stacking.Deposit(user1, DEPOSIT_AMOUNT);
        
        stacking.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function test_MultipleDeposits() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        assertEq(stacking.total_stacked(), DEPOSIT_AMOUNT * 2);
        assertEq(stacking.balanceOf(user1), DEPOSIT_AMOUNT);
        assertEq(stacking.balanceOf(user2), DEPOSIT_AMOUNT);
    }

    function test_RewardsAccumulation() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.warp(block.timestamp + 1 hours);
        
        // rewards = (time * balance) / (rewardsPerHour * 1 hours)
        // rewards = (3600 * 1000e18) / (100 * 3600) = 10e18
        uint256 expectedRewards = DEPOSIT_AMOUNT / 100;
        uint256 actualRewards = stacking.rewards(user1);
        
        assertEq(actualRewards, expectedRewards);
        vm.stopPrank();
    }

    function test_Claim() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.warp(block.timestamp + 1 hours);
        
        uint256 balanceBefore = token.balanceOf(user1);
        uint256 rewardAmount = stacking.rewards(user1);
        
        stacking.claim();
        
        uint256 balanceAfter = token.balanceOf(user1);
        
        assertEq(balanceAfter - balanceBefore, rewardAmount);
        assertEq(stacking.claimed(user1), rewardAmount);
        assertEq(stacking.rewards(user1), 0); 
        
        vm.stopPrank();
    }

    function test_ClaimEmitsEvent() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.warp(block.timestamp + 1 hours);
        uint256 rewardAmount = stacking.rewards(user1);
        
        vm.expectEmit(true, true, true, true);
        emit Stacking.Claim(user1, rewardAmount);
        
        stacking.claim();
        vm.stopPrank();
    }

    function test_Compound() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.warp(block.timestamp + 1 hours);
        
        uint256 rewardAmount = stacking.rewards(user1);
        uint256 balanceBefore = stacking.balanceOf(user1);
        
        stacking.compound();
        
        uint256 balanceAfter = stacking.balanceOf(user1);
        
        assertEq(balanceAfter, balanceBefore + rewardAmount);
        assertEq(stacking.total_stacked(), DEPOSIT_AMOUNT + rewardAmount);
        assertEq(stacking.claimed(user1), rewardAmount);
        
        vm.stopPrank();
    }

    function test_CompoundEmitsEvent() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.warp(block.timestamp + 1 hours);
        uint256 rewardAmount = stacking.rewards(user1);
        
        vm.expectEmit(true, true, true, true);
        emit Stacking.Compound(user1, rewardAmount);
        
        stacking.compound();
        vm.stopPrank();
    }

    function test_Withdraw() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.warp(block.timestamp + 1 hours);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT / 2;
        uint256 balanceBefore = token.balanceOf(user1);
        
        stacking.withdraw(withdrawAmount);
        
        uint256 balanceAfter = token.balanceOf(user1);
        
        assertEq(balanceAfter - balanceBefore, withdrawAmount);
        assertGt(stacking.balanceOf(user1), DEPOSIT_AMOUNT / 2);
        
        vm.stopPrank();
    }

    function test_WithdrawRevertsIfNotEnoughFunds() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.expectRevert("Not enough funds");
        stacking.withdraw(DEPOSIT_AMOUNT * 2);
        
        vm.stopPrank();
    }

    function test_WithdrawEmitsEvent() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT / 2;
        
        vm.expectEmit(true, true, true, true);
        emit Stacking.Withdraw(user1, withdrawAmount);
        
        stacking.withdraw(withdrawAmount);
        vm.stopPrank();
    }

    function test_TotalRewards() public {
        uint256 rewardsAdded = 50_000 * 10**18;
        token.transfer(address(stacking), rewardsAdded);
        
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        uint256 expectedTotalRewards = 100_000 * 10**18 + rewardsAdded;
        assertEq(stacking.totalRewards(), expectedTotalRewards);
    }

    function test_CompoundIncreasesRewardsRate() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        
        vm.warp(block.timestamp + 1 hours);
        stacking.compound();
        
        uint256 balanceAfterCompound = stacking.balanceOf(user1);
        
        vm.warp(block.timestamp + 1 hours);
        
        uint256 rewards = stacking.rewards(user1);
        uint256 expectedRewards = balanceAfterCompound / 100;
        
        assertEq(rewards, expectedRewards);
        assertGt(rewards, DEPOSIT_AMOUNT / 100);
        
        vm.stopPrank();
    }

    function test_MultipleUsersIndependentRewards() public {
        vm.startPrank(user1);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 30 minutes);
        
        vm.startPrank(user2);
        token.approve(address(stacking), DEPOSIT_AMOUNT);
        stacking.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 30 minutes);
        
        uint256 rewardsUser1 = stacking.rewards(user1);
        uint256 rewardsUser2 = stacking.rewards(user2);
        
        assertEq(rewardsUser1, rewardsUser2 * 2);
    }
}
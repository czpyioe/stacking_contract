# Stacking Contract

A simple ERC20 token staking contract with reward distribution built with Solidity and Foundry.

## Features

- **Deposit**: Stake ERC20 tokens to earn rewards
- **Claim**: Withdraw accumulated rewards to your wallet
- **Compound**: Automatically reinvest rewards to increase staking position
- **Withdraw**: Remove staked tokens (with automatic compound)

## Contracts

- `Token.sol`: ERC20 token for staking
- `Stacking.sol`: Main staking contract with reward mechanism

## Setup

```shell
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
``` 

## Test result
```shell
Ran 15 tests for test/Stacking.t.sol:StackingTest
[PASS] test_Claim() (gas: 152976)
[PASS] test_ClaimEmitsEvent() (gas: 146781)
[PASS] test_Compound() (gas: 148185)
[PASS] test_CompoundEmitsEvent() (gas: 143423)
[PASS] test_CompoundIncreasesRewardsRate() (gas: 143925)
[PASS] test_Deployment() (gas: 12643)
[PASS] test_Deposit() (gas: 117271)
[PASS] test_DepositEmitsEvent() (gas: 114706)
[PASS] test_MultipleDeposits() (gas: 191073)
[PASS] test_MultipleUsersIndependentRewards() (gas: 193375)
[PASS] test_RewardsAccumulation() (gas: 115980)
[PASS] test_TotalRewards() (gas: 125070)
[PASS] test_Withdraw() (gas: 151426)
[PASS] test_WithdrawEmitsEvent() (gas: 127469)
[PASS] test_WithdrawRevertsIfNotEnoughFunds() (gas: 114655)
Suite result: ok. 15 passed; 0 failed; 0 skipped; finished in 2.65ms (7.03ms CPU time)

Ran 1 test suite in 6.85ms (2.65ms CPU time): 15 tests passed, 0 failed, 0 skipped (15 total tests)
``` 

## How It Works

- Users deposit tokens and earn rewards over time (100 tokens per hour staked)
- Rewards can be claimed (withdrawn) or compounded (reinvested)
- Each withdrawal automatically compounds pending rewards first



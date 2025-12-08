// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Stacking {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    uint256 public total_stacked = 0;

    uint256 public immutable rewardsPerHour = 100; 

    mapping (address=>uint256) public balanceOf;
    mapping (address=>uint256) public lastUpdated;

    mapping (address=>uint256) public claimed;

    event Deposit(address address_, uint256 amount);

    event Claim(address address_, uint256 amount);

    event Compound(address address_, uint256 amount);

    event Withdraw(address address_, uint256 amount);

    constructor (IERC20 _token){
        token = _token;
    }

    function deposit(uint256 amount) external{
        _compound();
        token.safeTransferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender]+=amount;
        lastUpdated[msg.sender]=block.timestamp;
        total_stacked += amount;
        emit Deposit(msg.sender, amount);
    }


    function totalRewards() external view returns (uint256){
        return _totalRewards();
    }
    function _totalRewards() internal view returns (uint256){
        return token.balanceOf(address(this))-total_stacked;
    }


    function rewards(address address_) external view returns (uint256){
        return _rewards(address_);
    }

    function _rewards(address address_) internal view returns (uint256){
        return (block.timestamp - lastUpdated[address_])*balanceOf[address_] / (rewardsPerHour * 1 hours);
    }

    function claim() external {
        uint256 amount = _rewards(msg.sender);
        token.safeTransfer(msg.sender,amount);
        claimed[msg.sender]+=amount;
        lastUpdated[msg.sender] = block.timestamp;
        emit Claim(msg.sender,amount);
    }

    function _compound() internal {
        uint256 amount = _rewards(msg.sender);
        claimed[msg.sender]+=amount;
        balanceOf[msg.sender]+=amount;
        total_stacked+=amount;
        lastUpdated[msg.sender] = block.timestamp;
        emit Compound(msg.sender, amount);
    }

    function compound() external {
        _compound();
    }

    function withdraw(uint256 amount) external{
        require(amount<=balanceOf[msg.sender],"Not enough funds");
        _compound();
        token.safeTransfer(msg.sender,amount);
        balanceOf[msg.sender]-= amount;
        total_stacked-= amount;
        emit Withdraw(msg.sender,amount);
    }
}

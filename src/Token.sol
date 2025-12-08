// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor (uint256 initial_supply, string memory token_name, string memory token_symbol) ERC20 (token_name,token_symbol){
        _mint(msg.sender, initial_supply);
    }
}
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

/**
 * @title Context抽象合约
 * @author Aliceonly 
 * @notice 提供msg.sender和msg.data
 */

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata){
        return msg.data;
    }
}
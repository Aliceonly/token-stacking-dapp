// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "./Address.sol";

/**
 * @title 初始化合约程序
 * @author Aliceonly
 * @notice 
 */

abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;

    event Initialized(uint8 version);

    //初始化Top合约
    modifier initializer() {
        //确保Top合约被初始化
        bool isTopLevelCall = !_initializing;
        //确保合约未被初始化
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized == 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    //re初始化合约
    modifier reinitializer(uint8 version) {
        require(
            (!_initializing && _initialized < version),
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    //仅在初始化时调用
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    //禁止初始化
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if(_initialized < type(uint8).max){
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

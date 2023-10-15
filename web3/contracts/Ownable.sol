pragma solidity ^0.8.9;

import "./Context.sol";

/**
 * @title Ownable抽象合约
 * @author Aliceonly
 * @notice 
 */

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //构造时拥有
    constructor() {
        _transferOwnership(_msgSender());
    }

    //限制拥有
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns(address){
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    //放弃拥有
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


}
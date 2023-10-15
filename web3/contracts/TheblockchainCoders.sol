// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

/**
 * @title custom ERC20 Token
 * @author Aliceonly
 */

contract TheblockchainCoders() {
    string public name = "@Aliceonly";
    string public symbol = "ABC";
    string public standard = "AliceonlyBlockCoin v1";
    uint256 public totalSupply;
    address public ownerOfContract;
    uint256 public _userId;

    uint256 constant initialSupply = 1000000 * (10 ** 18);

    address[] public holderToken;

    event Transfer(address indexed _from, address indexed _to, uint256 value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 value
    );

    mapping (address => TokenHolderInfo) public tokenHolderInfos;

    struct TokenHolderInfo {
        uint256 _tokenId;
        address _from;
        address _to;
        uint256 _totalToken;
        bool _tokenHolder;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        ownerOfContract = msg.sender;
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    function inc() internal {
        _userId++;
    }

    function transfer(address _to, uint256 _value) public returns(bool success){
        require(balanceOf[msg.sender] >= value);
        inc();
        balanceOf[msg.sender] -= value;
        balanceOf[_to] += value;

        TokenHolderInfo storage tokenHolderInfos = tokenHolderInfos[_to];
        tokenHolderInfos._tokenId = _userId;
        tokenHolderInfos._to = _to;
        tokenHolderInfos._from = msg.sender;
        tokenHolderInfos._totalToken = _value;
        tokenHolderInfos._tokenHolder = true;

        holderToken.push(_to);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns(bool success){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= value;
        balanceOf[_to] += value;

        allowance[_from][msg.sender] -= value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function getTokenHolderData(address _address) public view returns(uint256, address, address,uint256, bool){
        return(
            tokenHolderInfos[_address]._tokenId,
            tokenHolderInfos[_address]._to,
            tokenHolderInfos[_address]._from,
            tokenHolderInfos[_address]._totalToken,
            tokenHolderInfos[_address]._tokenHolder,
        )
    }

    function getTokenHolder() public view returns(address[] memory){
        return holderToken;
    }
}
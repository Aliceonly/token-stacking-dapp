// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./IERC20.sol";

contract TokenStaking is Ownable, ReentrancyGuard, Initializable {
    //存user detail的结构体
    struct User {
        uint256 stakeAmount; //质押的数量
        uint256 rewardAmount; //奖励的数量
        uint256 lastStakeTime; //上次质押时间
        uint256 lastRewardCalculationTime; //上次结算奖励时间
        uint256 rewardsClaimedSoFar; //历史奖励
    }

    uint256 _minimunStakingAmount;
    uint256 _maxStakeTokenLimit;
    uint256 _stakeEndDate;
    uint256 _stakeStartDate;
    uint256 _totalStakedTokens;

    uint256 _totalUsers;
    uint256 _stakeDays;
    uint256 _earlyUnstakeFeePercentage;

    bool _isStakingPaused;
    address private _tokenAddress;

    uint256 _apyRate;

    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint256 public constant APY_RATE_CHANGE_THRESHOLD = 10;

    mapping(address => User) private _users;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);
    event EarlyUnStakeFee(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

    modifier whenTreasuryHasBalance() {
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= amount,
            "Treasury has insufficient balance"
        );
        _;
    }

    function initialize(
        address owner_,
        address tokenAddress_,
        uint256 apyRate_,
        uint256 minimunStakingAmount_,
        uint256 maxStakeTokenLimit_,
        uint256 stakeStartDate_,
        uint256 stakeEndDate_,
        uint256 stakeDays_,
        uint256 earlyUnstakeFeePercentage_
    ) public virtual initializer {
        __TokenStaking_init_unchained(
            owner_,
            tokenAddress_,
            apyRate_,
            minimunStakingAmount_,
            maxStakeTokenLimit_,
            stakeStartDate_,
            stakeEndDate_,
            stakeDays_,
            earlyUnstakeFeePercentage_
        );
    }

    function __TokenStaking_init_unchained(
        address owner_,
        address tokenAddress_,
        uint256 apyRate_,
        uint256 minimunStakingAmount_,
        uint256 maxStakeTokenLimit_,
        uint256 stakeStartDate_,
        uint256 stakeEndDate_,
        uint256 stakeDays_,
        uint256 earlyUnstakeFeePercentage_
    ) internal onlyInitializing {
        require(_apyRate <= 10000, "APY rate cannot be more than 100%");
        require(stakeDays_ > 0, "Stake days cannot be 0");
        require(tokenAddress_ != address(0), "Token address cannot be 0");
        require(
            stakeStartDate_ < stakeEndDate_,
            "Stake start date cannot be less than end date"
        );
        _transferOwnership(owner_);
        _tokenAddress = tokenAddress_;
        _apyRate = apyRate_;
        _minimunStakingAmount = minimunStakingAmount_;
        _maxStakeTokenLimit = maxStakeTokenLimit_;
        _stakeStartDate = stakeStartDate_;
        _stakeEndDate = stakeEndDate_;
        _stakeDays = stakeDays_ * 1 days;
        _earlyUnstakeFeePercentage = earlyUnstakeFeePercentage_;
    }

    /**
     * View Methods
     */
    function getMinimumStakingAmount() external view returns(uint256) {
        return _minimunStakingAmount;
    }

    function getMaxStakingTokenLimit() external view returns(uint256){
        return _maxStakeTokenLimit;
    }

    function getStakeStartDate() external view returns(uint256){
        return _stakeStartDate;
    }

    function getTotalStakedToken() external view returns(uint256){
        return _totalStakedTokens;
    }

    function getTotalUser() external view returns(uint256){
        return _totalUsers;
    }

    function getStakeDays() external view returns(uint256){
        return _stakeDays;
    }

    function getEarlyUnstakeFeePercentage() external view returns(uint256){
        return _earlyUnstakeFeePercentage;
    }

    function getStakingStatus() external view returns(bool){
        return _isStakingPaused;
    }

    function getAPY() external view returns(uint256){
        return _apyRate;
    }

    function getUserEstimatedRewards() external view returns(uint256){
        (uint256 amount, ) = _getUserEstimatedRewards(msg.sender);
        return _users[msg.sender].rewardAmount + amount;
    }

    function getWithdrawableAmount() external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this)) - _totalStakedTokens;
    }

    function getUser(address userAddress) external view returns(User memory){
        return _users[userAddress];
    }

    function isStakingHolder(address _user) external view returns(bool){
        return _users[_user].stakeAmount > 0;
    }

    /**
     * Owner Methods
     */

    function updateMinimumStakingAmount(uint256 newAmount) external onlyOwner {
        _minimunStakingAmount = newAmount;
    }

    function updateMaxStakingTokenLimit(uint256 newAmount) external onlyOwner {
        _maxStakeTokenLimit = newAmount;
    }

    function updateStakeEndDate(uint256 newDate) external onlyOwner {
        _stakeEndDate = newDate;
    }

    function updateEarlyUnstakeFeePercentage(uint256 newPercentage) external onlyOwner {
        _earlyUnstakeFeePercentage = newPercentage;
    }

    function stakeForUser(uint256 amount, address user) external onlyOwner nonReentrant {
        _stake(amount, user);
    }

    function toggleStakingStatus() external onlyOwner {
        _isStakingPaused = !_isStakingPaused;
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        require(
            this.getWithdrawableAmount() >= amount,
            "Treasury has insufficient balance"
        );
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    
}

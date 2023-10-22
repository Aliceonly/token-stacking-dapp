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
    function getMinimumStakingAmount() external view returns (uint256) {
        return _minimunStakingAmount;
    }

    function getMaxStakingTokenLimit() external view returns (uint256) {
        return _maxStakeTokenLimit;
    }

    function getStakeStartDate() external view returns (uint256) {
        return _stakeStartDate;
    }

    function getTotalStakedToken() external view returns (uint256) {
        return _totalStakedTokens;
    }

    function getTotalUser() external view returns (uint256) {
        return _totalUsers;
    }

    function getStakeDays() external view returns (uint256) {
        return _stakeDays;
    }

    function getEarlyUnstakeFeePercentage() external view returns (uint256) {
        return _earlyUnstakeFeePercentage;
    }

    function getStakingStatus() external view returns (bool) {
        return _isStakingPaused;
    }

    function getAPY() external view returns (uint256) {
        return _apyRate;
    }

    function getUserEstimatedRewards() external view returns (uint256) {
        (uint256 amount, ) = _getUserEstimatedRewards(msg.sender);
        return _users[msg.sender].rewardAmount + amount;
    }

    function getWithdrawableAmount() external view returns (uint256) {
        return
            IERC20(_tokenAddress).balanceOf(address(this)) - _totalStakedTokens;
    }

    function getUser(address userAddress) external view returns (User memory) {
        return _users[userAddress];
    }

    function isStakingHolder(address _user) external view returns (bool) {
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

    function updateEarlyUnstakeFeePercentage(
        uint256 newPercentage
    ) external onlyOwner {
        _earlyUnstakeFeePercentage = newPercentage;
    }

    function stakeForUser(
        uint256 amount,
        address user
    ) external onlyOwner nonReentrant {
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

    function stake(uint256 _amount) external nonReentrant {
        _stakeTokens(_amount, msg.sender);
    }

    function _stakeTokens(uint256 _amount, address user_) private {
        require(!_isStakingPaused, "Token staking is paused");
        uint256 currentTime = getCurrentTime();
        require(
            currentTime > _stakeStartDate && currentTime < _stakeEndDate,
            "Staking is not allowed at this time"
        );
        require(
            _totalStakedTokens + _amount <= _maxStakeTokenLimit,
            "Stake limit reached"
        );
        require(_amount > 0, "Token amount cannot be 0");
        require(
            _amount >= _minimunStakingAmount,
            "Amount is less than minimum stake amount"
        );

        if (_users[user_].stakeAmount != 0) {
            _calculateRewards(user_);
        } else {
            _users[user_].lastRewardCalculationTime = currentTime;
            _totalUsers++;
        }

        _user[user_].stakeAmount += _amount;
        _user[user_].lastStakeTime = currentTime;

        _totalStakedTokens += _amount;

        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Token transfer failed"
        );

        emit Stake(user_, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant whenTreasuryHasBalance(_amount) {
        address user = msg.sender;
        require(_amount != 0, "Amount cannot be 0");
        require(this.isStakeHolder(user), "User is not a stake holder");
        require(
            _users[user].stakeAmount >= _amount,
            "Insufficient staked amount"
        );
        _calculateRewards(user);

        uint256 feeEarlyUnstake;

        if(getCurrentTime() < _users[user].lastStakeTime + _stakeDays) {
            feeEarlyUnstake = (_amount * _earlyUnstakeFeePercentage) / PERCENTAGE_DENOMINATOR;
            emit EarlyUnStakeFee(user, feeEarlyUnstake);
        }

        uint256 amountToUnstake = _amount - feeEarlyUnstake;

        _users[user].stakeAmount -= _amount;
        _totalStakedTokens -= _amount;

        if(_users[user].stakeAmount == 0) {
            _totalUsers--;
        }

        require(
            IERC20(_tokenAddress).transfer(user, amountToUnstake),
            "Token transfer failed"
        );
        emit UnStake(user, _amount);
    }

    function claimReward() external nonReentrant whenTreasuryHasBalance(_users[msg.sender].rewardAmount) {
        _calculateRewards(msg.sender);
        uint256 rewardAmount = _users[msg.sender].rewardAmount;

        require(rewardAmount > 0, "No rewards to claim");
        
        require(IERC20(_tokenAddress).transfer(msg.sender, rewardAmount), "Token transfer failed");))
        _users[msg.sender].rewardAmount = 0;
        _users[msg.sender].rewardsClaimedSoFar += rewardAmount;

        emit ClaimReward(msg.sender, rewardAmount);
    }

    function _calculateRewards(address _user) private {
        (uint256 userReward, uint256 currentTime) = _getUserEstimatedRewards(_user);

        _users[_user].rewardAmount += userReward;
        _users[_user].lastRewardCalculationTime = currentTime;
    }

    function _getUserEstimatedRewards(address _user) private view returns(uint256, uint256){
        uint256 userReward;
        uint256 userTimestamp = _users[_user].lastRewardCalculationTime;

        uint256 currentTime = getCurrentTime();

        if(currentTime > _users[_user].lastStakeTime + _stakeDays) {
            currentTime = _users[_user].lastStakeTime + _stakeDays
        }

        uint256 totalStakedTime = currentTime - userTimestamp;

        userReward += ((totalStakedTime * _users[_user].stakeAmount * _apyRate) / 365 days) / PERCENTAGE_DENOMINATOR;
        
        return(userReward,currentTime);
    }

    function getCurrentTime() internal view returns(uint256) {
        return block.timestamp;
    }
}

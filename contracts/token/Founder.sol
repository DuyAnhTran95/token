pragma solidity ^0.7.5;

import "../library/IERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @title Staking Token (STK)
 * @author Alberto Cuesta Canada
 * @notice Implements a basic ERC20 staking token with incentive distribution.
 */
contract Founder is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Mintable;

    struct PoolInfo {
        uint256 shares;
        uint256 withdraw;
    }

    struct Staker {
        uint256 amount;
        uint256 withdraw;
    }

    mapping (address => PoolInfo) _pools;
    mapping (address => Staker) _stakers;

    IERC20Mintable _rewardToken;
    uint256 _totalShare;
    uint256 _startBlock;
    uint256 _lastBlock;
    uint256 _poolRewardPerBlock;
    uint256 _stakerRewardPerBlock;
    uint256 _totalStaked;

    constructor(uint256 startBlock, address rewardToken, address[] memory pools, uint256[] memory poolShares,
            uint256 poolRewardPerBlock, uint256 stakerRewardPerBlock) {
        require(pools.length == poolShares.length, "pools and shares data lenght different");
        
        uint256 totalShare = 0;
        for (uint i = 0; i < pools.length; i++) {
            _pools[pools[i]] = PoolInfo(poolShares[i], 0);
            totalShare = totalShare.add(poolShares[i]);
        }

        _totalShare = totalShare;
        _rewardToken = IERC20Mintable(rewardToken);
        _poolRewardPerBlock = poolRewardPerBlock;
        _stakerRewardPerBlock = stakerRewardPerBlock;
        _startBlock = startBlock;
        _lastBlock = startBlock + (86400 * 365 * 4) / 3; //4 years
    }

    modifier stakingUnlock() {
        require(block.number >= _lastBlock, "Stake token locked");
        _;
    }

    function setRewardPerBlock(uint256 reward) external onlyOwner {
        _poolRewardPerBlock = reward;
    }

    function setStakerRewardPerBlock(uint256 stakerReward) external onlyOwner {
        _stakerRewardPerBlock = stakerReward;
    }
    function getTotalPoolReward(PoolInfo memory pool) internal view returns (uint256 poolReward) {
         uint256 totalReward = (block.number - _startBlock).mul(_poolRewardPerBlock);

        poolReward = totalReward.div(_totalShare).mul(pool.shares);
    }

    function redeemPoolReward() external {
        PoolInfo memory pool = _pools[msg.sender];
        require(pool.shares > 0, "Only pool can redeem");

        uint256 totalReward = getTotalPoolReward(pool);
        uint256 reward = totalReward.sub(pool.withdraw);

        _rewardToken.mint(msg.sender, reward);
        _pools[msg.sender].withdraw = totalReward;
    }

    function getStakerTotalReward(Staker memory staker) internal view returns (uint256 stakerReward) {
        uint256 totalReward = (block.number - _startBlock).mul(_stakerRewardPerBlock);

        stakerReward = totalReward.div(_totalStaked).mul(staker.amount);
    }

    function redeemStakingReward() external {
        Staker memory staker = _stakers[msg.sender];
        require(staker.amount > 0, "Only staker can redeem");

        uint256 totalReward = getStakerTotalReward(staker);
        uint256 reward = totalReward.sub(staker.withdraw);

        _rewardToken.mint(msg.sender, reward);
        _stakers[msg.sender].withdraw = totalReward;
    }

    function stakeFor(address stakerAddr, uint256 amount) external onlyOwner {
        require(_stakers[stakerAddr].amount != 0, "Staker already existed");
        Staker memory staker = Staker(amount, 0);

        _stakers[stakerAddr] = staker;
    }

    function unstake(address stakerAddr, uint256 amount) external onlyOwner stakingUnlock {
        Staker memory staker = _stakers[stakerAddr];
        require(staker.amount >= amount, "Amount higher than staked amount");

        staker.amount = staker.amount - amount;
        _totalStaked.sub(amount);

        _stakers[stakerAddr] = staker;
        _rewardToken.mint(stakerAddr, amount);
    }
}
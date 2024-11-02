// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "ERC20.sol";
import "Ownable.sol";

contract BlockFixToken is ERC20, Ownable {
    uint256 public constant initialSupply = 100_000_000 ether;
    uint256 public constant dividendSupply = 40_000_000 ether;
    uint256 public constant developmentSupply = 30_000_000 ether;
    uint256 public constant ecosystemSupply = 20_000_000 ether;
    uint256 public constant governanceSupply = 10_000_000 ether;

    uint256 public crowdfundingSupply;
    uint256 public stakingRewardsPool;
    uint256 public constant stakingRewardRate = 1000; // Example reward rate: 0.1%

    struct Stake {
        uint256 amount;
        uint256 since;
    }

    mapping(address => Stake) private _stakes;

    event StakeCreated(address indexed staker, uint256 amount);
    event StakeWithdrawn(address indexed staker, uint256 amount);

    constructor(
        address dividendAddress,
        address developmentAddress,
        address ecosystemAddress,
        address governanceAddress,
        uint256 _crowdfundingSupply,
        uint256 _stakingRewardsPool
    ) ERC20("BlockFix Token", "BFX") {
        require(dividendSupply + developmentSupply + ecosystemSupply + governanceSupply + _crowdfundingSupply + _stakingRewardsPool == initialSupply, "Invalid supply settings");
        
        crowdfundingSupply = _crowdfundingSupply;
        stakingRewardsPool = _stakingRewardsPool;

        _mint(dividendAddress, dividendSupply);
        _mint(developmentAddress, developmentSupply);
        _mint(ecosystemAddress, ecosystemSupply);
        _mint(governanceAddress, governanceSupply);
    }

    // Crowdfunding: Allow users to purchase tokens during the event
    function purchaseTokens() external payable {
        uint256 tokensToPurchase = msg.value * 1000; // 1 ETH = 1000 BFX example rate
        require(tokensToPurchase <= crowdfundingSupply, "Not enough tokens available for sale");

        crowdfundingSupply -= tokensToPurchase;
        _mint(msg.sender, tokensToPurchase);
    }

    // Staking Functionality
    function createStake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero tokens");
        transfer(address(this), amount);
        _stakes[msg.sender] = Stake(amount, block.timestamp);
        emit StakeCreated(msg.sender, amount);
    }

    function withdrawStake() external {
        Stake memory staked = _stakes[msg.sender];
        require(staked.amount > 0, "No stake found");

        uint256 reward = calculateReward(staked.amount, staked.since);
        require(reward <= stakingRewardsPool, "Insufficient reward pool");

        _transfer(address(this), msg.sender, staked.amount + reward);

        stakingRewardsPool -= reward;
        delete _stakes[msg.sender];

        emit StakeWithdrawn(msg.sender, staked.amount + reward);
    }

    function calculateReward(uint256 amount, uint256 since) internal view returns (uint256) {
        uint256 timeStaked = block.timestamp - since;
        // Reward formula based on time and rate
        return (amount * stakingRewardRate * timeStaked) / 365 days / 10_000;
    }

    // Optional token burn mechanism
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';


interface IMigratorChef {
    // Perform LP token migration from legacy PancakeSwap to PeaceSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PancakeSwap LP tokens.
    // PeaceSwap must mint EXACTLY the same amount of PeaceSwap LP tokens or
    // else something bad will happen. Traditional PancakeSwap does not
    // do that so be careful!
    function migrate(IBEP20 token) external returns (IBEP20);
}

// MasterChef is the master of Peace. He can make Peace and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PEACE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 stakeTime; // Reward debt. See explanation below.
        uint256 nextHarvestUntil; //stakeTime + pool.withdrawLockPeriod
        //
        // We do some fancy math here. Basically, any point in time, the amount of PEACEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPeacePerShare) - user.stakeTime
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPeacePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `stakeTime` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 apr;       // How many allocation points assigned to this pool. PEACEs to distribute per block.
        uint256 withdrawLockPeriod; // lock period for this pool
        uint256 balance;            // pool token balance, allow multiple pools with same token
       
    }

    IBEP20 public PeaceToken;
    address public devaddr;
    address public rewardaddr;
   
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _peace,
        address _devaddr,
        address _rewardaddr
    ) public {
        PeaceToken = IBEP20(_peace);
        devaddr = _devaddr;
        rewardaddr = _rewardaddr;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: PeaceToken,
            apr: 30,
            withdrawLockPeriod: 30 days,
            balance: 0  
        }));
        poolInfo.push(PoolInfo({
            lpToken: PeaceToken,
            apr: 50,
            withdrawLockPeriod: 60 days,
            balance: 0  
        }));
        poolInfo.push(PoolInfo({
            lpToken: PeaceToken,
            apr: 80,
            withdrawLockPeriod: 90 days,
            balance: 0  
        }));
        poolInfo.push(PoolInfo({
            lpToken: PeaceToken,
            apr: 130,
            withdrawLockPeriod: 180 days,
            balance: 0  
        }));
        poolInfo.push(PoolInfo({
            lpToken: PeaceToken,
            apr: 250,
            withdrawLockPeriod: 360 days,
            balance: 0  
        }));

    }

    function updateapr(uint256 _pid, uint256 _apr) public onlyOwner {
        require(_apr>0, "apr set error");
        PoolInfo storage pool = poolInfo[_pid];
        pool.apr = _apr;
    }

    function updatewithdrawLockPeriod(uint256 _pid, uint256 _withdrawLockPeriod) public onlyOwner {
        require(_withdrawLockPeriod>0, "withdrawLockPeriod set error");
        PoolInfo storage pool = poolInfo[_pid];
        pool.withdrawLockPeriod = _withdrawLockPeriod;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IBEP20 _lpToken, uint256 _apr, uint256 _withdrawLockPeriod) public onlyOwner {

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            apr: _apr,
            withdrawLockPeriod: _withdrawLockPeriod,
            balance: 0
        }));

    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IBEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(1e12).div(365 days);
    }

    // View function to see pending PEACEs on frontend.
    function pendingPeace(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 multiplier = getMultiplier(user.stakeTime, block.timestamp);
        return user.amount.mul(multiplier).div(1e12).mul(pool.apr).div(100);
    }


    // Deposit LP tokens to MasterChef for PEACE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        if (user.amount > 0) {
            uint256 pending = pendingPeace(_pid, msg.sender);
            if(pending > 0) {
                pool.lpToken.safeTransferFrom(rewardaddr, msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            user.stakeTime = block.timestamp;
            user.nextHarvestUntil = user.stakeTime + pool.withdrawLockPeriod;
            
            pool.balance = pool.balance.add(_amount);
        }
        
        emit Deposit(msg.sender, _pid, _amount);
    }

    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return (user.nextHarvestUntil > 0) && (block.timestamp >= user.nextHarvestUntil);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(user.nextHarvestUntil > 0, "not staked ");
        require( block.timestamp >= user.nextHarvestUntil, "in lock period");

        uint256 pending = pendingPeace(_pid, msg.sender);
        if(pending > 0) {
            uint256 feeAmount = pending.div(100);
            pool.lpToken.safeTransferFrom(rewardaddr, devaddr, feeAmount);
            pool.lpToken.safeTransferFrom(rewardaddr, msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.balance = pool.balance.sub(_amount);

        }

        if(user.amount == 0){
            user.stakeTime = 0;
            user.nextHarvestUntil = 0;
        }
        
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 emerAmount = user.amount.mul(99).div(100);
        pool.lpToken.safeTransfer(address(msg.sender), emerAmount);
        pool.lpToken.safeTransfer(devaddr, user.amount.sub(emerAmount));

        user.stakeTime = 0;
        user.nextHarvestUntil = 0;
        pool.balance = pool.balance.sub(user.amount);

        user.amount = 0;
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "devaddr: wut?");
        require(msg.sender != address(this), "devaddr: wut?");
        require(msg.sender != address(0), "devaddr: wut?");
        devaddr = _devaddr;
    }
    function setRewardAddr(address _rewardaddr) public {
        require(msg.sender == rewardaddr, "rewardaddr: wut?");
        require(msg.sender != address(this), "devaddr: wut?");
        require(msg.sender != address(0), "devaddr: wut?");
        rewardaddr = _rewardaddr;
    }
}

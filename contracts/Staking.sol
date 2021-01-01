pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract Staking is AccessControl {
    using SafeMath for uint256;
    address[] public stakeholders;
    uint256 public numOfStakeHolders;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewards;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    IERC20 public mok;

    constructor(address _owner, address _mok) public {
        _setupRole(OWNER_ROLE, _owner);
        mok = IERC20(_mok);
    }

    function isStakeHolder(address _address)
        public
        view
        returns (bool, uint256)
    {
        // loop through stakeholders and if address exists then return true and index
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    // check if stakeholder already is in array before pushing in new address
    function addStakeHolder(address _stakeholder) public {
        (bool _isStakeHolder, ) = isStakeHolder(_stakeholder);
        if (!_isStakeHolder) stakeholders.push(_stakeholder);
        numOfStakeHolders = stakeholders.length;
    }

    function removeStakeHolder(address _stakeholder) public {
        (bool _isStakeHolder, uint256 s) = isStakeHolder(_stakeholder);
        if (_isStakeHolder) {
            // if stake holder exists
            // set stakeholders at index s to the last value in the array and pop (remove last value)
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
        numOfStakeHolders = stakeholders.length;
    }

    // find stake size of specific stake holder
    function stakeOf(address _stakeholder) public view returns (uint256) {
        return stakes[_stakeholder];
    }

    // find total stakes
    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            // safe math to add
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }

        return _totalStakes;
    }

    // create new stakes
    function createStakes(uint256 _stake) public {
        mok.transferFrom(msg.sender, address(this), _stake);
        if (stakes[msg.sender] == 0) addStakeHolder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    // remove stakes
    function removeStakes(uint256 _stake) public {
        // safe math throws error code if negative
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if (stakes[msg.sender] == 0) removeStakeHolder(msg.sender);
        mok.transfer(msg.sender, _stake);
    }

    // return rewards of stakeholder
    function rewardOf(address _stakeholder) public view returns (uint256) {
        return rewards[_stakeholder];
    }

    // returns aggregated reward of all stakeholders
    function totalReward() public view returns (uint256) {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    // let the reward be 1% of the stakeholders stake
    function calcReward(address _stakeholder) public view returns (uint256) {
        return stakes[_stakeholder] / 100;
    }

    // distribute rewards should be every period
    // require owner to distribute
    // note owner has to manually call this function every period
    function distReward() public {
        require(
            hasRole(OWNER_ROLE, msg.sender),
            "Only owner can distribute rewards"
        );
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            address stakeholder = stakeholders[s];
            uint256 reward = calcReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    // withdraw mok when stakeholder wants to get their reward
    // reset their rewards to 0
    function withdrawReward() public {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        mok.transfer(msg.sender, reward);
    }
}

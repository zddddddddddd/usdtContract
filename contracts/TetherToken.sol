// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./SafeMath.sol";

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

/**
 * @title BlackList
 * @dev Base contract which allows to blacklist accounts.
 */
contract BlackList is Ownable {
    mapping(address => bool) public isBlackListed;

    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
}

/**
 * @title Standard TRC20 Token
 * Implementation of the basic standard token with fees functionality.
 */
contract StandardToken is ITRC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal _totalSupply;

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(_to != address(0), "StandardToken: transfer to the zero address");
        require(_value <= balances[msg.sender], "StandardToken: transfer amount exceeds balance");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(_to != address(0), "StandardToken: transfer to the zero address");
        require(_value <= balances[_from], "StandardToken: transfer amount exceeds balance");
        require(_value <= allowed[_from][msg.sender], "StandardToken: transfer amount exceeds allowance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public virtual override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public virtual returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public virtual returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

/**
 * @title StandardTokenWithFees
 * @dev StandardToken with fee functionality.
 */
contract StandardTokenWithFees is StandardToken, Ownable {
    using SafeMath for uint256;

    // Additional variables for use if transaction fees ever became necessary
    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;
    uint256 constant MAX_SETTABLE_BASIS_POINTS = 20;
    uint256 constant MAX_SETTABLE_FEE = 50;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint public constant MAX_UINT = 2 ** 256 - 1;

    function calcFee(uint _value) public view returns (uint) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        return fee;
    }

    function transfer(address _to, uint _value) public virtual override returns (bool) {
        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        super.transfer(_to, sendAmount);
        if (fee > 0) {
            super.transfer(owner, fee);
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
        require(_to != address(0), "StandardTokenWithFees: transfer to the zero address");
        require(_value <= balances[_from], "StandardTokenWithFees: transfer amount exceeds balance");
        require(_value <= allowed[_from][msg.sender], "StandardTokenWithFees: transfer amount exceeds allowance");

        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (allowed[_from][msg.sender] < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        return true;
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < MAX_SETTABLE_BASIS_POINTS, "StandardTokenWithFees: basis points exceeds maximum");
        require(newMaxFee < MAX_SETTABLE_FEE, "StandardTokenWithFees: fee exceeds maximum");

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(uint(10) ** decimals);

        emit Params(basisPointsRate, maximumFee);
    }

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);
}

/**
 * @title UpgradedStandardToken
 * @dev Contract that allows interaction with token after upgrade.
 */
interface UpgradedStandardToken {
    // those methods are called by the legacy contract
    function transferByLegacy(address from, address to, uint value) external returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint value) external returns (bool);
    function approveByLegacy(address from, address spender, uint value) external returns (bool);
    function increaseApprovalByLegacy(address from, address spender, uint addedValue) external returns (bool);
    function decreaseApprovalByLegacy(address from, address spender, uint subtractedValue) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

/**
 * @title Tether Token
 * @dev TRC20 Token that can be irreversibly upgraded.
 */
contract TetherToken is Pausable, StandardTokenWithFees, BlackList {
    using SafeMath for uint256;
    
    address public upgradedAddress;
    bool public deprecated;

    // Called when new token are issued
    event Issue(uint amount);
    // Called when tokens are redeemed
    event Redeem(uint amount);
    // Called when contract is deprecated
    event Deprecate(address newAddress);
    // Called when funds are destroyed from blacklist
    event DestroyedBlackFunds(address indexed _blackListedUser, uint _balance);

    /**
     * @dev Constructor to initialize the token
     * @param _initialSupply Initial supply of the contract
     * @param _name Token Name
     * @param _symbol Token symbol
     * @param _decimals Token decimals
     */
    constructor(uint _initialSupply, string memory _name, string memory _symbol, uint8 _decimals) {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    /**
     * @dev Forward ERC20 methods to upgraded contract if this one is deprecated
     */
    function transfer(address _to, uint _value) public override(StandardTokenWithFees) whenNotPaused returns (bool) {
        require(!isBlackListed[msg.sender], "TetherToken: sender is blacklisted");
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    /**
     * @dev Forward ERC20 methods to upgraded contract if this one is deprecated
     */
    function transferFrom(address _from, address _to, uint _value) public override(StandardTokenWithFees) whenNotPaused returns (bool) {
        require(!isBlackListed[_from], "TetherToken: sender is blacklisted");
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    /**
     * @dev Forward ERC20 methods to upgraded contract if this one is deprecated
     */
    function balanceOf(address who) public view override(StandardToken) returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    /**
     * @dev Allow checks of balance at time of deprecation
     */
    function oldBalanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return super.balanceOf(who);
        }
        return 0;
    }

    /**
     * @dev Forward ERC20 methods to upgraded contract if this one is deprecated
     */
    function approve(address _spender, uint _value) public override(StandardToken) whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    /**
     * @dev Forward ERC20 methods to upgraded contract if this one is deprecated
     */
    function increaseApproval(address _spender, uint _addedValue) public override(StandardToken) whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).increaseApprovalByLegacy(msg.sender, _spender, _addedValue);
        } else {
            return super.increaseApproval(_spender, _addedValue);
        }
    }

    /**
     * @dev Forward ERC20 methods to upgraded contract if this one is deprecated
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public override(StandardToken) whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).decreaseApprovalByLegacy(msg.sender, _spender, _subtractedValue);
        } else {
            return super.decreaseApproval(_spender, _subtractedValue);
        }
    }

    /**
     * @dev Forward ERC20 methods to upgraded contract if this one is deprecated
     */
    function allowance(address _owner, address _spender) public view override(StandardToken) returns (uint remaining) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    /**
     * @dev Deprecate current contract in favour of a new one
     */
    function deprecate(address _upgradedAddress) public onlyOwner {
        require(_upgradedAddress != address(0), "TetherToken: upgraded address is zero");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    /**
     * @dev Get total token supply
     */
    function totalSupply() public view override(StandardToken) returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    /**
     * @dev Issue a new amount of tokens
     * @param amount Number of tokens to be issued
     */
    function issue(uint amount) public onlyOwner {
        require(!deprecated, "TetherToken: token is deprecated");
        balances[owner] = balances[owner].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Issue(amount);
        emit Transfer(address(0), owner, amount);
    }

    /**
     * @dev Redeem tokens
     * @param amount Number of tokens to be redeemed
     */
    function redeem(uint amount) public onlyOwner {
        require(!deprecated, "TetherToken: token is deprecated");
        require(balances[owner] >= amount, "TetherToken: redeem amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
        emit Redeem(amount);
        emit Transfer(owner, address(0), amount);
    }

    /**
     * @dev Destroy blacklisted user funds
     * @param _blackListedUser Address of blacklisted user
     */
    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser], "TetherToken: account is not blacklisted");
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
} 
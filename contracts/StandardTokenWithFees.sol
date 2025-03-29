// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract StandardTokenWithFees is StandardToken, Ownable {
    using SafeMath for uint256;
    
    // Additional variables for use if transaction fees ever became necessary
    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;
    uint256 constant MAX_SETTABLE_BASIS_POINTS = 20;
    uint256 constant MAX_SETTABLE_FEE = 50;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    uint public constant MAX_UINT = 2 ** 256 - 1;

    function calcFee(uint _value) public view returns (uint) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        return fee;
    }

    function transfer(address _to, uint _value) public virtual override(BasicToken, ERC20Basic) returns (bool) {
        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        super.transfer(_to, sendAmount);
        if (fee > 0) {
            super.transfer(owner, fee);
        }
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override(StandardToken) returns (bool) {
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

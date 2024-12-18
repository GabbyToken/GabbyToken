// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts@5.1.0/access/Ownable.sol";

contract Gabby is ERC20, Ownable {
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
    address public marketAddress = address(0x3c9666f7BA4EFf024fa8E79bCFfbBd330c13d6CA);
    address public liquidityPool;

    uint256 public rewardFee = 1;
    uint256 public burnFee = 1;
    uint256 public marketFee = 1;
    uint256 public totalFee = rewardFee + burnFee + marketFee;

    mapping(address => bool) private _isHolder;
    address[] private _holders;

    constructor() ERC20("Gabby", "Gabby") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
        _addHolder(msg.sender);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        
        if (liquidityPool == address(0) && _isContract(recipient)) {
            liquidityPool = recipient;
        }

        uint256 feeAmount;
        uint256 transferAmount;

        if (_msgSender() == liquidityPool) {
            
            feeAmount = (amount * totalFee) / 100;
            transferAmount = amount - feeAmount;
        } else if (recipient == liquidityPool) {
            
            feeAmount = (amount * totalFee) / 100;
            transferAmount = amount - feeAmount;
        } else {
            
            feeAmount = (amount * totalFee) / 100;
            transferAmount = amount - feeAmount;
        }

        
        uint256 burnAmount = (amount * burnFee) / 100;
        uint256 marketAmount = (amount * marketFee) / 100;
        uint256 rewardAmount = feeAmount - burnAmount - marketAmount;

        if (burnAmount > 0) super.transfer(burnAddress, burnAmount);
        if (marketAmount > 0) super.transfer(marketAddress, marketAmount);
        if (rewardAmount > 0) _distributeReward(rewardAmount);

        
        bool success = super.transfer(recipient, transferAmount);

        
        _updateHolders(_msgSender());
        _updateHolders(recipient);

        return success;
    }

    function _distributeReward(uint256 rewardAmount) private {
        uint256 totalSupplyExcludingBurn = totalSupply() - balanceOf(burnAddress);
        if (totalSupplyExcludingBurn == 0 || rewardAmount == 0) {
            return;
        }

        for (uint256 i = 0; i < _holders.length; i++) {
            address holder = _holders[i];
            if (balanceOf(holder) > 0) {
                uint256 holderReward = (rewardAmount * balanceOf(holder)) / totalSupplyExcludingBurn;
                super.transfer(holder, holderReward);
            }
        }
    }

    function _updateHolders(address account) private {
        if (balanceOf(account) > 0 && !_isHolder[account]) {
            _addHolder(account);
        } else if (balanceOf(account) == 0 && _isHolder[account]) {
            _removeHolder(account);
        }
    }

    function _addHolder(address account) private {
        _holders.push(account);
        _isHolder[account] = true;
    }

    function _removeHolder(address account) private {
        _isHolder[account] = false;
        for (uint256 i = 0; i < _holders.length; i++) {
            if (_holders[i] == account) {
                _holders[i] = _holders[_holders.length - 1];
                _holders.pop();
                break;
            }
        }
    }

    function holderAt(uint256 index) public view returns (address) {
        require(index < _holders.length, "Index out of bounds");
        return _holders[index];
    }

    function totalHolders() public view returns (uint256) {
        return _holders.length;
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

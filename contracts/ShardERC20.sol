// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract ShardERC20 is Context, IERC20Errors, IERC20 {

    uint16 public constant SLOTS_NUM = 16;
    
    mapping(address => uint256[SLOTS_NUM]) private _slotsBalance;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 sum = 0;
        for (uint16 i = 0; i < SLOTS_NUM; i++) {
            sum += _slotsBalance[account][i];
        }
        return sum;
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint16 fromSlot = (uint16)(uint160(to) & (SLOTS_NUM - 1));
            if (_slotsBalance[from][fromSlot] < value) {
                uint256 currentBalance = _slotsBalance[from][fromSlot];
                _slotsBalance[from][fromSlot] = 0;
                uint16 indexSlot = fromSlot + 1;
                while (indexSlot != fromSlot) {
                    if (currentBalance + _slotsBalance[from][indexSlot] < value) {
                        currentBalance += _slotsBalance[from][indexSlot];
                        _slotsBalance[from][indexSlot] = 0;
                        indexSlot = (indexSlot + 1) % SLOTS_NUM;
                    } else {
                        _slotsBalance[from][indexSlot] -= value - currentBalance;
                        break;
                    }
                }
                if (indexSlot == fromSlot) {
                    revert ERC20InsufficientBalance(from, currentBalance, value);
                }
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            uint16 toSlot = (uint16)(uint160(from) & (SLOTS_NUM - 1));
            unchecked {
                _slotsBalance[to][toSlot] += value;
            }
        }
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}


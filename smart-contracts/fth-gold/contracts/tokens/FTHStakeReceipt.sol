// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {AccessRoles} from "../access/AccessRoles.sol";
contract FTHStakeReceipt is ERC20, AccessRoles {
    mapping(address => bool) public transferable;
    constructor(address admin) ERC20("FTH Stake Receipt","FTH-SR"){
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
    }
    function mint(address to, uint256 amount) external onlyRole(ISSUER_ROLE){ _mint(to, amount); }
    function burn(address from, uint256 amount) external onlyRole(ISSUER_ROLE){ _burn(from, amount); }
    function setTransferable(address a, bool t) external onlyRole(DEFAULT_ADMIN_ROLE){ transferable[a]=t; }
    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && !transferable[from]) revert("NON_TRANSFERABLE");
        super._update(from, to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";

contract FTHG is ERC20, AccessControl, IERC20Mintable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
    bool    public paused;

    event Paused(bool state);

    constructor() ERC20("FTH-Gold", "FTHG") { 
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); 
    }

    function pause(bool p) external onlyRole(DEFAULT_ADMIN_ROLE) { 
        paused = p; 
        emit Paused(p); 
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(!paused, "paused");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}
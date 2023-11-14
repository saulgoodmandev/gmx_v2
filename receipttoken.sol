// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPToken is ERC20, Ownable{
    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) ERC20(name_, symbol_) {}

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }
}

contract LPTokenFactory is Ownable {
    address public manager;

    event LPTokenCreated(address indexed tokenAddress, string name, string symbol);

    constructor(address manager_) Ownable(msg.sender) {
        manager = manager_;
    }

    function createLPToken(string memory name, string memory symbol) external onlyOwner returns (address) {
        LPToken newLPToken = new LPToken(name, symbol);
        newLPToken.transferOwnership(manager);
        emit LPTokenCreated(address(newLPToken), name, symbol);
        return address(newLPToken);
    }

    function setManager(address manager_) external onlyOwner {
        manager = manager_;
    }
}

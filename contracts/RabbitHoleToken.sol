// contracts/RabbitHoleToken.sol
// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RabbitHoleToken is ERC20, Ownable {

    uint256 public constant INITIAL_SUPPLY = 100_000_000;

    constructor() ERC20("Rabbit Hole Token", "RBTHL") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

    function mint(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }
}
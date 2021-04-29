//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma abicoder v2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";

contract FTXFToken is ERC20("FTXFUND", "FTXF"), ERC20Burnable, Ownable {
    using SafeMath for uint256;

    constructor(address owner) {
        transferOwnership(owner);
    }

    function mint(address to, uint256 amount) public onlyOwner {
       _mint(to,amount);
    }

}
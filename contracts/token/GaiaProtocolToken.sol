// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GaiaProtocolToken is ERC20 {
    uint256 private constant INITIAL_SUPPLY = 100_000_000;
    uint8 private constant DECIMALS = 18;

    constructor() ERC20("Gaia Protocol", "GAIA") {
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** DECIMALS);
    }
}

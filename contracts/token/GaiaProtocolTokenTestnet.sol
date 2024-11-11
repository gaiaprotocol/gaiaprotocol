// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GaiaProtocolTokenTestnet is ERC20 {
    uint8 private constant DECIMALS = 18;

    constructor() ERC20("Gaia Protocol", "GAIA") {}

    function mint(uint256 amount) external {
        require(amount <= 10_000, "GaiaProtocolTokenTestnet: max mint amount is 10,000");
        _mint(msg.sender, amount);
    }
}

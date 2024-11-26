// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ClanEmblems is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;
}

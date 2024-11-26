// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PersonaFragments is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    uint256 public priceIncrement;
    uint256 public protocolFeePercent;
    uint256 public personaOwnerFeePercent;
    address payable public protocolFeeDestination;

    event SetProtocolFeeDestination(address indexed destination);
    event SetProtocolFeePercent(uint256 percent);
    event SetPersonaOwnerFeePercent(uint256 percent);

    //TODO:
}

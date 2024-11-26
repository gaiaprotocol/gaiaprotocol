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

    mapping(address => mapping(address => uint256)) public balance;
    mapping(address => uint256) public supply;

    event SetProtocolFeeDestination(address indexed destination);
    event SetProtocolFeePercent(uint256 percent);
    event SetPersonaOwnerFeePercent(uint256 percent);
    event Trade(
        address indexed trader,
        address indexed persona,
        bool indexed isBuy,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 personaOwnerFee,
        uint256 supply
    );

    function initialize(
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _personaOwnerFeePercent,
        uint256 _priceIncrementPerFragment
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        personaOwnerFeePercent = _personaOwnerFeePercent;
        priceIncrement = _priceIncrementPerFragment;

        emit SetProtocolFeeDestination(_protocolFeeDestination);
        emit SetProtocolFeePercent(_protocolFeePercent);
        emit SetPersonaOwnerFeePercent(_personaOwnerFeePercent);
    }

    function setProtocolFeeDestination(address payable _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
        emit SetProtocolFeeDestination(_feeDestination);
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
        emit SetProtocolFeePercent(_feePercent);
    }

    function setPersonaOwnerFeePercent(uint256 _feePercent) public onlyOwner {
        personaOwnerFeePercent = _feePercent;
        emit SetPersonaOwnerFeePercent(_feePercent);
    }

    function getPrice(uint256 _supply, uint256 amount) public view returns (uint256) {
        uint256 startPriceWei = priceIncrement + (_supply * priceIncrement) / 1e18;

        uint256 endSupply = _supply + amount;
        if (endSupply >= 1e18) {
            endSupply -= 1e18;
        } else {
            endSupply = 0;
        }

        uint256 endPriceWei = priceIncrement + (endSupply * priceIncrement) / 1e18;

        uint256 averagePriceWei = (startPriceWei + endPriceWei) / 2;
        uint256 totalCostWei = (averagePriceWei * amount) / 1e18;

        return totalCostWei;
    }

    function getBuyPrice(address persona, uint256 amount) public view returns (uint256) {
        return getPrice(supply[persona], amount);
    }

    function getSellPrice(address persona, uint256 amount) public view returns (uint256) {
        uint256 supplyAfterSale = supply[persona] - amount;
        return getPrice(supplyAfterSale, amount);
    }

    function getBuyPriceAfterFee(address persona, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(persona, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 personaOwnerFee = (price * personaOwnerFeePercent) / 1e18;
        return price + protocolFee + personaOwnerFee;
    }

    function getSellPriceAfterFee(address persona, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(persona, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 personaOwnerFee = (price * personaOwnerFeePercent) / 1e18;
        return price - protocolFee - personaOwnerFee;
    }

    function executeTrade(address persona, uint256 amount, uint256 price, bool isBuy) private nonReentrant {
        uint256 personaOwnerFee = (price * personaOwnerFeePercent) / 1e18;
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;

        if (isBuy) {
            require(msg.value >= price + protocolFee + personaOwnerFee, "Insufficient payment");
            balance[persona][msg.sender] += amount;
            supply[persona] += amount;
            protocolFeeDestination.sendValue(protocolFee);
            payable(persona).sendValue(personaOwnerFee);
            if (msg.value > price + protocolFee + personaOwnerFee) {
                uint256 refund = msg.value - price - protocolFee - personaOwnerFee;
                payable(msg.sender).sendValue(refund);
            }
        } else {
            require(balance[persona][msg.sender] >= amount, "Insufficient balance");
            balance[persona][msg.sender] -= amount;
            supply[persona] -= amount;
            uint256 netAmount = price - protocolFee - personaOwnerFee;
            payable(msg.sender).sendValue(netAmount);
            protocolFeeDestination.sendValue(protocolFee);
            payable(persona).sendValue(personaOwnerFee);
        }

        emit Trade(msg.sender, persona, isBuy, amount, price, protocolFee, personaOwnerFee, supply[persona]);
    }

    function buy(address persona, uint256 amount) external payable {
        uint256 price = getBuyPrice(persona, amount);
        executeTrade(persona, amount, price, true);
    }

    function sell(address persona, uint256 amount) external {
        uint256 price = getSellPrice(persona, amount);
        executeTrade(persona, amount, price, false);
    }
}

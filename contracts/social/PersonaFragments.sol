// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HoldingRewardsBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PersonaFragments is HoldingRewardsBase {
    using Address for address payable;

    uint256 public priceIncrementPerFragment;
    uint256 public personaOwnerFeeRate;

    mapping(address => mapping(address => uint256)) public balance;
    mapping(address => uint256) public supply;

    event PersonaOwnerFeeRateUpdated(uint256 rate);
    event TradeExecuted(
        address indexed trader,
        address indexed persona,
        bool indexed isBuy,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 personaFee,
        uint256 holdingReward,
        uint256 supply
    );

    function initialize(
        address payable _treasury,
        uint256 _protocolFeeRate,
        uint256 _personaOwnerFeeRate,
        uint256 _priceIncrementPerFragment,
        address _holdingVerifier
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        require(_treasury != address(0), "Invalid treasury");
        require(_holdingVerifier != address(0), "Invalid verifier");

        treasury = _treasury;
        protocolFeeRate = _protocolFeeRate;
        personaOwnerFeeRate = _personaOwnerFeeRate;
        priceIncrementPerFragment = _priceIncrementPerFragment;
        holdingVerifier = _holdingVerifier;

        emit TreasuryUpdated(_treasury);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
        emit PersonaOwnerFeeRateUpdated(_personaOwnerFeeRate);
        emit HoldingVerifierUpdated(_holdingVerifier);
    }

    function setPersonaOwnerFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        personaOwnerFeeRate = _rate;
        emit PersonaOwnerFeeRateUpdated(_rate);
    }

    function getPrice(uint256 _supply, uint256 amount) public view returns (uint256) {
        uint256 startPriceWei = priceIncrementPerFragment + (_supply * priceIncrementPerFragment);
        uint256 endSupply = _supply + amount;
        uint256 endPriceWei = priceIncrementPerFragment + (endSupply * priceIncrementPerFragment);
        uint256 averagePriceWei = (startPriceWei + endPriceWei) / 2;
        uint256 totalCostWei = averagePriceWei * amount;
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
        uint256 protocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 personaFee = (price * personaOwnerFeeRate) / 1 ether;
        return price + protocolFee + personaFee;
    }

    function getSellPriceAfterFee(address persona, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(persona, amount);
        uint256 protocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 personaFee = (price * personaOwnerFeeRate) / 1 ether;
        return price - protocolFee - personaFee;
    }

    function executeTrade(
        address persona,
        uint256 amount,
        uint256 price,
        bool isBuy,
        bytes memory holdingRewardSignature
    ) private nonReentrant {
        uint256 holdingReward = calculateHoldingReward((price * protocolFeeRate) / 1 ether, holdingRewardSignature);
        uint256 protocolFee = ((price * protocolFeeRate) / 1 ether) - holdingReward;
        uint256 personaFee = ((price * personaOwnerFeeRate) / 1 ether) + holdingReward;

        if (isBuy) {
            require(msg.value >= price + protocolFee + personaFee, "Insufficient payment");
            balance[persona][msg.sender] += amount;
            supply[persona] += amount;
            treasury.sendValue(protocolFee);
            payable(persona).sendValue(personaFee);
            if (msg.value > price + protocolFee + personaFee) {
                payable(msg.sender).sendValue(msg.value - price - protocolFee - personaFee);
            }
        } else {
            require(balance[persona][msg.sender] >= amount, "Insufficient balance");
            balance[persona][msg.sender] -= amount;
            supply[persona] -= amount;
            payable(msg.sender).sendValue(price - protocolFee - personaFee);
            treasury.sendValue(protocolFee);
            payable(persona).sendValue(personaFee);
        }

        emit TradeExecuted(msg.sender, persona, isBuy, amount, price, protocolFee, personaFee, holdingReward, supply[persona]);
    }

    function buy(address persona, uint256 amount, bytes memory holdingRewardSignature) external payable {
        uint256 price = getBuyPrice(persona, amount);
        executeTrade(persona, amount, price, true, holdingRewardSignature);
    }

    function sell(address persona, uint256 amount, bytes memory holdingRewardSignature) external {
        uint256 price = getSellPrice(persona, amount);
        executeTrade(persona, amount, price, false, holdingRewardSignature);
    }
}

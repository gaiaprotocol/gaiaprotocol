// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Address.sol";
import "./HoldingRewardsBase.sol";
import "../libraries/PricingLib.sol";

contract ClanEmblems is HoldingRewardsBase {
    using Address for address payable;

    uint256 public priceIncrementPerEmblem;
    uint256 public clanFeeRate;

    struct Clan {
        address owner;
        uint256 accumulatedFees;
    }

    uint256 public nextClanId;
    mapping(uint256 => Clan) public clans;
    mapping(uint256 => mapping(address => uint256)) public balance;
    mapping(uint256 => uint256) public supply;

    event ClanFeeRateUpdated(uint256 rate);
    event ClanCreated(address indexed clanOwner, uint256 indexed clanId, bytes32 metadataHash);
    event ClanDeleted(uint256 indexed clanId);
    event ClanOwnershipTransferred(uint256 indexed clanId, address indexed previousOwner, address indexed newOwner);
    event FeesWithdrawn(uint256 indexed clanId, uint256 amount);
    event TradeExecuted(
        address indexed trader,
        uint256 indexed clanId,
        bool indexed isBuy,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 clanFee,
        uint256 holdingReward,
        uint256 supply
    );

    function initialize(
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeRate,
        uint256 _clanFeeRate,
        uint256 _priceIncrementPerEmblem,
        address _holdingVerifier
    ) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient");
        require(_holdingVerifier != address(0), "Invalid verifier address");

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;
        clanFeeRate = _clanFeeRate;
        priceIncrementPerEmblem = _priceIncrementPerEmblem;
        holdingVerifier = _holdingVerifier;

        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
        emit ClanFeeRateUpdated(_clanFeeRate);
        emit HoldingVerifierUpdated(_holdingVerifier);
    }

    function setClanFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        clanFeeRate = _rate;
        emit ClanFeeRateUpdated(_rate);
    }

    function createClan(bytes32 metadataHash) external returns (uint256 clanId) {
        clanId = nextClanId++;
        clans[clanId].owner = msg.sender;
        emit ClanCreated(msg.sender, clanId, metadataHash);
    }

    function deleteClan(uint256 clanId) external {
        require(clans[clanId].owner == msg.sender, "Not clan owner");
        require(supply[clanId] == 0, "Supply must be zero");
        require(clans[clanId].accumulatedFees == 0, "Must withdraw fees first");

        delete clans[clanId];
        emit ClanDeleted(clanId);
    }

    function transferClanOwnership(uint256 clanId, address newOwner) external {
        require(clans[clanId].owner == msg.sender, "Not clan owner");
        require(newOwner != address(0), "Invalid new owner");
        address previousOwner = clans[clanId].owner;
        clans[clanId].owner = newOwner;
        emit ClanOwnershipTransferred(clanId, previousOwner, newOwner);
    }

    function withdrawFees(uint256 clanId) external {
        require(clans[clanId].owner == msg.sender, "Not clan owner");
        uint256 amount = clans[clanId].accumulatedFees;
        require(amount > 0, "No fees to withdraw");
        clans[clanId].accumulatedFees = 0;
        payable(msg.sender).sendValue(amount);
        emit FeesWithdrawn(clanId, amount);
    }

    function getPrice(uint256 _supply, uint256 amount) public view returns (uint256) {
        return PricingLib.getPrice(_supply, amount, priceIncrementPerEmblem, 1);
    }

    function getBuyPrice(uint256 clanId, uint256 amount) public view returns (uint256) {
        return PricingLib.getBuyPrice(supply[clanId], amount, priceIncrementPerEmblem, 1);
    }

    function getSellPrice(uint256 clanId, uint256 amount) public view returns (uint256) {
        return PricingLib.getSellPrice(supply[clanId], amount, priceIncrementPerEmblem, 1);
    }

    function getBuyPriceAfterFee(uint256 clanId, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(clanId, amount);
        uint256 protocolFee = ((price * protocolFeeRate) / 1 ether);
        uint256 clanFee = ((price * clanFeeRate) / 1 ether);
        return price + protocolFee + clanFee;
    }

    function getSellPriceAfterFee(uint256 clanId, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(clanId, amount);
        uint256 protocolFee = ((price * protocolFeeRate) / 1 ether);
        uint256 clanFee = ((price * clanFeeRate) / 1 ether);
        return price - protocolFee - clanFee;
    }

    function executeTrade(
        uint256 clanId,
        uint256 amount,
        uint256 price,
        bool isBuy,
        uint256 rewardRatio,
        bytes memory holdingRewardSignature
    ) private nonReentrant {
        require(clans[clanId].owner != address(0), "Clan does not exist");

        uint256 rawProtocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 holdingReward = calculateHoldingReward(rawProtocolFee, rewardRatio, holdingRewardSignature);
        uint256 protocolFee = rawProtocolFee - holdingReward;
        uint256 clanFee = ((price * clanFeeRate) / 1 ether) + holdingReward;

        if (isBuy) {
            require(msg.value >= price + protocolFee + clanFee, "Insufficient payment");
            balance[clanId][msg.sender] += amount;
            supply[clanId] += amount;
            protocolFeeRecipient.sendValue(protocolFee);
            clans[clanId].accumulatedFees += clanFee;
            if (msg.value > price + protocolFee + clanFee) {
                payable(msg.sender).sendValue(msg.value - price - protocolFee - clanFee);
            }
        } else {
            require(balance[clanId][msg.sender] >= amount, "Insufficient balance");
            balance[clanId][msg.sender] -= amount;
            supply[clanId] -= amount;
            payable(msg.sender).sendValue(price - protocolFee - clanFee);
            protocolFeeRecipient.sendValue(protocolFee);
            clans[clanId].accumulatedFees += clanFee;
        }

        emit TradeExecuted(
            msg.sender,
            clanId,
            isBuy,
            amount,
            price,
            protocolFee,
            clanFee,
            holdingReward,
            supply[clanId]
        );
    }

    function buy(
        uint256 clanId,
        uint256 amount,
        uint256 rewardRatio,
        bytes memory holdingRewardSignature
    ) external payable {
        uint256 price = getBuyPrice(clanId, amount);
        executeTrade(clanId, amount, price, true, rewardRatio, holdingRewardSignature);
    }

    function sell(uint256 clanId, uint256 amount, uint256 rewardRatio, bytes memory holdingRewardSignature) external {
        uint256 price = getSellPrice(clanId, amount);
        executeTrade(clanId, amount, price, false, rewardRatio, holdingRewardSignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./HoldingRewardsBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TopicShares is HoldingRewardsBase {
    using Address for address payable;

    uint256 private constant ACC_FEE_PRECISION = 1e4;
    uint256 public priceIncrementPerShare;
    uint256 public holderFeeRate;

    struct Topic {
        uint256 supply;
        uint256 accFeePerUnit;
    }

    struct Holder {
        uint256 balance;
        int256 feeDebt;
    }

    mapping(bytes32 => Topic) public topics;
    mapping(bytes32 => mapping(address => Holder)) public holders;

    event HolderFeeRateUpdated(uint256 rate);
    event Trade(
        address indexed trader,
        bytes32 indexed topic,
        bool indexed isBuy,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 holderFee,
        uint256 holdingReward,
        uint256 supply
    );
    event ClaimHolderFee(address indexed holder, bytes32 indexed topic, uint256 fee);

    function initialize(
        address payable _treasury,
        uint256 _protocolFeeRate,
        uint256 _holderFeeRate,
        uint256 _priceIncrementPerShare,
        uint256 _baseDivider,
        address _holdingVerifier
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        require(_treasury != address(0), "Invalid treasury");
        require(_holdingVerifier != address(0), "Invalid verifier");

        treasury = _treasury;
        protocolFeeRate = _protocolFeeRate;
        holderFeeRate = _holderFeeRate;
        priceIncrementPerShare = _priceIncrementPerShare;
        baseDivider = _baseDivider;
        holdingVerifier = _holdingVerifier;

        emit TreasuryUpdated(_treasury);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
        emit HolderFeeRateUpdated(_holderFeeRate);
        emit HoldingVerifierUpdated(_holdingVerifier);
    }

    function setHolderFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        holderFeeRate = _rate;
        emit HolderFeeRateUpdated(_rate);
    }

    function getPrice(uint256 _supply, uint256 amount) public view returns (uint256) {
        uint256 startPriceWei = priceIncrementPerShare + (_supply * priceIncrementPerShare);
        uint256 endSupply = _supply + amount;
        uint256 endPriceWei = priceIncrementPerShare + (endSupply * priceIncrementPerShare);
        uint256 averagePriceWei = (startPriceWei + endPriceWei) / 2;
        uint256 totalCostWei = averagePriceWei * amount;
        return totalCostWei;
    }

    function getBuyPrice(bytes32 topic, uint256 amount) public view returns (uint256) {
        return getPrice(topics[topic].supply, amount);
    }

    function getSellPrice(bytes32 topic, uint256 amount) public view returns (uint256) {
        return getPrice(topics[topic].supply - amount, amount);
    }

    function getBuyPriceAfterFee(bytes32 topic, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(topic, amount);
        uint256 protocolFee = ((price * protocolFeeRate) / 1 ether);
        uint256 holderFee = ((price * holderFeeRate) / 1 ether);
        return price + protocolFee + holderFee;
    }

    function getSellPriceAfterFee(bytes32 topic, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(topic, amount);
        uint256 protocolFee = ((price * protocolFeeRate) / 1 ether);
        uint256 holderFee = ((price * holderFeeRate) / 1 ether);
        return price - protocolFee - holderFee;
    }

    function buy(bytes32 topic, uint256 amount, bytes memory holdingRewardSignature) external payable nonReentrant {
        uint256 price = getBuyPrice(topic, amount);
        uint256 holdingReward = calculateHoldingReward((price * protocolFeeRate) / 1 ether, holdingRewardSignature);
        uint256 protocolFee = ((price * protocolFeeRate) / 1 ether) - holdingReward;
        uint256 holderFee = ((price * holderFeeRate) / 1 ether) + holdingReward;

        require(msg.value >= price + protocolFee + holderFee, "Insufficient payment");

        Topic memory t = topics[topic];
        Holder storage holder = holders[topic][msg.sender];

        holder.balance += amount;
        holder.feeDebt += int256((amount * t.accFeePerUnit) / ACC_FEE_PRECISION);

        t.supply += amount;
        t.accFeePerUnit += (holderFee * ACC_FEE_PRECISION) / t.supply;
        topics[topic] = t;

        treasury.sendValue(protocolFee);
        if (msg.value > price + protocolFee + holderFee) {
            payable(msg.sender).sendValue(msg.value - price - protocolFee - holderFee);
        }

        emit Trade(msg.sender, topic, true, amount, price, protocolFee, holderFee, holdingReward, t.supply);
    }

    function sell(bytes32 topic, uint256 amount, bytes memory holdingRewardSignature) external nonReentrant {
        uint256 price = getSellPrice(topic, amount);
        uint256 holdingReward = calculateHoldingReward((price * protocolFeeRate) / 1 ether, holdingRewardSignature);
        uint256 protocolFee = ((price * protocolFeeRate) / 1 ether) - holdingReward;
        uint256 holderFee = ((price * holderFeeRate) / 1 ether) + holdingReward;

        Topic memory t = topics[topic];
        Holder storage holder = holders[topic][msg.sender];

        require(holder.balance >= amount, "Insufficient balance");

        t.accFeePerUnit += (holderFee * ACC_FEE_PRECISION) / t.supply;
        t.supply -= amount;
        topics[topic] = t;

        holder.balance -= amount;
        holder.feeDebt -= int256((amount * t.accFeePerUnit) / ACC_FEE_PRECISION);

        payable(msg.sender).sendValue(price - protocolFee - holderFee);
        treasury.sendValue(protocolFee);

        emit Trade(msg.sender, topic, false, amount, price, protocolFee, holderFee, holdingReward, t.supply);
    }

    function claimableHolderFee(bytes32 topic, address holder) public view returns (uint256 claimableFee) {
        Topic memory t = topics[topic];
        Holder memory h = holders[topic][holder];
        int256 accumulatedFee = int256((h.balance * t.accFeePerUnit) / ACC_FEE_PRECISION);
        claimableFee = uint256(accumulatedFee - h.feeDebt);
    }

    function _claimHolderFee(bytes32 topic) private {
        Topic memory t = topics[topic];
        Holder storage holder = holders[topic][msg.sender];
        int256 accumulatedFee = int256((holder.balance * t.accFeePerUnit) / ACC_FEE_PRECISION);
        uint256 claimableFee = uint256(accumulatedFee - holder.feeDebt);
        holder.feeDebt = accumulatedFee;
        payable(msg.sender).sendValue(claimableFee);
        emit ClaimHolderFee(msg.sender, topic, claimableFee);
    }

    function claimHolderFee(bytes32 topic) external nonReentrant {
        _claimHolderFee(topic);
    }

    function batchClaimableHolderFees(
        bytes32[] memory _topics,
        address holder
    ) external view returns (uint256[] memory claimableFees) {
        claimableFees = new uint256[](_topics.length);
        for (uint256 i = 0; i < _topics.length; i++) {
            claimableFees[i] = claimableHolderFee(_topics[i], holder);
        }
    }

    function batchClaimHolderFees(bytes32[] memory _topics) external nonReentrant {
        for (uint256 i = 0; i < _topics.length; i++) {
            _claimHolderFee(_topics[i]);
        }
    }
}

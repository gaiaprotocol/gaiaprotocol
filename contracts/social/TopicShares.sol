// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TopicShares is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    uint256 private constant ACC_FEE_PRECISION = 1e4;
    uint256 public holderFeePercent;

    struct Hashtag {
        uint256 supply;
        uint256 accFeePerUnit;
    }

    struct Holder {
        uint256 balance;
        int256 feeDebt;
    }

    mapping(bytes32 => Hashtag) public hashtags;
    mapping(bytes32 => mapping(address => Holder)) public holders;

    event SetHolderFeePercent(uint256 percent);
    event Trade(
        address indexed trader,
        bytes32 indexed hashtag,
        bool indexed isBuy,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 holderFee,
        uint256 additionalFee,
        uint256 supply
    );
    event ClaimHolderFee(address indexed holder, bytes32 indexed hashtag, uint256 fee);

    function initialize(
        uint256 _baseDivider,
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _holderFeePercent
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        baseDivider = _baseDivider;
        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        holderFeePercent = _holderFeePercent;

        emit SetProtocolFeeDestination(_protocolFeeDestination);
        emit SetProtocolFeePercent(_protocolFeePercent);
        emit SetHolderFeePercent(_holderFeePercent);
    }

    function setHolderFeePercent(uint256 _feePercent) external onlyOwner {
        holderFeePercent = _feePercent;
        emit SetHolderFeePercent(_feePercent);
    }

    function getPrice(uint256 supply, uint256 amount) public view returns (uint256) {
        uint256 sum1 = ((supply * (supply + 1)) * (2 * supply + 1)) / 6;
        uint256 sum2 = (((supply + amount) * (supply + 1 + amount)) * (2 * (supply + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / baseDivider;
    }

    function getBuyPrice(bytes32 hashtag, uint256 amount) public view returns (uint256) {
        return getPrice(hashtags[hashtag].supply, amount);
    }

    function getSellPrice(bytes32 hashtag, uint256 amount) public view returns (uint256) {
        return getPrice(hashtags[hashtag].supply - amount, amount);
    }

    function getBuyPriceAfterFee(bytes32 hashtag, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(hashtag, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 holderFee = (price * holderFeePercent) / 1 ether;
        return price + protocolFee + holderFee;
    }

    function getSellPriceAfterFee(bytes32 hashtag, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(hashtag, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 holderFee = (price * holderFeePercent) / 1 ether;
        return price - protocolFee - holderFee;
    }

    function buy(bytes32 hashtag, uint256 amount, bytes memory oracleSignature) external payable nonReentrant {
        uint256 price = getBuyPrice(hashtag, amount);
        uint256 additionalFee = calculateAdditionalTokenOwnerFee(price, oracleSignature);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether - additionalFee;
        uint256 holderFee = (price * holderFeePercent) / 1 ether + additionalFee;

        require(msg.value >= price + protocolFee + holderFee, "Insufficient payment");

        Hashtag memory t = hashtags[hashtag];
        Holder storage holder = holders[hashtag][msg.sender];

        holder.balance += amount;
        holder.feeDebt += int256((amount * t.accFeePerUnit) / ACC_FEE_PRECISION);

        t.supply += amount;
        t.accFeePerUnit += (holderFee * ACC_FEE_PRECISION) / t.supply;
        hashtags[hashtag] = t;

        protocolFeeDestination.sendValue(protocolFee);
        if (msg.value > price + protocolFee + holderFee) {
            uint256 refund = msg.value - price - protocolFee - holderFee;
            payable(msg.sender).sendValue(refund);
        }

        emit Trade(msg.sender, hashtag, true, amount, price, protocolFee, holderFee, additionalFee, t.supply);
    }

    function sell(bytes32 hashtag, uint256 amount, bytes memory oracleSignature) external nonReentrant {
        uint256 price = getSellPrice(hashtag, amount);
        uint256 additionalFee = calculateAdditionalTokenOwnerFee(price, oracleSignature);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether - additionalFee;
        uint256 holderFee = (price * holderFeePercent) / 1 ether + additionalFee;

        Hashtag memory t = hashtags[hashtag];
        Holder storage holder = holders[hashtag][msg.sender];

        t.accFeePerUnit += (holderFee * ACC_FEE_PRECISION) / t.supply;
        t.supply -= amount;
        hashtags[hashtag] = t;

        require(holder.balance >= amount, "Insufficient balance");
        holder.balance -= amount;
        holder.feeDebt -= int256((amount * t.accFeePerUnit) / ACC_FEE_PRECISION);

        uint256 netAmount = price - protocolFee - holderFee;
        payable(msg.sender).sendValue(netAmount);
        protocolFeeDestination.sendValue(protocolFee);

        emit Trade(msg.sender, hashtag, false, amount, price, protocolFee, holderFee, additionalFee, t.supply);
    }

    function claimableHolderFee(bytes32 hashtag, address holder) public view returns (uint256 claimableFee) {
        Hashtag memory t = hashtags[hashtag];
        Holder memory h = holders[hashtag][holder];

        int256 accumulatedFee = int256((h.balance * t.accFeePerUnit) / ACC_FEE_PRECISION);
        claimableFee = uint256(accumulatedFee - h.feeDebt);
    }

    function _claimHolderFee(bytes32 hashtag) private {
        Hashtag memory t = hashtags[hashtag];
        Holder storage holder = holders[hashtag][msg.sender];

        int256 accumulatedFee = int256((holder.balance * t.accFeePerUnit) / ACC_FEE_PRECISION);
        uint256 claimableFee = uint256(accumulatedFee - holder.feeDebt);

        holder.feeDebt = accumulatedFee;

        payable(msg.sender).sendValue(claimableFee);

        emit ClaimHolderFee(msg.sender, hashtag, claimableFee);
    }

    function claimHolderFee(bytes32 hashtag) external nonReentrant {
        _claimHolderFee(hashtag);
    }

    function batchClaimableHolderFees(
        bytes32[] memory _hashtags,
        address holder
    ) external view returns (uint256[] memory claimableFees) {
        claimableFees = new uint256[](_hashtags.length);
        for (uint256 i = 0; i < _hashtags.length; i++) {
            claimableFees[i] = claimableHolderFee(_hashtags[i], holder);
        }
    }

    function batchClaimHolderFees(bytes32[] memory _hashtags) external nonReentrant {
        for (uint256 i = 0; i < _hashtags.length; i++) {
            _claimHolderFee(_hashtags[i]);
        }
    }
}

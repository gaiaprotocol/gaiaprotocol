// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TopicShares is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    struct Topic {
        string name;
        uint256 totalShares;
        uint256 pricePerShare;
        uint256 accFeePerShare;
    }

    mapping(uint256 => Topic) public topics;
    mapping(uint256 => mapping(address => uint256)) public shareBalances;
    mapping(uint256 => mapping(address => int256)) public feeDebts;
    uint256 public topicCount;

    uint256 public priceIncrementPerShare;
    uint256 public protocolFeePercent;

    address payable public protocolFeeDestination;

    event TopicCreated(uint256 indexed topicId, string name);
    event SharesPurchased(address indexed buyer, uint256 indexed topicId, uint256 amount, uint256 price);
    event SharesSold(address indexed seller, uint256 indexed topicId, uint256 amount, uint256 price);
    event FeeClaimed(address indexed claimer, uint256 indexed topicId, uint256 amount);

    function initialize(
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _priceIncrementPerShare
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        priceIncrementPerShare = _priceIncrementPerShare;
    }

    function createTopic(string memory name) external {
        topicCount++;
        topics[topicCount] = Topic({
            name: name,
            totalShares: 0,
            pricePerShare: priceIncrementPerShare,
            accFeePerShare: 0
        });

        emit TopicCreated(topicCount, name);
    }

    function getSharePrice(uint256 topicId, uint256 amount) public view returns (uint256) {
        Topic storage topic = topics[topicId];
        uint256 startPrice = topic.pricePerShare;
        uint256 endPrice = startPrice + (amount * priceIncrementPerShare);
        uint256 averagePrice = (startPrice + endPrice) / 2;
        uint256 totalPrice = averagePrice * amount;
        return totalPrice;
    }

    function buyShares(uint256 topicId, uint256 amount) external payable nonReentrant {
        Topic storage topic = topics[topicId];
        uint256 price = getSharePrice(topicId, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 holderFee = price - protocolFee;

        require(msg.value >= price + protocolFee, "Insufficient payment");

        distributeFees(topicId, holderFee);

        shareBalances[topicId][msg.sender] += amount;
        feeDebts[topicId][msg.sender] += int256(topic.accFeePerShare * amount);
        topic.totalShares += amount;
        topic.pricePerShare += amount * priceIncrementPerShare;

        protocolFeeDestination.sendValue(protocolFee);

        if (msg.value > price + protocolFee) {
            payable(msg.sender).sendValue(msg.value - price - protocolFee);
        }

        emit SharesPurchased(msg.sender, topicId, amount, price);
    }

    function sellShares(uint256 topicId, uint256 amount) external nonReentrant {
        require(shareBalances[topicId][msg.sender] >= amount, "Insufficient shares");

        Topic storage topic = topics[topicId];
        uint256 price = getSharePriceForSelling(topicId, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 holderFee = price - protocolFee;

        shareBalances[topicId][msg.sender] -= amount;
        feeDebts[topicId][msg.sender] -= int256(topic.accFeePerShare * amount);
        topic.totalShares -= amount;
        if (topic.pricePerShare >= amount * priceIncrementPerShare) {
            topic.pricePerShare -= amount * priceIncrementPerShare;
        }

        distributeFees(topicId, holderFee);

        payable(msg.sender).sendValue(price - protocolFee - holderFee);
        protocolFeeDestination.sendValue(protocolFee);

        emit SharesSold(msg.sender, topicId, amount, price);
    }

    function getSharePriceForSelling(uint256 topicId, uint256 amount) public view returns (uint256) {
        return getSharePrice(topicId, amount);
    }

    function distributeFees(uint256 topicId, uint256 fee) internal {
        Topic storage topic = topics[topicId];
        if (topic.totalShares > 0) {
            topic.accFeePerShare += fee / topic.totalShares;
        }
    }

    function claimFees(uint256 topicId) external nonReentrant {
        uint256 claimable = getClaimableFees(topicId, msg.sender);
        require(claimable > 0, "No fees to claim");

        feeDebts[topicId][msg.sender] = int256(shareBalances[topicId][msg.sender] * topics[topicId].accFeePerShare);

        payable(msg.sender).sendValue(claimable);

        emit FeeClaimed(msg.sender, topicId, claimable);
    }

    function getClaimableFees(uint256 topicId, address user) public view returns (uint256) {
        int256 totalEarned = int256(shareBalances[topicId][user] * topics[topicId].accFeePerShare);
        int256 alreadyPaid = feeDebts[topicId][user];
        int256 claimable = totalEarned - alreadyPaid;
        if (claimable < 0) {
            return 0;
        }
        return uint256(claimable);
    }
}

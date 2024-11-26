// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ClanEmblems is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    uint256 public priceIncrement;
    uint256 public protocolFeePercent;
    uint256 public clanFeePercent;
    address payable public protocolFeeDestination;

    struct Clan {
        address owner;
        uint256 accumulatedFees;
    }

    uint256 public nextClanId;
    mapping(uint256 => Clan) public clans;
    mapping(uint256 => mapping(address => uint256)) public balance;
    mapping(uint256 => uint256) public supply;

    event SetProtocolFeeDestination(address indexed destination);
    event SetProtocolFeePercent(uint256 percent);
    event SetClanFeePercent(uint256 percent);
    event ClanCreated(uint256 indexed clanId, address indexed owner);
    event ClanDeleted(uint256 indexed clanId);
    event ClanOwnershipTransferred(uint256 indexed clanId, address indexed previousOwner, address indexed newOwner);
    event FeesWithdrawn(uint256 indexed clanId, uint256 amount);
    event Trade(
        address indexed trader,
        uint256 indexed clanId,
        bool indexed isBuy,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 clanFee,
        uint256 supply
    );

    function initialize(
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _clanFeePercent,
        uint256 _priceIncrementPerEmblem
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        clanFeePercent = _clanFeePercent;
        priceIncrement = _priceIncrementPerEmblem;

        emit SetProtocolFeeDestination(_protocolFeeDestination);
        emit SetProtocolFeePercent(_protocolFeePercent);
        emit SetClanFeePercent(_clanFeePercent);
    }

    function setProtocolFeeDestination(address payable _feeDestination) external onlyOwner {
        protocolFeeDestination = _feeDestination;
        emit SetProtocolFeeDestination(_feeDestination);
    }

    function setProtocolFeePercent(uint256 _feePercent) external onlyOwner {
        protocolFeePercent = _feePercent;
        emit SetProtocolFeePercent(_feePercent);
    }

    function setClanFeePercent(uint256 _feePercent) external onlyOwner {
        clanFeePercent = _feePercent;
        emit SetClanFeePercent(_feePercent);
    }

    function createClan() external returns (uint256 clanId) {
        clanId = nextClanId++;
        clans[clanId].owner = msg.sender;
        emit ClanCreated(clanId, msg.sender);
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
        uint256 startPriceWei = priceIncrement + (_supply * priceIncrement);
        uint256 endSupply = _supply + amount;
        uint256 endPriceWei = priceIncrement + (endSupply * priceIncrement);
        uint256 averagePriceWei = (startPriceWei + endPriceWei) / 2;
        uint256 totalCostWei = averagePriceWei * amount;
        return totalCostWei;
    }

    function getBuyPrice(uint256 clanId, uint256 amount) public view returns (uint256) {
        return getPrice(supply[clanId], amount);
    }

    function getSellPrice(uint256 clanId, uint256 amount) public view returns (uint256) {
        uint256 supplyAfterSale = supply[clanId] - amount;
        return getPrice(supplyAfterSale, amount);
    }

    function getBuyPriceAfterFee(uint256 clanId, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(clanId, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 clanFee = (price * clanFeePercent) / 1 ether;
        return price + protocolFee + clanFee;
    }

    function getSellPriceAfterFee(uint256 clanId, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(clanId, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 clanFee = (price * clanFeePercent) / 1 ether;
        return price - protocolFee - clanFee;
    }

    function executeTrade(uint256 clanId, uint256 amount, uint256 price, bool isBuy) private nonReentrant {
        require(clans[clanId].owner != address(0), "Clan does not exist");
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 clanFee = (price * clanFeePercent) / 1 ether;

        if (isBuy) {
            require(msg.value >= price + protocolFee + clanFee, "Insufficient payment");
            balance[clanId][msg.sender] += amount;
            supply[clanId] += amount;
            protocolFeeDestination.sendValue(protocolFee);
            clans[clanId].accumulatedFees += clanFee;
            if (msg.value > price + protocolFee + clanFee) {
                uint256 refund = msg.value - price - protocolFee - clanFee;
                payable(msg.sender).sendValue(refund);
            }
        } else {
            require(balance[clanId][msg.sender] >= amount, "Insufficient balance");
            balance[clanId][msg.sender] -= amount;
            supply[clanId] -= amount;
            uint256 netAmount = price - protocolFee - clanFee;
            payable(msg.sender).sendValue(netAmount);
            protocolFeeDestination.sendValue(protocolFee);
            clans[clanId].accumulatedFees += clanFee;
        }

        emit Trade(msg.sender, clanId, isBuy, amount, price, protocolFee, clanFee, supply[clanId]);
    }

    function buy(uint256 clanId, uint256 amount) external payable {
        uint256 price = getBuyPrice(clanId, amount);
        executeTrade(clanId, amount, price, true);
    }

    function sell(uint256 clanId, uint256 amount) external {
        uint256 price = getSellPrice(clanId, amount);
        executeTrade(clanId, amount, price, false);
    }
}

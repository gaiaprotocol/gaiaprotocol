// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ClanEmblems is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    struct Clan {
        string name;
        address clanWallet;
        uint256 totalMembers;
        uint256 pricePerEmblem;
    }

    mapping(uint256 => Clan) public clans;
    mapping(uint256 => mapping(address => bool)) public clanMembers;
    uint256 public clanCount;

    uint256 public priceIncrementPerMember;
    uint256 public protocolFeePercent;

    address payable public protocolFeeDestination;

    event ClanCreated(uint256 indexed clanId, string name, address indexed clanWallet);
    event EmblemPurchased(address indexed buyer, uint256 indexed clanId, uint256 price);
    event EmblemReturned(address indexed member, uint256 indexed clanId);

    function initialize(
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _priceIncrementPerMember
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        priceIncrementPerMember = _priceIncrementPerMember;
    }

    function createClan(string memory name, address clanWallet) external onlyOwner {
        clanCount++;
        clans[clanCount] = Clan({
            name: name,
            clanWallet: clanWallet,
            totalMembers: 0,
            pricePerEmblem: priceIncrementPerMember
        });

        emit ClanCreated(clanCount, name, clanWallet);
    }

    function getEmblemPrice(uint256 clanId) public view returns (uint256) {
        Clan storage clan = clans[clanId];
        return clan.pricePerEmblem;
    }

    function joinClan(uint256 clanId) external payable nonReentrant {
        Clan storage clan = clans[clanId];
        require(!clanMembers[clanId][msg.sender], "Already a clan member");

        uint256 price = clan.pricePerEmblem;
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 clanFee = price - protocolFee;

        require(msg.value >= price, "Insufficient payment");

        clanMembers[clanId][msg.sender] = true;
        clan.totalMembers++;
        clan.pricePerEmblem += priceIncrementPerMember;

        protocolFeeDestination.sendValue(protocolFee);
        payable(clan.clanWallet).sendValue(clanFee);

        if (msg.value > price) {
            payable(msg.sender).sendValue(msg.value - price);
        }

        emit EmblemPurchased(msg.sender, clanId, price);
    }

    function leaveClan(uint256 clanId) external nonReentrant {
        Clan storage clan = clans[clanId];
        require(clanMembers[clanId][msg.sender], "Not a clan member");

        clanMembers[clanId][msg.sender] = false;
        clan.totalMembers--;
        if (clan.pricePerEmblem >= priceIncrementPerMember) {
            clan.pricePerEmblem -= priceIncrementPerMember;
        }

        emit EmblemReturned(msg.sender, clanId);
    }
}

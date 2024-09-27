// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MaterialV1.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract MaterialTrade is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;

    uint256 internal baseDivider;
    address payable public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public materialOwnerFeePercent;

    event SetProtocolFeeDestination(address indexed destination);
    event SetProtocolFeePercent(uint256 percent);
    event SetMaterialOwnerFeePercent(uint256 percent);
    event MaterialCreated(address indexed materialOwner, address indexed materialAddress, string name, string symbol);
    event Trade(
        address indexed trader,
        address indexed materialAddress,
        bool indexed isBuy,
        uint256 amount,
        uint256 price,
        uint256 protocolFee,
        uint256 materialOwnerFee,
        uint256 supply
    );

    function initialize(
        uint256 _baseDivider,
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _materialOwnerFeePercent
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        baseDivider = _baseDivider;
        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        materialOwnerFeePercent = _materialOwnerFeePercent;

        emit SetProtocolFeeDestination(_protocolFeeDestination);
        emit SetProtocolFeePercent(_protocolFeePercent);
        emit SetMaterialOwnerFeePercent(_materialOwnerFeePercent);
    }

    function setProtocolFeeDestination(address payable _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
        emit SetProtocolFeeDestination(_feeDestination);
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
        emit SetProtocolFeePercent(_feePercent);
    }

    function setMaterialOwnerFeePercent(uint256 _feePercent) public onlyOwner {
        materialOwnerFeePercent = _feePercent;
        emit SetMaterialOwnerFeePercent(_feePercent);
    }

    function createMaterial(string memory name, string memory symbol) public returns (address) {
        MaterialV1 newMaterial = new MaterialV1(msg.sender, name, symbol);
        emit MaterialCreated(msg.sender, address(newMaterial), name, symbol);
        return address(newMaterial);
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 startPriceWei = (1e15 + supply * 1e15);
        uint256 endPriceWei = (1e15 + (supply + amount - 1) * 1e15);
        uint256 totalCostWei = ((startPriceWei + endPriceWei) / 2) * amount;

        return totalCostWei;
    }

    function getBuyPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        MaterialV1 material = MaterialV1(materialAddress);
        return getPrice(material.totalSupply(), amount);
    }

    function getSellPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        MaterialV1 material = MaterialV1(materialAddress);
        return getPrice(material.totalSupply() - amount, amount);
    }

    function getBuyPriceAfterFee(address materialAddress, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(materialAddress, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 materialOwnerFee = (price * materialOwnerFeePercent) / 1 ether;
        return price + protocolFee + materialOwnerFee;
    }

    function getSellPriceAfterFee(address materialAddress, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(materialAddress, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 materialOwnerFee = (price * materialOwnerFeePercent) / 1 ether;
        return price - protocolFee - materialOwnerFee;
    }

    function executeTrade(address materialAddress, uint256 amount, uint256 price, bool isBuy) private nonReentrant {
        MaterialV1 material = MaterialV1(materialAddress);
        uint256 materialOwnerFee = (price * materialOwnerFeePercent) / 1 ether;
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;

        if (isBuy) {
            require(msg.value >= price + protocolFee + materialOwnerFee, "Insufficient payment");
            material.mint(msg.sender, amount);
            protocolFeeDestination.sendValue(protocolFee);
            payable(material.owner()).sendValue(materialOwnerFee);
            if (msg.value > price + protocolFee + materialOwnerFee) {
                uint256 refund = msg.value - price - protocolFee - materialOwnerFee;
                payable(msg.sender).sendValue(refund);
            }
        } else {
            require(material.balanceOf(msg.sender) >= amount, "Insufficient balance");
            material.burn(msg.sender, amount);
            uint256 netAmount = price - protocolFee - materialOwnerFee;
            payable(msg.sender).sendValue(netAmount);
            protocolFeeDestination.sendValue(protocolFee);
            payable(material.owner()).sendValue(materialOwnerFee);
        }

        emit Trade(
            msg.sender,
            materialAddress,
            isBuy,
            amount,
            price,
            protocolFee,
            materialOwnerFee,
            material.totalSupply()
        );
    }

    function buy(address materialAddress, uint256 amount) external payable {
        uint256 price = getBuyPrice(materialAddress, amount);
        executeTrade(materialAddress, amount, price, true);
    }

    function sell(address materialAddress, uint256 amount) external {
        uint256 price = getSellPrice(materialAddress, amount);
        executeTrade(materialAddress, amount, price, false);
    }
}

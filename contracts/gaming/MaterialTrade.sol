// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MaterialV1.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract MaterialTrade is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;

    address payable public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public materialOwnerFeePercent;
    uint256 public priceIncrementPerToken;

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
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _materialOwnerFeePercent,
        uint256 _priceIncrementPerToken
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        materialOwnerFeePercent = _materialOwnerFeePercent;
        priceIncrementPerToken = _priceIncrementPerToken;

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

    function getPrice(uint256 supply, uint256 amount) public view returns (uint256) {
        uint256 startPriceWei = priceIncrementPerToken + (supply * priceIncrementPerToken) / 1e18;

        uint256 endSupply = supply + amount;
        if (endSupply >= 1e18) {
            endSupply -= 1e18;
        } else {
            endSupply = 0;
        }

        uint256 endPriceWei = priceIncrementPerToken + (endSupply * priceIncrementPerToken) / 1e18;

        uint256 averagePriceWei = (startPriceWei + endPriceWei) / 2;
        uint256 totalCostWei = (averagePriceWei * amount) / 1e18;

        return totalCostWei;
    }

    function getBuyPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        MaterialV1 material = MaterialV1(materialAddress);
        return getPrice(material.totalSupply(), amount);
    }

    function getSellPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        MaterialV1 material = MaterialV1(materialAddress);
        uint256 supplyAfterSale = material.totalSupply() - amount;
        return getPrice(supplyAfterSale, amount);
    }

    function getBuyPriceAfterFee(address materialAddress, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(materialAddress, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 materialOwnerFee = (price * materialOwnerFeePercent) / 1e18;
        return price + protocolFee + materialOwnerFee;
    }

    function getSellPriceAfterFee(address materialAddress, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(materialAddress, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 materialOwnerFee = (price * materialOwnerFeePercent) / 1e18;
        return price - protocolFee - materialOwnerFee;
    }

    function executeTrade(address materialAddress, uint256 amount, uint256 price, bool isBuy) private nonReentrant {
        MaterialV1 material = MaterialV1(materialAddress);
        uint256 materialOwnerFee = (price * materialOwnerFeePercent) / 1e18;
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;

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

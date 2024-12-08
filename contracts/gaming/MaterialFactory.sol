// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Material.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MaterialFactory is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    uint256 public priceIncrement;
    uint256 public protocolFeeRate;
    uint256 public materialOwnerFeeRate;
    address payable public treasury;

    event TreasuryUpdated(address indexed treasury);
    event ProtocolFeeRateUpdated(uint256 rate);
    event MaterialOwnerFeeRateUpdated(uint256 rate);
    event MaterialCreated(
        address indexed materialOwner,
        address indexed materialAddress,
        string name,
        string symbol,
        bytes32 metadataHash
    );
    event MaterialDeleted(address indexed materialAddress);
    event TradeExecuted(
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
        address payable _treasury,
        uint256 _protocolFeeRate,
        uint256 _materialOwnerFeeRate,
        uint256 _priceIncrement
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        treasury = _treasury;
        protocolFeeRate = _protocolFeeRate;
        materialOwnerFeeRate = _materialOwnerFeeRate;
        priceIncrement = _priceIncrement;

        emit TreasuryUpdated(_treasury);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
        emit MaterialOwnerFeeRateUpdated(_materialOwnerFeeRate);
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setProtocolFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        protocolFeeRate = _rate;
        emit ProtocolFeeRateUpdated(_rate);
    }

    function setMaterialOwnerFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        materialOwnerFeeRate = _rate;
        emit MaterialOwnerFeeRateUpdated(_rate);
    }

    function createMaterial(string memory name, string memory symbol, bytes32 metadataHash) public returns (address) {
        Material newMaterial = new Material(msg.sender, name, symbol);
        emit MaterialCreated(msg.sender, address(newMaterial), name, symbol, metadataHash);
        return address(newMaterial);
    }

    function deleteMaterial(address materialAddress) external {
        Material material = Material(materialAddress);
        require(material.owner() == msg.sender, "Not material owner");
        require(material.totalSupply() == 0, "Supply must be zero");

        material.renounceOwnership();
        emit MaterialDeleted(materialAddress);
    }

    function getPrice(uint256 supply, uint256 amount) public view returns (uint256) {
        uint256 startPriceWei = priceIncrement + (supply * priceIncrement) / 1e18;
        uint256 endSupply = supply + amount;
        uint256 endPriceWei = priceIncrement + (endSupply * priceIncrement) / 1e18;
        uint256 averagePriceWei = (startPriceWei + endPriceWei) / 2;
        uint256 totalCostWei = (averagePriceWei * amount) / 1e18;
        return totalCostWei;
    }

    function getBuyPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        Material material = Material(materialAddress);
        return getPrice(material.totalSupply(), amount);
    }

    function getSellPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        Material material = Material(materialAddress);
        uint256 supplyAfterSale = material.totalSupply() - amount;
        return getPrice(supplyAfterSale, amount);
    }

    function getBuyPriceAfterFee(address materialAddress, uint256 amount) external view returns (uint256) {
        uint256 price = getBuyPrice(materialAddress, amount);
        uint256 protocolFee = (price * protocolFeeRate) / 1e18;
        uint256 materialOwnerFee = (price * materialOwnerFeeRate) / 1e18;
        return price + protocolFee + materialOwnerFee;
    }

    function getSellPriceAfterFee(address materialAddress, uint256 amount) external view returns (uint256) {
        uint256 price = getSellPrice(materialAddress, amount);
        uint256 protocolFee = (price * protocolFeeRate) / 1e18;
        uint256 materialOwnerFee = (price * materialOwnerFeeRate) / 1e18;
        return price - protocolFee - materialOwnerFee;
    }

    function executeTrade(address materialAddress, uint256 amount, uint256 price, bool isBuy) private nonReentrant {
        Material material = Material(materialAddress);
        uint256 protocolFee = (price * protocolFeeRate) / 1e18;
        uint256 materialOwnerFee = (price * materialOwnerFeeRate) / 1e18;

        if (isBuy) {
            require(msg.value >= price + protocolFee + materialOwnerFee, "Insufficient payment");
            material.mint(msg.sender, amount);
            treasury.sendValue(protocolFee);
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
            treasury.sendValue(protocolFee);
            payable(material.owner()).sendValue(materialOwnerFee);
        }

        emit TradeExecuted(
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

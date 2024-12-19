// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.28;

  
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Material is ERC20Permit, Ownable2Step {
    address public immutable factory;

    string private _name;
    string private _symbol;

    mapping(address => bool) public whitelist;

    event NameUpdated(string name);
    event SymbolUpdated(string symbol);
    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_
    ) ERC20Permit("Material") ERC20("", "") Ownable(owner_) {
        factory = msg.sender;
        _name = name_;
        _symbol = symbol_;

        emit NameUpdated(name_);
        emit SymbolUpdated(symbol_);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function updateName(string memory name_) external onlyOwner {
        _name = name_;
        emit NameUpdated(name_);
    }

    function updateSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
        emit SymbolUpdated(symbol_);
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Material: caller is not the factory");
        _;
    }

    function mint(address to, uint256 amount) external onlyFactory {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyFactory {
        _burn(from, amount);
    }

    function addToWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!whitelist[_addresses[i]], "Address is already whitelisted");
            whitelist[_addresses[i]] = true;
            emit WhitelistAdded(_addresses[i]);
        }
    }

    function removeFromWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(whitelist[_addresses[i]], "Address is not whitelisted");
            whitelist[_addresses[i]] = false;
            emit WhitelistRemoved(_addresses[i]);
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if (whitelist[msg.sender]) {
            _transfer(sender, recipient, amount);
            return true;
        }
        return super.transferFrom(sender, recipient, amount);
    }
}


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MaterialFactory is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    uint256 public priceIncrement;
    address payable public protocolFeeRecipient;
    uint256 public protocolFeeRate;
    uint256 public materialOwnerFeeRate;

    event ProtocolFeeRecipientUpdated(address indexed protocolFeeRecipient);
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
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeRate,
        uint256 _materialOwnerFeeRate,
        uint256 _priceIncrement
    ) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;
        materialOwnerFeeRate = _materialOwnerFeeRate;
        priceIncrement = _priceIncrement;

        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
        emit MaterialOwnerFeeRateUpdated(_materialOwnerFeeRate);
    }

    function updateProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient address");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    function updateProtocolFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        protocolFeeRate = _rate;
        emit ProtocolFeeRateUpdated(_rate);
    }

    function updateMaterialOwnerFeeRate(uint256 _rate) external onlyOwner {
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
        return PricingLib.getPrice(supply, amount, priceIncrement, 1e18);
    }

    function getBuyPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        Material material = Material(materialAddress);
        return PricingLib.getBuyPrice(material.totalSupply(), amount, priceIncrement, 1e18);
    }

    function getSellPrice(address materialAddress, uint256 amount) public view returns (uint256) {
        Material material = Material(materialAddress);
        return PricingLib.getSellPrice(material.totalSupply(), amount, priceIncrement, 1e18);
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
            protocolFeeRecipient.sendValue(protocolFee);
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
            protocolFeeRecipient.sendValue(protocolFee);
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


import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract GaiaProtocolToken is ERC20Permit {
    constructor() ERC20("Gaia Protocol", "GAIA") ERC20Permit("Gaia Protocol") {
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }
}


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GaiaProtocolTokenTestnet is ERC20 {
    uint8 private constant DECIMALS = 18;

    constructor() ERC20("Gaia Protocol", "GAIA") {}

    function mintForTest(uint256 amount) external {
        require(amount <= 10_000 * 10 ** DECIMALS, "GaiaProtocolTokenTestnet: max mint amount is 10,000");
        _mint(msg.sender, amount);
    }
}


library PricingLib {
    function getPrice(
        uint256 supply,
        uint256 amount,
        uint256 priceIncrement,
        uint256 scaleFactor
    ) internal pure returns (uint256) {
        uint256 startPrice = priceIncrement + (supply * priceIncrement) / scaleFactor;
        uint256 endSupply = supply + amount;
        uint256 endPrice = priceIncrement + (endSupply * priceIncrement) / scaleFactor;
        uint256 averagePrice = (startPrice + endPrice) / 2;
        uint256 totalCost = (averagePrice * amount) / scaleFactor;
        return totalCost;
    }

    function getBuyPrice(
        uint256 supply,
        uint256 amount,
        uint256 priceIncrement,
        uint256 scaleFactor
    ) internal pure returns (uint256) {
        return getPrice(supply, amount, priceIncrement, scaleFactor);
    }

    function getSellPrice(
        uint256 supply,
        uint256 amount,
        uint256 priceIncrement,
        uint256 scaleFactor
    ) internal pure returns (uint256) {
        uint256 supplyAfterSale = supply - amount;
        return getPrice(supplyAfterSale, amount, priceIncrement, scaleFactor);
    }
}


import "@openzeppelin/contracts/utils/Address.sol";

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


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

abstract contract HoldingRewardsBase is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address payable public protocolFeeRecipient;
    uint256 public protocolFeeRate;
    address public holdingVerifier;

    event ProtocolFeeRecipientUpdated(address indexed protocolFeeRecipient);
    event ProtocolFeeRateUpdated(uint256 rate);
    event HoldingVerifierUpdated(address indexed verifier);

    function updateProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    function updateProtocolFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        protocolFeeRate = _rate;
        emit ProtocolFeeRateUpdated(_rate);
    }

    function updateHoldingVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        holdingVerifier = _verifier;
        emit HoldingVerifierUpdated(_verifier);
    }

    function calculateHoldingReward(
        uint256 baseAmount,
        uint256 rewardRatio,
        bytes memory signature
    ) public view returns (uint256) {
        if (signature.length == 0) return 0;
        require(rewardRatio <= 1 ether, "Reward ratio too high");

        bytes32 hash = keccak256(abi.encodePacked(baseAmount, rewardRatio));
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();

        address signer = ethSignedHash.recover(signature);
        require(signer == holdingVerifier, "Invalid verifier");

        return (baseAmount * rewardRatio) / 1 ether;
    }
}


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
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeRate,
        uint256 _personaOwnerFeeRate,
        uint256 _priceIncrementPerFragment,
        address _holdingVerifier
    ) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient");
        require(_holdingVerifier != address(0), "Invalid verifier address");

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;
        personaOwnerFeeRate = _personaOwnerFeeRate;
        priceIncrementPerFragment = _priceIncrementPerFragment;
        holdingVerifier = _holdingVerifier;

        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
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
        return PricingLib.getPrice(_supply, amount, priceIncrementPerFragment, 1);
    }

    function getBuyPrice(address persona, uint256 amount) public view returns (uint256) {
        return PricingLib.getBuyPrice(supply[persona], amount, priceIncrementPerFragment, 1);
    }

    function getSellPrice(address persona, uint256 amount) public view returns (uint256) {
        return PricingLib.getSellPrice(supply[persona], amount, priceIncrementPerFragment, 1);
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
        uint256 rewardRatio,
        bytes memory holdingRewardSignature
    ) private nonReentrant {
        uint256 rawProtocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 holdingReward = calculateHoldingReward(rawProtocolFee, rewardRatio, holdingRewardSignature);
        uint256 protocolFee = rawProtocolFee - holdingReward;
        uint256 personaFee = ((price * personaOwnerFeeRate) / 1 ether) + holdingReward;

        if (isBuy) {
            require(msg.value >= price + protocolFee + personaFee, "Insufficient payment");
            balance[persona][msg.sender] += amount;
            supply[persona] += amount;
            protocolFeeRecipient.sendValue(protocolFee);
            payable(persona).sendValue(personaFee);
            if (msg.value > price + protocolFee + personaFee) {
                payable(msg.sender).sendValue(msg.value - price - protocolFee - personaFee);
            }
        } else {
            require(balance[persona][msg.sender] >= amount, "Insufficient balance");
            balance[persona][msg.sender] -= amount;
            supply[persona] -= amount;
            payable(msg.sender).sendValue(price - protocolFee - personaFee);
            protocolFeeRecipient.sendValue(protocolFee);
            payable(persona).sendValue(personaFee);
        }

        emit TradeExecuted(
            msg.sender,
            persona,
            isBuy,
            amount,
            price,
            protocolFee,
            personaFee,
            holdingReward,
            supply[persona]
        );
    }

    function buy(
        address persona,
        uint256 amount,
        uint256 rewardRatio,
        bytes memory holdingRewardSignature
    ) external payable {
        uint256 price = getBuyPrice(persona, amount);
        executeTrade(persona, amount, price, true, rewardRatio, holdingRewardSignature);
    }

    function sell(address persona, uint256 amount, uint256 rewardRatio, bytes memory holdingRewardSignature) external {
        uint256 price = getSellPrice(persona, amount);
        executeTrade(persona, amount, price, false, rewardRatio, holdingRewardSignature);
    }
}


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
    event TradeExecuted(
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
    event HolderFeeClaimed(address indexed holder, bytes32 indexed topic, uint256 fee);

    function initialize(
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeRate,
        uint256 _holderFeeRate,
        uint256 _priceIncrementPerShare,
        address _holdingVerifier
    ) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient");
        require(_holdingVerifier != address(0), "Invalid verifier address");

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;
        holderFeeRate = _holderFeeRate;
        priceIncrementPerShare = _priceIncrementPerShare;
        holdingVerifier = _holdingVerifier;

        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
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
        return PricingLib.getPrice(_supply, amount, priceIncrementPerShare, 1);
    }

    function getBuyPrice(bytes32 topic, uint256 amount) public view returns (uint256) {
        return PricingLib.getBuyPrice(topics[topic].supply, amount, priceIncrementPerShare, 1);
    }

    function getSellPrice(bytes32 topic, uint256 amount) public view returns (uint256) {
        return PricingLib.getSellPrice(topics[topic].supply, amount, priceIncrementPerShare, 1);
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

    function buy(
        bytes32 topic,
        uint256 amount,
        uint256 rewardRatio,
        bytes memory holdingRewardSignature
    ) external payable nonReentrant {
        Topic memory t = topics[topic];
        uint256 price = getBuyPrice(topic, amount);

        uint256 rawProtocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 holdingReward = calculateHoldingReward(rawProtocolFee, rewardRatio, holdingRewardSignature);
        uint256 protocolFee = rawProtocolFee - holdingReward;
        uint256 holderFee = ((price * holderFeeRate) / 1 ether) + holdingReward;

        require(msg.value >= price + protocolFee + holderFee, "Insufficient payment");

        if (t.supply > 0) {
            t.accFeePerUnit += (holderFee * ACC_FEE_PRECISION) / t.supply;
        }

        t.supply += amount;
        topics[topic] = t;

        Holder storage h = holders[topic][msg.sender];
        h.balance += amount;
        h.feeDebt += int256((amount * t.accFeePerUnit) / ACC_FEE_PRECISION);

        protocolFeeRecipient.sendValue(protocolFee);
        if (msg.value > price + protocolFee + holderFee) {
            payable(msg.sender).sendValue(msg.value - price - protocolFee - holderFee);
        }

        emit TradeExecuted(msg.sender, topic, true, amount, price, protocolFee, holderFee, holdingReward, t.supply);
    }

    function sell(
        bytes32 topic,
        uint256 amount,
        uint256 rewardRatio,
        bytes memory holdingRewardSignature
    ) external nonReentrant {
        Topic memory t = topics[topic];
        Holder storage holder = holders[topic][msg.sender];

        require(holder.balance >= amount, "Insufficient balance");

        uint256 price = getSellPrice(topic, amount);

        uint256 rawProtocolFee = (price * protocolFeeRate) / 1 ether;
        uint256 holdingReward = calculateHoldingReward(rawProtocolFee, rewardRatio, holdingRewardSignature);
        uint256 protocolFee = rawProtocolFee - holdingReward;
        uint256 holderFee = ((price * holderFeeRate) / 1 ether) + holdingReward;

        holder.balance -= amount;
        t.supply -= amount;

        if (t.supply > 0) {
            t.accFeePerUnit += (holderFee * ACC_FEE_PRECISION) / t.supply;
            topics[topic] = t;

            payable(msg.sender).sendValue(price - protocolFee - holderFee);
            protocolFeeRecipient.sendValue(protocolFee);
        } else {
            topics[topic] = t;

            payable(msg.sender).sendValue(price - protocolFee - holderFee);
            protocolFeeRecipient.sendValue(protocolFee + holderFee);
        }

        emit TradeExecuted(msg.sender, topic, false, amount, price, protocolFee, holderFee, holdingReward, t.supply);
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
        emit HolderFeeClaimed(msg.sender, topic, claimableFee);
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


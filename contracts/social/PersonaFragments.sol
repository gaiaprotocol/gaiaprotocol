// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PersonaFragments is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address payable;

    struct Persona {
        string name;
        address personaOwner;
        uint256 totalFragments;
        uint256 pricePerFragment;
    }

    mapping(uint256 => Persona) public personas;
    mapping(uint256 => mapping(address => bool)) public personaConnections;
    uint256 public personaCount;

    uint256 public priceIncrementPerConnection;
    uint256 public protocolFeePercent;

    address payable public protocolFeeDestination;

    event PersonaCreated(uint256 indexed personaId, string name, address indexed personaOwner);
    event FragmentPurchased(address indexed buyer, uint256 indexed personaId, uint256 price);
    event FragmentSold(address indexed seller, uint256 indexed personaId);

    function initialize(
        address payable _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _priceIncrementPerConnection
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        priceIncrementPerConnection = _priceIncrementPerConnection;
    }

    function createPersona(string memory name) external {
        personaCount++;
        personas[personaCount] = Persona({
            name: name,
            personaOwner: msg.sender,
            totalFragments: 0,
            pricePerFragment: priceIncrementPerConnection
        });

        emit PersonaCreated(personaCount, name, msg.sender);
    }

    function getFragmentPrice(uint256 personaId) public view returns (uint256) {
        Persona storage persona = personas[personaId];
        return persona.pricePerFragment;
    }

    function connectToPersona(uint256 personaId) external payable nonReentrant {
        Persona storage persona = personas[personaId];
        require(!personaConnections[personaId][msg.sender], "Already connected");

        uint256 price = persona.pricePerFragment;
        uint256 protocolFee = (price * protocolFeePercent) / 1e18;
        uint256 ownerFee = price - protocolFee;

        require(msg.value >= price, "Insufficient payment");

        personaConnections[personaId][msg.sender] = true;
        persona.totalFragments++;
        persona.pricePerFragment += priceIncrementPerConnection;

        protocolFeeDestination.sendValue(protocolFee);
        payable(persona.personaOwner).sendValue(ownerFee);

        if (msg.value > price) {
            payable(msg.sender).sendValue(msg.value - price);
        }

        emit FragmentPurchased(msg.sender, personaId, price);
    }

    function disconnectFromPersona(uint256 personaId) external nonReentrant {
        Persona storage persona = personas[personaId];
        require(personaConnections[personaId][msg.sender], "Not connected");

        personaConnections[personaId][msg.sender] = false;
        persona.totalFragments--;
        if (persona.pricePerFragment >= priceIncrementPerConnection) {
            persona.pricePerFragment -= priceIncrementPerConnection;
        }

        emit FragmentSold(msg.sender, personaId);
    }
}

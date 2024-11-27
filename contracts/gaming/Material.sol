// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Material is ERC20Permit, Ownable2Step {
    address public immutable factory;

    string private _name;
    string private _symbol;

    mapping(address => bool) public whitelist;

    event NameSet(string name);
    event SymbolSet(string symbol);
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

        emit NameSet(name_);
        emit SymbolSet(symbol_);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
        emit NameSet(name_);
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
        emit SymbolSet(symbol_);
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

    function addToWhitelist(address _address) external onlyOwner {
        require(!whitelist[_address], "Address is already whitelisted");
        whitelist[_address] = true;
        emit WhitelistAdded(_address);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        require(whitelist[_address], "Address is not whitelisted");
        whitelist[_address] = false;
        emit WhitelistRemoved(_address);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Material is ERC20Permit, Ownable2Step {
    address public immutable materialTrade;

    string private _name;
    string private _symbol;

    mapping(address => bool) public whitelist;

    event SetName(string name);
    event SetSymbol(string symbol);
    event AddToWhitelist(address indexed account);
    event RemoveFromWhitelist(address indexed account);

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_
    ) ERC20Permit("Material") ERC20("", "") Ownable(owner_) {
        materialTrade = msg.sender;
        _name = name_;
        _symbol = symbol_;

        emit SetName(name_);
        emit SetSymbol(symbol_);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
        emit SetName(name_);
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
        emit SetSymbol(symbol_);
    }

    modifier onlyMaterialTrade() {
        require(msg.sender == materialTrade, "Material: caller is not the material trade");
        _;
    }

    function mint(address to, uint256 amount) external onlyMaterialTrade {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMaterialTrade {
        _burn(from, amount);
    }

    function addToWhitelist(address _address) external onlyOwner {
        require(!whitelist[_address], "Address is already whitelisted");
        whitelist[_address] = true;
        emit AddToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        require(whitelist[_address], "Address is not whitelisted");
        whitelist[_address] = false;
        emit RemoveFromWhitelist(_address);
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

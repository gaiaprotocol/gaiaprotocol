// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GaiaProtocolBadges is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC1155Upgradeable, UUPSUpgradeable {
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __ERC1155_init("");
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, ids, values);
        } else {
            revert("Soulbound tokens cannot be transferred");
        }
    }

    function airdrop(address[] calldata recipients, uint256 tokenId, bytes calldata data) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenId, 1, data);
        }
    }
}

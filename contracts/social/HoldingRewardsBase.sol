// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

abstract contract HoldingRewardsBase is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address payable public treasury;
    uint256 public protocolFeeRate;
    address public holdingVerifier;

    event TreasuryUpdated(address indexed treasury);
    event ProtocolFeeRateUpdated(uint256 rate);
    event HoldingVerifierUpdated(address indexed verifier);

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

    function setHoldingVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        holdingVerifier = _verifier;
        emit HoldingVerifierUpdated(_verifier);
    }

    function parseRewardRatio(
        bytes memory signature
    ) internal pure returns (uint256 rewardRatio, bytes32 originalHash) {
        require(signature.length == 96, "Invalid signature length");

        assembly {
            rewardRatio := mload(add(signature, 32))
            originalHash := mload(add(signature, 64))
        }

        require(rewardRatio <= 1 ether, "Reward ratio too high");
        return (rewardRatio, originalHash);
    }

    function calculateHoldingReward(uint256 baseAmount, bytes memory signature) public view returns (uint256) {
        if (signature.length == 0) return 0;

        (uint256 rewardRatio, bytes32 originalHash) = parseRewardRatio(signature);

        bytes32 hash = keccak256(abi.encodePacked(baseAmount, rewardRatio));
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        require(originalHash == ethSignedHash, "Invalid signature data");

        address signer = ethSignedHash.recover(signature);
        require(signer == holdingVerifier, "Invalid verifier");

        return (baseAmount * rewardRatio) / 1 ether;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Profiles is OwnableUpgradeable {
    struct Profile {
        address pfpAddress;
        uint256 pfpTokenId;
        string profileData;
    }
    mapping(address => Profile) public profiles;
    event ProfileChanged(address indexed _address, address _pfpAddress, uint256 _pfpTokenId, string _profileData);

    function initialize() public initializer {
        __Ownable_init();
    }

    function pfpOf(address _address) public view returns (address, uint256) {
        Profile memory profile = profiles[_address];
        if (IERC721(profile.pfpAddress).ownerOf(profile.pfpTokenId) == _address) {
            return (profile.pfpAddress, profile.pfpTokenId);
        }
        return (address(0), 0);
    }

    function updateProfile(address _pfpAddress, uint256 _pfpTokenId, string memory _profileData) public {
        require(
            (_pfpAddress == address(0) && _pfpTokenId == 0) || IERC721(_pfpAddress).ownerOf(_pfpTokenId) == msg.sender,
            "Profiles: You don't own this PFP"
        );
        profiles[msg.sender] = Profile(_pfpAddress, _pfpTokenId, _profileData);
        emit ProfileChanged(msg.sender, _pfpAddress, _pfpTokenId, _profileData);
    }

    function deleteProfile() public {
        delete profiles[msg.sender];
        emit ProfileChanged(msg.sender, address(0), 0, "");
    }
}

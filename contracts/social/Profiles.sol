// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Profiles is OwnableUpgradeable {
    struct Pfp {
        address addr;
        uint256 tokenId;
    }

    mapping(address => Pfp) private _pfp;
    mapping(address => string) public profile; // json string

    event PfpChanged(address indexed _addr, address indexed _pfpAddr, uint256 indexed _tokenId);
    event ProfileChanged(address indexed _addr, string _profile);

    function initialize() public initializer {
        __Ownable_init();
    }

    function pfpOf(address _addr) public view returns (address, uint256) {
        Pfp memory pfp = _pfp[_addr];
        if (IERC721(pfp.addr).ownerOf(pfp.tokenId) == _addr) {
            return (pfp.addr, pfp.tokenId);
        }
        return (address(0), 0);
    }

    function changePfp(address _pfpAddr, uint256 _tokenId) public {
        require(IERC721(_pfpAddr).ownerOf(_tokenId) == msg.sender, "Not owner");
        _pfp[msg.sender] = Pfp(_pfpAddr, _tokenId);
        emit PfpChanged(msg.sender, _pfpAddr, _tokenId);
    }

    function changeProfile(string memory _profile) public {
        profile[msg.sender] = _profile;
        emit ProfileChanged(msg.sender, _profile);
    }
}

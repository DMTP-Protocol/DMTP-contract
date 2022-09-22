// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./extensions/ERC721URIStorage.sol";

contract Sticker is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721A("DMTP Sticker", "DMTPSTK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(
        address to,
        uint256 quantity,
        string[] memory uris
    ) external onlyRole(MINTER_ROLE) {
        require(
            quantity == uris.length,
            "Sticker: quantity and uris length mismatch"
        );
        uint256 startTokenId = _nextTokenId();
        _mint(to, quantity);
        for (uint256 i = 0; i < quantity; i++) {
            _setTokenURI(startTokenId + i, uris[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

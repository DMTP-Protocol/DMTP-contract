// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Sticker is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _currentTokenID = 0;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(
        address account,
        uint256 amount,
        string memory _uri
    ) public onlyRole(MINTER_ROLE) {
        uint256 id = ++_currentTokenID;
        _tokenURIs[id] = _uri;
        _mint(account, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory amounts,
        string[] memory uris
    ) public onlyRole(MINTER_ROLE) {
        require(amounts.length == uris.length, "Sticker: INVALID_INPUT_LENGTH");
        uint256[] memory ids = new uint256[](amounts.length);
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 id = ++_currentTokenID;
            ids[i] = id;
            _tokenURIs[id] = uris[i];
        }
        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _tokenURIs[id];
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

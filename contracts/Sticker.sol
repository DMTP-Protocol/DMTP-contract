// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./interfaces/ISticker.sol";
import "./interfaces/IDMTPMarket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Sticker is ISticker, Ownable, ERC1155 {
    mapping(uint256 => string) private _tokenURIs;
    bytes32 public constant ACCESS_STICKER_ROLE =
        keccak256("ACCESS_STICKER_ROLE");
    IDMTPMarket private _market;

    constructor() ERC1155("") {}

    function setMarket(address _marketAddress) public onlyOwner {
        _market = IDMTPMarket(_marketAddress);
    }

    function mint(
        uint256 id,
        address account,
        uint256 amount,
        string memory _uri
    ) public override {
        require(
            _market.hasRole(ACCESS_STICKER_ROLE, msg.sender),
            "Sticker: only market can mint"
        );
        _tokenURIs[id] = _uri;
        _mint(account, id, amount, "");
    }

    function mintBatch(
        uint256[] memory ids,
        address to,
        uint256[] memory amounts,
        string[] memory uris
    ) public override {
        require(
            _market.hasRole(ACCESS_STICKER_ROLE, msg.sender),
            "Sticker: only market can mint"
        );
        require(amounts.length == uris.length, "Sticker: INVALID_INPUT_LENGTH");
        for (uint256 i = 0; i < uris.length; i++) {
            _tokenURIs[ids[i]] = uris[i];
        }
        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _tokenURIs[id];
    }
}

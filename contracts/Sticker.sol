// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./interfaces/ISticker.sol";
import "./interfaces/IDMTPMarket.sol";

contract Sticker is ISticker, ERC1155 {
    mapping(uint256 => string) private _tokenURIs;

    IDMTPMarket private _market;

    constructor(address market) ERC1155("") {
        _market = IDMTPMarket(market);
    }

    function mint(
        uint256 id,
        address account,
        uint256 amount,
        string memory _uri
    ) public override {
        _tokenURIs[id] = _uri;
        _mint(account, id, amount, "");
    }

    function mintBatch(
        uint256[] memory ids,
        address to,
        uint256[] memory amounts,
        string[] memory uris
    ) public override {
        require(amounts.length == uris.length, "Sticker: INVALID_INPUT_LENGTH");
        for (uint256 i = 0; i < uris.length; i++) {
            _tokenURIs[ids[i]] = uris[i];
        }
        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _market.stickerURI(id);
    }
}

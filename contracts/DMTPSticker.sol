// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./interfaces/ISticker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DMTPSticker is ISticker, Ownable, ERC1155 {
    mapping(uint256 => string) private _tokenURIs;
    address private _market;

    constructor() ERC1155("") {}

    modifier onlyMarket() {
        require(_market == msg.sender, "Sticker: only market can mint");
        _;
    }

    function setMarket(address _marketAddress) public onlyOwner {
        _market = _marketAddress;
    }

    function mint(
        uint256 id,
        address account,
        uint256 amount,
        string calldata _uri
    ) public override onlyMarket {
        _tokenURIs[id] = _uri;
        _mint(account, id, amount, "");
    }

    function mintBatch(
        uint256[] calldata ids,
        address to,
        uint256[] calldata amounts,
        string[] calldata uris
    ) public override onlyMarket {
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

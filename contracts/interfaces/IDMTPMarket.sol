// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDMTPMarket {
    enum StickerPriceType {
        None,
        Fixed,
        Free
    }

    enum WhitelistType {
        None,
        Fixed
    }

    struct Sticker {
        string uri;
        StickerPriceType priceType;
        address token;
        uint256 price;
        address seller;
        uint256 amount;
    }

    struct Whitelist {
        WhitelistType whitelistType;
        mapping(address => bool) whitelist;
    }
    event SetPrice(
        uint256 indexed stickerId,
        uint256 indexed price,
        address token,
        StickerPriceType indexed priceType
    );
    event SetWhiteList(uint256 indexed stickerId, string whitelist);
    event NoWhitelist(uint256 indexed stickerId);
    event Buy(
        uint256 indexed stickerId,
        address indexed buyer,
        uint256 indexed price
    );

    function setStickerPrice(
        string memory uri,
        uint256 amount,
        address token,
        uint256 price,
        bool sellable,
        address[] memory whitelist
    ) external;

    function setStickerPriceBatch(
        string[] memory stickerUris,
        uint256[] memory amounts,
        address[] memory tokens,
        uint256[] memory prices,
        bool[] memory sellables,
        address[][] memory whitelists
    ) external;

    function buy(uint256 stickerId) external;

    function stickerURI(uint256 id) external view returns (string memory);
}

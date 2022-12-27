// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IDMTPMarket is IAccessControl {
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
        uint256 amount;
    }

    event NewSticker(
        uint256 indexed stickerId,
        uint256 indexed price,
        address token,
        uint256 amount,
        StickerPriceType priceType,
        bytes32 whitelist
    );
    event Buy(
        uint256 indexed stickerId,
        address indexed buyer,
        uint256 indexed price,
        address token
    );

    function setStickerPrice(
        uint256 tokenId,
        string memory uri,
        uint256 amount,
        address token,
        uint256 price,
        bool sellable,
        bytes32 whitelist
    ) external;

    function setStickerPriceBatch(
        uint256[] memory stickerIds,
        string[] memory stickerUris,
        uint256[] memory amounts,
        address[] memory tokens,
        uint256[] memory prices,
        bool[] memory sellables,
        bytes32[] memory whitelists
    ) external;

    function buy(uint256 stickerId, bytes32[] memory _merkleProof) external;

    function stickerURI(uint256 id) external view returns (string memory);

    function stickerLeft(uint256 id) external view returns (uint256);
}

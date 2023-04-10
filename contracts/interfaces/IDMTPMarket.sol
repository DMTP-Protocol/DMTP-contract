// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IDMTPMarket is IAccessControl {
    enum StickerPriceType {
        None,
        Fixed,
        Free
    }

    struct Sticker {
        string uri;
        StickerPriceType priceType;
        address token;
        uint256 price;
        uint256 amount;
        bytes32 whitelistTopHash;
        uint256 amountLeft;
    }

    event NewSticker(
        uint256 indexed stickerId,
        uint256 indexed price,
        address token,
        uint256 amount,
        StickerPriceType priceType,
        bytes32 whitelistTopHash
    );
    event Buy(
        uint256 indexed stickerId,
        address indexed buyer,
        uint256 indexed price,
        address token
    );

    event DisablelSticker(uint256 indexed stickerId);
    event EnableSticker(uint256 indexed stickerId);

    function listSticker(
        uint256 tokenId,
        string calldata uri,
        uint256 amount,
        address token,
        uint256 price,
        bytes32 whitelist
    ) external;

    function listStickerBatch(
        uint256[] calldata stickerIds,
        string[] calldata stickerUris,
        uint256[] calldata amounts,
        address[] calldata tokens,
        uint256[] calldata prices,
        bytes32[] calldata whitelists
    ) external;

    function disableListedSticker(uint256 stickerId) external;

    function enableListedSticker(uint256 stickerId) external;

    function buy(uint256 stickerId, bytes32[] calldata _merkleProof) external;
}

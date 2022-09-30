// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

enum StickerStatus {
    None,
    Fixed,
    Free
}

enum WhitelistStatus {
    None,
    Fixed
}

struct StickerPrice {
    StickerStatus status;
    uint256 price;
}

struct StickerWhitelist {
    WhitelistStatus status;
    mapping(address => bool) whitelist;
}

contract DMTPMarket {
    event SetPrice(
        uint256 indexed stickerId,
        uint256 indexed price,
        StickerStatus indexed status
    );
    event SetWhiteList(
        uint256 indexed stickerId,
        address[] indexed whitelist,
        bool indexed allow
    );
    event ClearWhitelist(uint256 indexed stickerId);
    event Buy(uint256 indexed stickerId, address indexed buyer);

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint256 => StickerWhitelist) private _whitelist;
    mapping(uint256 => StickerPrice) private _stickerPrice;
    IERC20 private _token;
    IERC721 private _sticker;
    IAccessControl private _accessControl;

    constructor(address token, address sticker) {
        _token = IERC20(token);
        _sticker = IERC721(sticker);
        _accessControl = IAccessControl(sticker);
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is missing `MINTER_ROLE`.
     */
    modifier onlyMintRole() {
        require(
            _accessControl.hasRole(MINTER_ROLE, msg.sender),
            "DMTPMarket: only minter"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `sticker` is not sale.
     */
    modifier onlyStickerSale(uint256 stickerId) {
        require(
            _stickerPrice[stickerId].status != StickerStatus.None,
            "DMTPMarket: sticker not for sale"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is not owner of sticker.
     */
    modifier onlyOwner(uint256 stickerId) {
        require(
            _sticker.ownerOf(stickerId) == msg.sender,
            "DMTPMarket: only owner"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is not in whitelist to Buy sticker, in case sticker have whitelist.
     */
    modifier onlyWhitelist(uint256 stickerId) {
        if (_whitelist[stickerId].status == WhitelistStatus.Fixed)
            require(
                _whitelist[stickerId].whitelist[msg.sender],
                "DMTPMarket: not in whitelist"
            );
        _;
    }

    /**
     * @dev set price for sticker.
     *
     * Requirements:
     * - `msg.sender` must be owner of sticker.
     * - `msg.sender` must be have `MINTER_ROLE`.
     * - `status` equa None for disallow to Buy sticker.
     * - `status` equa Free for airdrop sticker.
     * - `status` equa Fixed for sale sticker.
     * - `price` must be equal 0 when `status` equa Free.
     * - `price` must be greater than 0 when `status` equa Fixed.
     * - `price` will be dont care when `status` equa None.
     * - `whitelist` empty when everyone can Buy.
     * - `whitelist` not empty when only address in whitelist can Buy.
     */
    function setStickerPrice(
        uint256 stickerId,
        StickerStatus status,
        uint256 price,
        address[] memory whitelist
    ) public onlyMintRole onlyOwner(stickerId) {
        if (status == StickerStatus.Fixed) {
            require(price > 0, "DMTPMarket: price must be greater than 0");
        } else if (status == StickerStatus.Free) {
            require(price == 0, "DMTPMarket: price must be equal 0");
        }
        _stickerPrice[stickerId] = StickerPrice(status, price);
        emit SetPrice(stickerId, price, status);
        if (whitelist.length == 0) {
            delete _whitelist[stickerId];
            emit ClearWhitelist(stickerId);
        } else {
            _whitelist[stickerId].status = WhitelistStatus.Fixed;
            for (uint256 i = 0; i < whitelist.length; i++) {
                _whitelist[stickerId].whitelist[whitelist[i]] = true;
            }
            emit SetWhiteList(stickerId, whitelist, true);
        }
    }

    /**
     * @dev set whitelist for sticker.
     *
     * Requirements:
     *
     * - `msg.sender` must be owner of sticker.
     * - `msg.sender` must be have `MINTER_ROLE`.
     * - `whitelist` empty when everyone can Buy.
     * - `whitelist` not empty when only address in whitelist can Buy.
     */
    function setStickerWhitelist(
        uint256 stickerId,
        address[] memory whitelist,
        bool allow
    ) external onlyMintRole onlyOwner(stickerId) {
        if (whitelist.length == 0) {
            delete _whitelist[stickerId];
            emit ClearWhitelist(stickerId);
        } else {
            _whitelist[stickerId].status = WhitelistStatus.Fixed;
            for (uint256 i = 0; i < whitelist.length; i++) {
                _whitelist[stickerId].whitelist[whitelist[i]] = allow;
            }
            emit SetWhiteList(stickerId, whitelist, allow);
        }
    }

    /**
     * @dev Buy sticker.
     *
     * Requirements:
     * - `msg.sender` must be have `appvore` erc20 token on this contract before call this function.
     * - `sticker` owner must be have `appvore` erc721 sticker nft on this contract before this function call.
     * - `stickerId` must be exist.
     * - `stickerId` must be for sale.
     * - `msg.sender` must be in whitelist if sticker have whitelist.
     */
    function buy(uint256 stickerId)
        external
        onlyStickerSale(stickerId)
        onlyWhitelist(stickerId)
    {
        _token.transferFrom(
            msg.sender,
            _sticker.ownerOf(stickerId),
            _stickerPrice[stickerId].price
        );
        _sticker.transferFrom(
            _sticker.ownerOf(stickerId),
            msg.sender,
            stickerId
        );
        delete _stickerPrice[stickerId];
        delete _whitelist[stickerId];
        emit Buy(stickerId, msg.sender);
    }
}

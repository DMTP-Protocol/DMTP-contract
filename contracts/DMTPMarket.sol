// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
    address seller;
    uint256 amount;
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
    event SetWhiteList(uint256 indexed stickerId, string whitelist);
    event ClearWhitelist(uint256 indexed stickerId);
    event Buy(
        uint256 indexed stickerId,
        address indexed buyer,
        uint256 indexed price
    );

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint256 => StickerWhitelist) private _whitelist;
    mapping(uint256 => StickerPrice) private _stickerPrice;

    IERC20 private _token;
    IERC1155 private _sticker;
    IAccessControl private _accessControl;

    constructor(address token, address sticker) {
        _token = IERC20(token);
        _sticker = IERC1155(sticker);
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
            _sticker.balanceOf(msg.sender, stickerId) > 0,
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
        uint256 amount,
        uint256 price,
        bool sellable,
        address[] memory whitelist
    ) public onlyMintRole onlyOwner(stickerId) {
        StickerStatus status;
        if (sellable) {
            if (price > 0) status = StickerStatus.Fixed;
            else status = StickerStatus.Free;
        }

        _stickerPrice[stickerId] = StickerPrice(
            status,
            price,
            msg.sender,
            amount
        );
        emit SetPrice(stickerId, price, status);
        if (whitelist.length == 0) {
            delete _whitelist[stickerId];
            emit ClearWhitelist(stickerId);
        } else {
            _whitelist[stickerId].status = WhitelistStatus.Fixed;
            for (uint256 i = 0; i < whitelist.length; i++) {
                _whitelist[stickerId].whitelist[whitelist[i]] = true;
            }
            emit SetWhiteList(stickerId, joinAddress(whitelist));
        }
    }

    function setStickerPriceBatch(
        uint256[] memory stickerIds,
        uint256[] memory amounts,
        uint256[] memory prices,
        bool[] memory sellables,
        address[][] memory whitelists
    ) public {
        require(
            stickerIds.length == prices.length &&
                stickerIds.length == amounts.length &&
                stickerIds.length == sellables.length &&
                stickerIds.length == whitelists.length,
            "DMTPMarket: length not match"
        );
        for (uint256 i = 0; i < stickerIds.length; i++) {
            setStickerPrice(
                stickerIds[i],
                amounts[i],
                prices[i],
                sellables[i],
                whitelists[i]
            );
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
    function setStickerWhitelist(uint256 stickerId, address[] memory whitelist)
        public
        onlyMintRole
        onlyOwner(stickerId)
    {
        if (whitelist.length == 0) {
            delete _whitelist[stickerId];
            emit ClearWhitelist(stickerId);
        } else {
            _whitelist[stickerId].status = WhitelistStatus.Fixed;
            for (uint256 i = 0; i < whitelist.length; i++) {
                _whitelist[stickerId].whitelist[whitelist[i]] = true;
            }
            emit SetWhiteList(stickerId, joinAddress(whitelist));
        }
    }

    function setStickerWhitelistBatch(
        uint256[] memory stickerIds,
        address[][] memory whitelist
    ) public {
        require(
            stickerIds.length == whitelist.length,
            "DMTPMarket: stickerIds and whitelist length not match"
        );
        for (uint256 i = 0; i < stickerIds.length; i++) {
            setStickerWhitelist(stickerIds[i], whitelist[i]);
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
        require(
            _sticker.balanceOf(msg.sender, stickerId) == 0,
            "DMTPMarket: only own one sticker"
        );
        StickerPrice memory stickerPrice = _stickerPrice[stickerId];
        require(
            stickerPrice.amount > 0,
            "DMTPMarket: sticker amount not enough"
        );
        uint256 price = stickerPrice.price;

        _token.transferFrom(msg.sender, stickerPrice.seller, price);
        _sticker.safeTransferFrom(
            stickerPrice.seller,
            msg.sender,
            stickerId,
            1,
            ""
        );
        delete _stickerPrice[stickerId];
        delete _whitelist[stickerId];
        emit Buy(stickerId, msg.sender, _stickerPrice[stickerId].price);
    }

    function joinAddress(address[] memory addresses)
        private
        pure
        returns (string memory)
    {
        bytes memory output;

        for (uint256 i = 0; i < addresses.length; i++) {
            output = abi.encodePacked(
                output,
                ",",
                Strings.toHexString(addresses[i])
            );
        }

        return string(output);
    }
}

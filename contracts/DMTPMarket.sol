// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IDMTPMarket.sol";
import "./interfaces/ISticker.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DMTPMarket is AccessControl, IDMTPMarket {
    mapping(uint256 => Whitelist) private _whitelist;
    mapping(uint256 => Sticker) private _stickerData;
    mapping(uint256 => uint256) private _stickerAmountLeft;
    uint256 private _currentTokenID = 0;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ACCESS_STICKER_ROLE =
        keccak256("ACCESS_STICKER_ROLE");
    ISticker private _sticker;

    constructor(address adminAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(MINTER_ROLE, adminAddress);
    }

    function setSticker(address sticker) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_sticker == ISticker(address(0)), "DMTPMarket: ALREADY_SET");
        _sticker = ISticker(sticker);
        _grantRole(ACCESS_STICKER_ROLE, address(this));
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is missing `MINTER_ROLE`.
     */
    modifier onlyMintRole() {
        require(hasRole(MINTER_ROLE, msg.sender), "DMTPMarket: only minter");
        _;
    }

    /**
     * @dev Revert with a standard message if `sticker` is not sale.
     */
    modifier onlyStickerSale(uint256 stickerId) {
        require(
            _stickerData[stickerId].priceType != StickerPriceType.None,
            "DMTPMarket: sticker not for sale"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is not in whitelist to Buy sticker, in case sticker have whitelist.
     */
    modifier onlyWhitelist(uint256 stickerId) {
        if (_whitelist[stickerId].whitelistType == WhitelistType.Fixed)
            require(
                _whitelist[stickerId].whitelist[msg.sender],
                "DMTPMarket: not in whitelist"
            );
        _;
    }

    function setStickerPrice(
        string memory uri,
        uint256 amount,
        address token,
        uint256 price,
        bool sellable,
        address[] memory whitelist
    ) public override onlyMintRole {
        require(amount > 0, "DMTPMarket: sticker amount not enough");
        StickerPriceType priceType;
        if (sellable) {
            if (price > 0) priceType = StickerPriceType.Fixed;
            else priceType = StickerPriceType.Free;
        }
        _currentTokenID++;
        _stickerData[_currentTokenID] = Sticker(
            uri,
            priceType,
            token,
            price,
            msg.sender,
            amount
        );
        _stickerAmountLeft[_currentTokenID] = amount;
        if (whitelist.length != 0) {
            _whitelist[_currentTokenID].whitelistType = WhitelistType.Fixed;
            for (uint256 i = 0; i < whitelist.length; i++) {
                _whitelist[_currentTokenID].whitelist[whitelist[i]] = true;
            }
        }
        emit NewSticker(
            _currentTokenID,
            price,
            token,
            amount,
            priceType,
            _whitelist[_currentTokenID].whitelistType,
            joinAddress(whitelist)
        );
    }

    function setStickerPriceBatch(
        string[] memory stickerUris,
        uint256[] memory amounts,
        address[] memory tokens,
        uint256[] memory prices,
        bool[] memory sellables,
        address[][] memory whitelists
    ) public override onlyMintRole {
        require(
            stickerUris.length == prices.length &&
                stickerUris.length == amounts.length &&
                stickerUris.length == sellables.length &&
                stickerUris.length == whitelists.length,
            "DMTPMarket: length not match"
        );
        for (uint256 i = 0; i < stickerUris.length; i++) {
            setStickerPrice(
                stickerUris[i],
                amounts[i],
                tokens[i],
                prices[i],
                sellables[i],
                whitelists[i]
            );
        }
    }

    function stickerURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        return _stickerData[id].uri;
    }

    function stickerLeft(uint256 id) public view override returns (uint256) {
        return _stickerAmountLeft[id];
    }

    function buy(uint256 stickerId)
        external
        onlyStickerSale(stickerId)
        onlyWhitelist(stickerId)
    {
        require(
            _sticker.balanceOf(msg.sender, stickerId) == 0,
            "DMTPMarket: only own one sticker"
        );
        require(_stickerAmountLeft[stickerId] > 0, "DMTPMarket: sold out");
        _stickerAmountLeft[stickerId]--;
        Sticker memory sticker = _stickerData[stickerId];
        if (sticker.priceType == StickerPriceType.Fixed) {
            IERC20(sticker.token).transferFrom(
                msg.sender,
                sticker.seller,
                sticker.price
            );
        }
        _sticker.mint(stickerId, msg.sender, 1, sticker.uri);
        emit Buy(stickerId, msg.sender, sticker.price, sticker.token);
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

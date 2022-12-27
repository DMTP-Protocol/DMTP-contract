// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IDMTPMarket.sol";
import "./interfaces/ISticker.sol";

contract DMTPMarket is AccessControl, IDMTPMarket {
    mapping(uint256 => bytes32) private _whitelistTopHash;
    mapping(uint256 => Sticker) private _stickerData;
    mapping(uint256 => uint256) private _stickerAmountLeft;
    address private _holdTokenAddress;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ACCESS_STICKER_ROLE =
        keccak256("ACCESS_STICKER_ROLE");
    ISticker private _sticker;

    constructor(address adminAddress, address holdTokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(MINTER_ROLE, adminAddress);
        _holdTokenAddress = holdTokenAddress;
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
    modifier onlyStickerSale(uint256 tokenId) {
        require(
            _stickerData[tokenId].priceType != StickerPriceType.None,
            "DMTPMarket: sticker not for sale"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is not in whitelist to Buy sticker, in case sticker have whitelist.
     */
    modifier onlyWhitelist(bytes32[] memory _merkleProof, uint256 tokenId) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _whitelistTopHash[tokenId], leaf),
            "Invalid Merkle Proof."
        );
        _;
    }

    function setStickerPrice(
        uint256 tokenId,
        string memory uri,
        uint256 amount,
        address token,
        uint256 price,
        bool sellable,
        bytes32 whitelist
    ) public override onlyMintRole {
        require(amount > 0, "DMTPMarket: sticker amount not enough");
        StickerPriceType priceType;
        if (sellable) {
            if (price > 0) priceType = StickerPriceType.Fixed;
            else priceType = StickerPriceType.Free;
        }
        _stickerData[tokenId] = Sticker(uri, priceType, token, price, amount);
        _stickerAmountLeft[tokenId] = amount;
        _whitelistTopHash[tokenId] = whitelist;
        emit NewSticker(tokenId, price, token, amount, priceType, whitelist);
    }

    function setStickerPriceBatch(
        uint256[] memory tokenIds,
        string[] memory tokenUris,
        uint256[] memory amounts,
        address[] memory tokens,
        uint256[] memory prices,
        bool[] memory sellables,
        bytes32[] memory whitelists
    ) public override onlyMintRole {
        require(
            tokenUris.length == prices.length &&
                tokenUris.length == amounts.length &&
                tokenUris.length == sellables.length &&
                tokenUris.length == whitelists.length,
            "DMTPMarket: length not match"
        );
        for (uint256 i = 0; i < tokenUris.length; i++) {
            setStickerPrice(
                tokenIds[i],
                tokenUris[i],
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

    function buy(uint256 tokenId, bytes32[] memory _merkleProof)
        external
        override
        onlyStickerSale(tokenId)
        onlyWhitelist(_merkleProof, tokenId)
    {
        require(
            _sticker.balanceOf(msg.sender, tokenId) == 0,
            "DMTPMarket: only own one sticker"
        );
        require(_stickerAmountLeft[tokenId] > 0, "DMTPMarket: sold out");
        _stickerAmountLeft[tokenId]--;
        Sticker memory sticker = _stickerData[tokenId];
        if (sticker.priceType == StickerPriceType.Fixed) {
            require(
                IERC20(sticker.token).transferFrom(
                    msg.sender,
                    _holdTokenAddress,
                    sticker.price
                ),
                "DMTPMarket: transfer failed"
            );
        }
        _sticker.mint(tokenId, msg.sender, 1, sticker.uri);
        emit Buy(tokenId, msg.sender, sticker.price, sticker.token);
    }
}

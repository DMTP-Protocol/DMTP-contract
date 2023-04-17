// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IDMTPMarket.sol";
import "./interfaces/ISticker.sol";

contract DMTPMarket is AccessControl, IDMTPMarket {
    mapping(uint256 => Sticker) private _stickerData;
    address private _holdTokenAddress;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    ISticker private _sticker;

    constructor(address adminAddress, address holdTokenAddress,address sticker) {
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(MINTER_ROLE, adminAddress);
        _holdTokenAddress = holdTokenAddress;
        _sticker = ISticker(sticker);

    }

    function setHoldTokenAddress(address newHoldeTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _holdTokenAddress = newHoldeTokenAddress;
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
    modifier onlyWhitelist(bytes32[] calldata _merkleProof, uint256 tokenId) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            _stickerData[tokenId].whitelistTopHash == bytes32(0) ||
                MerkleProof.verify(
                    _merkleProof,
                    _stickerData[tokenId].whitelistTopHash,
                    leaf
                ),
            "Invalid Merkle Proof"
        );
        _;
    }

    function listSticker(
        uint256 tokenId,
        string calldata uri,
        uint256 amount,
        address token,
        uint256 price,
        bytes32 whitelistTopHash
    ) public override onlyMintRole {
        require(token != address(0), "DMTPMarket: token address is zero");
        require(
            _stickerData[tokenId].token == address(0),
            "DMTPMarket: sticker already for sale"
        );
        require(amount > 0, "DMTPMarket: sticker amount not enough");
        StickerPriceType priceType = price > 0
            ? StickerPriceType.Fixed
            : StickerPriceType.Free;

        _stickerData[tokenId] = Sticker(
            uri,
            priceType,
            token,
            price,
            amount,
            whitelistTopHash,
            amount
        );
        emit NewSticker(
            tokenId,
            price,
            token,
            amount,
            priceType,
            whitelistTopHash
        );
    }

    function listStickerBatch(
        uint256[] calldata tokenIds,
        string[] calldata tokenUris,
        uint256[] calldata amounts,
        address[] calldata tokens,
        uint256[] calldata prices,
        bytes32[] calldata whitelistTopHashs
    ) public override onlyMintRole {
        require(
            tokenUris.length == prices.length &&
                tokenUris.length == amounts.length &&
                tokenUris.length == whitelistTopHashs.length,
            "DMTPMarket: length not match"
        );
        for (uint256 i = 0; i < tokenUris.length; i++) {
            listSticker(
                tokenIds[i],
                tokenUris[i],
                amounts[i],
                tokens[i],
                prices[i],
                whitelistTopHashs[i]
            );
        }
    }

    function disableListedSticker(uint256 tokenId) public onlyMintRole {
        require(
            _stickerData[tokenId].priceType != StickerPriceType.None,
            "DMTPMarket: sticker not for sale"
        );
        _stickerData[tokenId].priceType = StickerPriceType.None;
        emit DisableSticker(tokenId);
    }

    function disableListedStickerBatch(
        uint256[] calldata tokenIds
    ) public onlyMintRole {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            disableListedSticker(tokenIds[i]);
        }
    }

    function enableListedSticker(uint256 tokenId) public onlyMintRole {
        require(
            _stickerData[tokenId].priceType == StickerPriceType.None,
            "DMTPMarket: sticker already for sale"
        );
        _stickerData[tokenId].priceType = _stickerData[tokenId].price > 0
            ? StickerPriceType.Fixed
            : StickerPriceType.Free;
        emit EnableSticker(tokenId);
    }

    function enableListedStickerBatch(
        uint256[] calldata tokenIds
    ) public onlyMintRole {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            enableListedSticker(tokenIds[i]);
        }
    }

    function stickerData(uint256 id) public view returns (Sticker memory) {
        return _stickerData[id];
    }

    function buy(
        uint256 tokenId,
        bytes32[] calldata _merkleProof
    )
        external
        override
        onlyStickerSale(tokenId)
        onlyWhitelist(_merkleProof, tokenId)
    {
        require(
            _sticker.balanceOf(msg.sender, tokenId) == 0,
            "DMTPMarket: only own one sticker"
        );
        Sticker storage sticker = _stickerData[tokenId];
        require(sticker.amountLeft > 0, "DMTPMarket: sold out");
        sticker.amountLeft = sticker.amountLeft - 1;
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

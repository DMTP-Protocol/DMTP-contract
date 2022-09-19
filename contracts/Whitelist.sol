// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) private _whitelist;
    mapping(address => mapping(uint256 => bool)) private _tokenWasBought;
    mapping(uint256 => uint256) private _stickerPrice;
    uint256 private _endTimestamp;
    IERC20 private _token;
    IERC1155 private _sticker;

    constructor(
        address[] memory whitelist,
        address token,
        address sticker,
        uint256 endTimestamp
    ) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            _whitelist[whitelist[i]] = true;
        }
        _token = IERC20(token);
        _sticker = IERC1155(sticker);
        _endTimestamp = endTimestamp;
    }

    modifier onlyWhitelisted() {
        require(
            isWhitelisted(msg.sender),
            "Whitelist: caller is not on the whitelist"
        );
        _;
    }

    modifier onlyNotExpired() {
        require(
            block.timestamp < _endTimestamp,
            "Whitelist: whitelist is expired"
        );
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function addWhitelist(address account) public onlyOwner onlyNotExpired {
        _whitelist[account] = true;
    }

    function removeWhitelist(address account) public onlyOwner onlyNotExpired {
        _whitelist[account] = false;
    }

    function setStickerPrice(uint256 id, uint256 price)
        public
        onlyOwner
        onlyNotExpired
    {
        _stickerPrice[id] = price;
    }

    function setStickerPriceBatch(uint256[] memory ids, uint256[] memory prices)
        public
        onlyOwner
        onlyNotExpired
    {
        for (uint256 i = 0; i < ids.length; i++) {
            _stickerPrice[ids[i]] = prices[i];
        }
    }

    function getStickerPrice(uint256 id) public view returns (uint256) {
        return _stickerPrice[id];
    }

    function getStickerPriceBatch(uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            prices[i] = _stickerPrice[ids[i]];
        }
        return prices;
    }

    function buySticker(uint256 id) public onlyWhitelisted onlyNotExpired {
        uint256 price = _stickerPrice[id];
        require(price > 0, "Sticker not for sale now");
        require(
            _tokenWasBought[msg.sender][id],
            "You already bought this sticker"
        );
        _tokenWasBought[msg.sender][id] = true;
        _token.transferFrom(msg.sender, address(this), price);
        _sticker.safeTransferFrom(address(this), msg.sender, id, 1, "");
    }

    function isStickerBought(address account, uint256 id)
        public
        view
        returns (bool)
    {
        return _tokenWasBought[account][id];
    }

    function claimToken() public onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
}

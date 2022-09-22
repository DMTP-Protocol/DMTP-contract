// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DMTPMarket is Ownable {
    mapping(uint256 => mapping(address => bool)) private _whitelist;
    mapping(uint256 => uint256) private _stickerPrice;
    IERC20 private _token;
    IERC721 private _sticker;

    constructor(address token, address sticker) {
        _token = IERC20(token);
        _sticker = IERC721(sticker);
    }
}

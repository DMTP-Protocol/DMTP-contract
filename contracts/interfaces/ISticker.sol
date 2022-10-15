// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISticker is IERC1155 {
    function mint(
        uint256 id,
        address account,
        uint256 amount,
        string memory _uri
    ) external;

    function mintBatch(
        uint256[] memory ids,
        address to,
        uint256[] memory amounts,
        string[] memory uris
    ) external;
}

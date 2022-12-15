// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDMTPMessages {
    function sendMessages(address _from, address _to, string memory _message) external;
    function setDelegator(address _delegator) external;
    function deleteDelegator(address _delegator) external;
}

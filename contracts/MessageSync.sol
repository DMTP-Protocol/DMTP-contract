// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MessageSync{
    struct message {
        address sender;
        string cid;
    }
    mapping(address => message[]) private syncMessage;
    // string[] private sync;
    uint256 private awardValue;

    function setAwardValue(uint256 _awardValue) public {
        awardValue = _awardValue;
    }

    function getAwardValue() public view returns(uint256){
        return awardValue;
    }

    function setSyncMessage(message[] memory syncList) public {
        syncMessage.
    }
}
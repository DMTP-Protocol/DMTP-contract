// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DMTPMessages{
  mapping(address => mapping(address => bool)) delegators;

  event DelgetorSet(address indexed wallet, address indexed delegator);
  event DelgetorDelete(address indexed wallet, address indexed delegator);
  event MessageSent(address indexed from, address indexed to, bytes message);

  function setDelegator(address _delegator) external{
    delegators[msg.sender][_delegator] = true;
    emit DelgetorSet(msg.sender, _delegator);
  }

  function deleteDelegator(address _delegator) external {
    delegators[msg.sender][_delegator] = false;
    emit DelgetorDelete(msg.sender, _delegator);
  }

  function isDelegator(address _owner, address _delegator) public view returns(bool) {
    return delegators[_owner][_delegator];
  }

  function sendMessages(address _from, address _to, string memory _message) external {
    require(delegators[_from][msg.sender] == true || msg.sender == _from, "DMTPMessages : Invalid delegators");
    bytes memory data = abi.encodePacked(_message);
    emit MessageSent(msg.sender, _to, data);
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract DMTPCid is Ownable {
    mapping(address => string) private DMTPkeys;
    string[] private cids;

    event AddKey(address indexed wallet, string cid);
    event AddCid(string cid);

    function addKey(address _user, string memory _cid) public onlyOwner {
        DMTPkeys[_user] = _cid;
    }

    function storeCID(string memory _cid) public onlyOwner {
        cids.push(_cid);
    }

    function getKeys(address _user) public view returns (string memory) {
        return DMTPkeys[_user];
    }

    function getCids() public view returns (string[] memory) {
        return cids;
    }

    function getCid(uint256 index) public view returns (string memory) {
        return cids[index];
    }
}

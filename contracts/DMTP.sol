// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DMTP is ERC20 {
    constructor() ERC20("DMTP", "DMTP") {
        _mint(
            0x5442d67C172e7eE94b755B2E3CA3529805B1c607,
            1000000000 * 10 ** decimals()
        );
    }
}

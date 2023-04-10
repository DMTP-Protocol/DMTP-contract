const { expect } = require("chai");
const { BN } = require("bn.js");

// Import utilities from Test Helpers
const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { ethers: etherjs } = require("ethers");

describe("Token contract", function () {
  let dmtp;
  beforeEach(async function () {
    const DMTP = await ethers.getContractFactory("DMTP");
    dmtp = await DMTP.deploy();
  });

  it("totalSupply should be 1000000000 ether", async function () {
    const value = etherjs.utils.parseEther("1000000000");
    expect(await dmtp.totalSupply()).equal(value);
  });
});

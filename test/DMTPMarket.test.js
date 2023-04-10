const { expect } = require("chai");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { ethers: etherjs } = require("ethers");

const BYTES32_ZERO = etherjs.utils.hexZeroPad(etherjs.utils.hexlify(0), 32);

const getHexProof = (whitelistAddresses, checkingAddress) => {
  const allNodes = whitelistAddresses.map((addr) =>
    keccak256(addr.toLowerCase())
  );
  const merkleTree = new MerkleTree(allNodes, keccak256, { sortPairs: true });
  const hexProof = merkleTree.getHexProof(keccak256(checkingAddress));
  return hexProof;
};

const getRootHash = (whitelistAddresses) => {
  const allNodes = whitelistAddresses.map((addr) =>
    keccak256(addr.toLowerCase())
  );
  const merkleTree = new MerkleTree(allNodes, keccak256, { sortPairs: true });
  const rootHash = merkleTree.getRoot().toString("hex");
  return `0x${rootHash}`;
};

describe("Market contract", function () {
  let dmtpMarket;
  let dmtpSticker;
  let dmtp;
  let admin;
  let adminAddress;
  let client;
  let clientAddress;
  let holdTokenAddress = etherjs.Wallet.createRandom().address;
  let maticWETH;

  const whitelistAddresses = [
    "0X5B38DA6A701C568545DCFCB03FCB875F56BEDDC4",
    "0X5A641E5FB72A2FD9137312E7694D42996D689D99",
    "0XDCAB482177A592E424D1C8318A464FC922E8DE40",
    "0X6E21D37E07A6F7E53C7ACE372CEC63D4AE4B6BD0",
    "0X09BAAB19FC77C19898140DADD30C4685C597620B",
    "0XCC4C29997177253376528C05D3DF91CF2D69061A",
    "0xdD870fA1b7C4700F2BD7f44238821C26f7392148",
  ];

  const listNFT = async (
    stickerId,
    price,
    amount,
    token,
    uri,
    whitelists = []
  ) => {
    const whitelistTopHash =
      whitelists.length > 0 ? getRootHash(whitelists) : BYTES32_ZERO;
    await dmtpMarket.listSticker(
      stickerId,
      uri,
      amount,
      token,
      price,
      whitelistTopHash
    );
    const stickerData = await dmtpMarket.stickerData(stickerId);
    expect(stickerData["uri"]).to.equal(uri);
    expect(stickerData["priceType"]).to.equal(1);
    expect(stickerData["token"]).to.equal(token);
    expect(stickerData["price"]).to.equal(price);
    expect(stickerData["amount"]).to.equal(amount);
    expect(stickerData["whitelistTopHash"]).to.equal(whitelistTopHash);
    expect(stickerData["amountLeft"]).to.equal(amount);
  };

  const buyNFT = async (stickerId, price, amount, token, whitelists = []) => {
    const tokenContract = token == dmtp.address ? dmtp : maticWETH;
    await tokenContract.transfer(clientAddress, price);
    await tokenContract.connect(client).approve(dmtpMarket.address, price);
    const buyResult = await dmtpMarket
      .connect(client)
      .buy(
        stickerId,
        whitelists.length > 0 ? getHexProof(whitelists, clientAddress) : []
      );
    expect(buyResult).ok;
    const stickerDataAfterBought = await dmtpMarket.stickerData(stickerId);
    expect(stickerDataAfterBought["amountLeft"]).to.equal(`${amount - 1}`);
  };

  const checkOwner = async (stickerId, owner) => {
    expect(await dmtpSticker.balanceOf(owner, stickerId)).to.equal("1");
  };

  beforeEach(async function () {
    const MaticWETH = await ethers.getContractFactory("MaticWETH");
    const DMTPMarket = await ethers.getContractFactory("DMTPMarket");
    const DMTPSticker = await ethers.getContractFactory("DMTPSticker");
    const DMTP = await ethers.getContractFactory("DMTP");
    [admin, client] = await ethers.getSigners();
    adminAddress = admin.address;
    clientAddress = client.address;
    maticWETH = await MaticWETH.deploy();
    dmtp = await DMTP.deploy();
    dmtpMarket = await DMTPMarket.deploy(adminAddress, holdTokenAddress);
    dmtpSticker = await DMTPSticker.deploy();
    await dmtpMarket.setSticker(dmtpSticker.address);
    await dmtpSticker.setMarket(dmtpMarket.address);
  });

  it("list Sticker: id 1 - price 1 DMTP - amount 10 - no whitelist | Client buy", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";
    await listNFT(stickerId, price, amount, dmtp.address, uri);
    await buyNFT(stickerId, price, amount, dmtp.address);
    await checkOwner(stickerId, clientAddress);
  });

  it("list Sticker: id 1 - price 1 WETH - amount 10 - no whitelist | Client buy", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";
    await listNFT(stickerId, price, amount, maticWETH.address, uri);
    await buyNFT(stickerId, price, amount, maticWETH.address);
    await checkOwner(stickerId, clientAddress);
  });

  it("list Sticker: id 1 - price 1 DMTP - amount 10 - with whitelist | Client buy", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";

    const whitelistIncludeClient = [...whitelistAddresses, clientAddress];
    await listNFT(
      stickerId,
      price,
      amount,
      dmtp.address,
      uri,
      whitelistIncludeClient
    );
    await buyNFT(
      stickerId,
      price,
      amount,
      dmtp.address,
      whitelistIncludeClient
    );
    await checkOwner(stickerId, clientAddress);
  });

  it("list Sticker: id 1 - price 1 WETH - amount 10 - with whitelist | Client buy", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";

    const whitelistIncludeClient = [...whitelistAddresses, clientAddress];
    await listNFT(
      stickerId,
      price,
      amount,
      maticWETH.address,
      uri,
      whitelistIncludeClient
    );
    await buyNFT(
      stickerId,
      price,
      amount,
      maticWETH.address,
      whitelistIncludeClient
    );
    await checkOwner(stickerId, clientAddress);
  });

  it("list Sticker: id 1 - price 1 DMTP - amount 10 - with whitelist | Client not in whitelist", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";

    const whitelistNotIncludeClient = [...whitelistAddresses];
    await listNFT(
      stickerId,
      price,
      amount,
      dmtp.address,
      uri,
      whitelistNotIncludeClient
    );
    await expect(
      buyNFT(stickerId, price, amount, dmtp.address, whitelistNotIncludeClient)
    ).to.be.revertedWith("Invalid Merkle Proof");
  });

  it("list Sticker: id 1 - price 1 WETH - amount 10 - with whitelist | Client not in whitelist", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";

    const whitelistNotIncludeClient = [...whitelistAddresses];
    await listNFT(
      stickerId,
      price,
      amount,
      maticWETH.address,
      uri,
      whitelistNotIncludeClient
    );
    await expect(
      buyNFT(
        stickerId,
        price,
        amount,
        maticWETH.address,
        whitelistNotIncludeClient
      )
    ).to.be.revertedWith("Invalid Merkle Proof");
  });

  it("list Sticker: id 1 - price 1 DMTP - amount 10 - with whitelist | disable sticker | Client cant not buy disable sticker", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";

    const whitelistIncludeClient = [...whitelistAddresses, clientAddress];
    await listNFT(
      stickerId,
      price,
      amount,
      dmtp.address,
      uri,
      whitelistIncludeClient
    );
    await dmtpMarket.disableListedSticker(stickerId);
    await expect(
      buyNFT(stickerId, price, amount, dmtp.address, whitelistIncludeClient)
    ).to.be.revertedWith("DMTPMarket: sticker not for sale");
  });

  it("list Sticker: id 1 - price 1 DMTP - amount 10 - with whitelist | disable sticker | Client cant not buy disable sticker | enable sticker | Client can buy sticker", async function () {
    const stickerId = 1;
    const price = etherjs.utils.parseEther("1");
    const amount = 10;
    const uri = "ipfs://Q";

    const whitelistIncludeClient = [...whitelistAddresses, clientAddress];
    await listNFT(
      stickerId,
      price,
      amount,
      dmtp.address,
      uri,
      whitelistIncludeClient
    );
    await dmtpMarket.disableListedSticker(stickerId);
    await expect(
      buyNFT(stickerId, price, amount, dmtp.address, whitelistIncludeClient)
    ).to.be.revertedWith("DMTPMarket: sticker not for sale");

    await dmtpMarket.enableListedSticker(stickerId);
    await buyNFT(
      stickerId,
      price,
      amount,
      dmtp.address,
      whitelistIncludeClient
    );
    await checkOwner(stickerId, clientAddress);
  });
});

require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  // const DMTP = await ethers.getContractFactory("DMTP");
  const Sticker = await ethers.getContractFactory("DMTPSticker");
  const DMTPMarket = await ethers.getContractFactory("DMTPMarket");

  // deploy contracts
  // const dmtp = await DMTP.deploy();
  const sticker = await Sticker.deploy();
  const dmtpmarket = await DMTPMarket.deploy(
    deployer.address,
    deployer.address
  );
  await sticker.deployed();
  await dmtpmarket.deployed();
  await dmtpmarket.setSticker(sticker.address);
  await sticker.setMarket(dmtpmarket.address);

  // const dmtpJson = require("../artifacts/contracts/DMTP.sol/DMTP.json");
  const dmtpStickerJson = require("../artifacts/contracts/DMTPSticker.sol/DMTPSticker.json");
  const dmtpMarketJson = require("../artifacts/contracts/DMTPMarket.sol/DMTPMarket.json");
  const contractDeployed = {
    // DMTP: {
    //   address: dmtp.address,
    //   abi: dmtpJson.abi,
    //   contractName: dmtpJson.contractName,
    //   input: [],
    // },
    DMTPSticker: {
      address: sticker.address,
      abi: dmtpStickerJson.abi,
      contractName: dmtpStickerJson.contractName,
      input: [],
    },
    DMTPMarket: {
      address: dmtpmarket.address,
      abi: dmtpMarketJson.abi,
      contractName: dmtpMarketJson.contractName,
      input: [
        "0x5442d67C172e7eE94b755B2E3CA3529805B1c607",
        "0x5442d67C172e7eE94b755B2E3CA3529805B1c607",
      ],
    },
  };

  fs.writeFileSync(
    "./sticker-market-abi.json",
    JSON.stringify(contractDeployed)
  );
  // log deploy contracts
  Object.values(contractDeployed).forEach((contract) => {
    console.log(
      `The contract ${contract.contractName} has been deployed to: ${contract.address}`
    );
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

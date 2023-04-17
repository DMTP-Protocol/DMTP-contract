require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
async function main() {
  const [deployer] = await ethers.getSigners();
  const adminAddress = "0x5442d67C172e7eE94b755B2E3CA3529805B1c607";
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const Sticker = await ethers.getContractFactory("DMTPSticker");
  const DMTPMarket = await ethers.getContractFactory("DMTPMarket");

  // deploy contracts
  const sticker = await Sticker.deploy();
  console.log("Sticker address: ", sticker.address);
  const dmtpmarket = await DMTPMarket.deploy(
    adminAddress,
    adminAddress,
    sticker.address
  );
  console.log("DMTPMarket address: ", dmtpmarket.address);
  await sticker.deployed();
  console.log("Sticker deployed to:", sticker.address);
  await dmtpmarket.deployed();
  console.log("DMTPMarket deployed to:", dmtpmarket.address);
  await sticker.setMarket(dmtpmarket.address);
  console.log("DMTPMarket address set to Sticker");
  await sticker.transferOwnership(adminAddress);
  console.log("Sticker ownership transferred to admin");

  const dmtpStickerJson = require("../artifacts/contracts/DMTPSticker.sol/DMTPSticker.json");
  const dmtpMarketJson = require("../artifacts/contracts/DMTPMarket.sol/DMTPMarket.json");
  const contractDeployed = {
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
      input: [adminAddress, adminAddress, sticker.address],
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

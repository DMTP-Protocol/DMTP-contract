require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const DMTP = await ethers.getContractFactory("DMTP");
  const Sticker = await ethers.getContractFactory("DMTPSticker");
  const DMTPMarket = await ethers.getContractFactory("DMTPMarket");

  // deploy contracts
  const dmtp = await DMTP.deploy();
  const sticker = await Sticker.deploy();
  const dmtpmarket = await DMTPMarket.deploy(
    deployer.address,
    deployer.address
  );
  await sticker.deployed();
  await dmtpmarket.deployed();
  await dmtpmarket.setSticker(sticker.address);
  await sticker.setMarket(dmtpmarket.address);

  const contractDeployed = {
    DMTP: {
      address: dmtp.address,
      abi: require("../build/contracts/DMTP.json").abi,
      contractName: require("../build/contracts/DMTP.json").contractName,
    },
    DMTPSticker: {
      address: sticker.address,
      abi: require("../build/contracts/DMTPSticker.json").abi,
      contractName: require("../build/contracts/DMTPSticker.json").contractName,
      input: [],
    },
    DMTPMarket: {
      address: dmtpmarket.address,
      abi: require("../build/contracts/DMTPMarket.json").abi,
      contractName: require("../build/contracts/DMTPMarket.json").contractName,
      input: [deployer.address, deployer.address],
    },
  };

  fs.writeFileSync("./sticker-market-abi.json", JSON.stringify(contractDeployed));
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

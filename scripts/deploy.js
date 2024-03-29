require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const DMTP = await ethers.getContractFactory("DMTP");
  const stDMTP = await ethers.getContractFactory("stDMTP");
  const Sticker = await ethers.getContractFactory("Sticker");
  const DMTPMarket = await ethers.getContractFactory("DMTPMarket");

  // deploy contracts
  const dmtp = await DMTP.deploy();
  const stdmtp = await stDMTP.deploy();
  const dmtpmarket = await DMTPMarket.deploy(
    deployer.address,
    deployer.address
  );
  const sticker = await Sticker.deploy(dmtpmarket.address);

  await sticker.deployed();
  await dmtpmarket.deployed();
  await dmtpmarket.setSticker(sticker.address);

  const contractDeployed = {
    DMTP: {
      address: dmtp.address,
      abi: require("../build/contracts/DMTP.json").abi,
      contractName: require("../build/contracts/DMTP.json").contractName,
    },
    stDMTP: {
      address: stdmtp.address,
      abi: require("../build/contracts/stDMTP.json").abi,
      contractName: require("../build/contracts/stDMTP.json").contractName,
    },
    Sticker: {
      address: sticker.address,
      abi: require("../build/contracts/Sticker.json").abi,
      contractName: require("../build/contracts/Sticker.json").contractName,
      input: [dmtpmarket.address],
    },
    DMTPMarket: {
      address: dmtpmarket.address,
      abi: require("../build/contracts/DMTPMarket.json").abi,
      contractName: require("../build/contracts/DMTPMarket.json").contractName,
      input: [deployer.address, deployer.address],
    },
  };

  fs.writeFileSync("./config.json", JSON.stringify(contractDeployed));
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

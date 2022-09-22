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
  const Whitelist = await ethers.getContractFactory("Whitelist");

  // deploy lockdata contracts
  const dmtp = await DMTP.deploy();
  const stdmtp = await stDMTP.deploy();
  const sticker = await Sticker.deploy();
  // const whitelist = await Whitelist.deploy(
  //   process.env.WHITELIST_ADDRESS.split(","),
  //   process.env.WHITELIST_TOKEN_ADDRESS,
  //   sticker.address,
  //   process.env.WHITELIST_ENDTIME
  // );

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
    },
    // Whitelist: {
    //   address: whitelist.address,
    //   abi: require("../build/contracts/Whitelist.json").abi,
    //   contractName: require("../build/contracts/Whitelist.json").contractName,
    // },
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

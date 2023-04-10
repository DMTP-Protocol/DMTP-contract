require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const DMTPCid = await ethers.getContractFactory("DMTPCid");

  // deploy contracts
  const dmtpCid = await DMTPCid.deploy();

  await dmtpCid.deployed();

  const contractDeployed = {
    DMTPCid: {
      address: dmtpCid.address,
      abi: require("../build/contracts/DMTPCid.json").abi,
      contractName: require("../build/contracts/DMTPCid.json").contractName,
    },
  };

  fs.writeFileSync("./cid-abi.json", JSON.stringify(contractDeployed));
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

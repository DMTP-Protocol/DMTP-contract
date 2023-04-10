require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const API_KEY = process.env.API_KEY;
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
      },
    },
  },
  networks: {
    polygon: {
      url: process.env.NETWORK_RPC,
      accounts: [`${PRIVATE_KEY}`],
      gasPrice: 35000000000,
    },
  },
  etherscan: {
    apiKey: API_KEY,
  },
  gasReporter: {
    currency: "USD",
  },
};

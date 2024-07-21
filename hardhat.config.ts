require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv/config");

const accounts = [process.env.DEV_WALLET_PRIVATE_KEY];

module.exports = {
  solidity: {
    compilers: [{
      version: "0.8.24",
      settings: {
        viaIR: true,
      },
    }],
  },
  networks: {
    base: {
      url: "https://mainnet.base.org",
      accounts,
      chainId: 8453,
      gasPrice: 1000000000,
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY,
    },
  },
};

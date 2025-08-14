require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

const { RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;

module.exports = {
  solidity: "0.8.20",
  networks: {
    mainnet: {
      url: RPC_URL,
      accounts: [PRIVATE_KEY]
    },
    rinkeby: {
      url: RPC_URL,
      accounts: [PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  }
};

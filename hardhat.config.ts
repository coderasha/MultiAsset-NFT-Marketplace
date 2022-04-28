import { config } from "dotenv";
config({
  path: '.env'
})

import { HardhatUserConfig } from "hardhat/types";

import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import "solidity-coverage";
// import "hardhat-gas-reporter";

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const RINKEBY_API_KEY = process.env.RINKEBY_API_KEY || "";
const MAINNET_API_KEY = process.env.MAINNET_API_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY || "";
const POLYGON_API_KEY = process.env.POLYGON_API_KEY || "";

const hardhatConfig: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.8.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  networks: {
    hardhat: {},
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${RINKEBY_API_KEY}`,
      gasPrice: 1000000000,
      accounts: [PRIVATE_KEY],
    },
    bscTest: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      gasPrice: 20000000000,
      accounts: [PRIVATE_KEY],
    },
    bscMain: {
      url: "https://bsc-dataseed.binance.org/",
      gasPrice: 20000000000,
      accounts: [PRIVATE_KEY],
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${MAINNET_API_KEY}`,
      gasPrice: 75000000000,
      accounts: [PRIVATE_KEY],
    },
    coverage: {
      url: "http://127.0.0.1:8555", // Coverage launches its own ganache-cli client
    },
  },
  etherscan: {
    apiKey: {
      // For all ethereum networks
      mainnet: ETHERSCAN_API_KEY,
      rinkeby: ETHERSCAN_API_KEY,
      // For all binance smart chain networks
      bsc: BSCSCAN_API_KEY,
      bscTestnet: BSCSCAN_API_KEY,
      // For all polygon networks
      polygon: POLYGON_API_KEY,
      polygonMumbai: POLYGON_API_KEY,
    }
  },
  // gasReporter: {
  //   currency: 'USDT',
  //   coinmarketcap: '16213b75-c15e-4923-8de3-bebe91f7c707',
  // },
};

export default hardhatConfig;

const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();
const { mnemonic, BSCSCANAPIKEY} = require('./env.json');
module.exports = {
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: BSCSCANAPIKEY
  },
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard BSC port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    bscTestnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true,
      from: '0xB5F402fA52386bD88280c730C323BE178cc5c4b6'
    },
    bsc: {
      provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed.binance.org`),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      from: '0xB5F402fA52386bD88280c730C323BE178cc5c4b6'
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "^0.6.12", // A version or constraint - Ex. "^0.5.0"
    }
  }
}
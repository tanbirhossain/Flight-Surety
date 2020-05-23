var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic =
  "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 5000000,
    }
    // ,
    // mynetwork: {
    //   provider: function () {
    //     return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
    //   },
    //   network_id: "*",
    //   gas: 9999999,
    // },
  },

  compilers: {
    solc: {
      version: "^0.4.24",
    },
  },
};



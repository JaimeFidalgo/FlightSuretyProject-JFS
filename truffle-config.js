var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "";
const fs = require('fs');


module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      gas: 4500000
    },
    
  },
  compilers: {
    solc: {
      version: "^0.5.0"
    }
  }
};

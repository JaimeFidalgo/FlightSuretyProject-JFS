# FlightSurety Project

This project is part of the UDACITY BLOCKCHAIN DEVELOPER BOOTCAMP. The content in this repository has been developed starting out from a project scaffoldig provided by Udacity team under MIT license. In any case may the owner of this repository get any credit in that regard.

## Requisites

Truffle v5.4.22
Solidity v0.5.0 (solc-js)
Node v10.24.1
Web3.js v1.0.0-beta.37

## Install

Run Ganache trough GanacheGUI or client. The workspace must have at least 50 accounts. The mnemonic and port id must be copied in the truffle-config.js file (GUI case)

To install node_modules run:

`npm install`

To compile the contracts run:

`truffle compile`

## Testing

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

## Migration

To migrate the contract to your private blockchain run:

`truffle migrate --reset`

## Develop client

To access the UI, in a separated shell run:

`npm run dapp`

To access the UI, in your browser, go to http://localhost:8000

## Develop server

To run the server, in a separated shell run:

`npm run server`

## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)






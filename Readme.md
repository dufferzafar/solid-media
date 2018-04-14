
# Media.sol

An Ethereum smart contract for licensed media distribution. 

## Stack

* [Solidity](http://solidity.readthedocs.io/en/v0.4.21/) for the core smart contract code.
* [Truffle](https://github.com/trufflesuite/truffle) to manage the dev environment.
* [Ganache](http://truffleframework.com/ganache/) to run a local Ethereum testnet.
* [MetaMask](https://metamask.io/) as the bridge between the browser and the dapp?
* General HTML/CSS (Bootstrap)/JS for the Web UI.

## Building

```bash
git clone https://github.com/dufferzafar/solid-media
cd solid-media

make install

# Run Ganache!

make tmr

make test
```

## Resources

[Tutorial on an election app](https://www.youtube.com/watch?v=3681ZYbDSSk)

[Code from the tutorial](https://github.com/dappuniversity/election)

Off-chain processing:

- https://medium.com/hello-sugoi/ethereum-communicating-with-the-off-chain-world-789fea13163b

- [Crypto](https://github.com/pubkey/eth-crypto)

- https://ethereum.stackexchange.com/questions/3092/how-to-encrypt-a-message-with-the-public-key-of-an-ethereum-address

- https://ethereum.stackexchange.com/questions/15442/whats-a-recommended-way-to-pass-secret-in-solidity

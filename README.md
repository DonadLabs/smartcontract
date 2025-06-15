# Donad Smart Contract - Monad Donation Platform

![./img/logo_center.webp](./img/logo_center.webp)

### Pain Point

1. Transaksi dari fundraiser tidak terintegrasi sehingga struggle untuk transparan

### Solution

1. Reputasi untuk fundraiser => 
    a. Menentukan apakah fundraiser bisa melakukan fundraise
    b. Membantu donatur untuk menentukan fundraiser yang layak
2. Reputasi untuk donatur =>
    a. Donatur memiki reputasi berdasarkan total donasi yang dilakukan di dalam platform
    b. Reputasi pada Donatur menentukan mereka bisa menjadi Fundraiser atau tidak
3. Transparansi transaksi oleh fundraiser dilaporkan sebagai laporan keuangan pada fundraising tersebut
4. Dana hanya bisa ditarik sesuai tenggat waktu
5. Dana tersimpan di sc biar mudah track transaksinya

### Pitch Deck

https://www.canva.com/design/DAGqY6XrGOY/liKGLt8Er5pwoQsx4PmQjg/view

### Team

1. Donad logo (Joan)
2. FE (Lead Leo, team Joan)
3. Smart Contract (Lead Han, team Bento)

### Smart Contract

| Name        | Type   | Contract Address |  
| ----------- | ------ | ---------------- |
| DonToken    | ERC20  | [0xC8897AEb22C494f8Aa427Bf5ba41737Bc29449BC](https://testnet.monadexplorer.com/address/0xC8897AEb22C494f8Aa427Bf5ba41737Bc29449BC) |
| DonDonorNFT | ERC721 | [0x66D0FDd17A2acFd9168a3E2cA6e30D99DEd58eC3](https://testnet.monadexplorer.com/address/0x66D0FDd17A2acFd9168a3E2cA6e30D99DEd58eC3)
| DonFundraiserNFT | ERC721 | [0x516873A1F9f49C26F155370807FfD3519C35aDb4](https://testnet.monadexplorer.com/address/0x516873A1F9f49C26F155370807FfD3519C35aDb4)

Feature
1. ERC20 ($DON) => mata uang untuk di platform ini
    - untuk donasi
    - untuk withdraw/cashout
    - untuk laporan keuangan
2. ERC721 => proof of donatur dan fundraiser (SBT)
    - ada NFT menunjukan bahwa user pernah donasi sekian secara akumulasi
    - NFT donatur ditujukan untuk menentukan apakah mereka bisa fundraise atau tidak
    - fundraiser juga memiliki NFT menunjukan akumulasi dana yang sudah dikumpulkan
3. Smart Contract DonadFundraisePlatform
    - First time deployment: whitelist fundraisers (founders address) by giving them NFT of Fundraiser
    - Early users can create fundraiser (fundraising name, deadline, target amount)
    - Any users can donate to the fundraising program (as long as it doesn't exceed the deadline)
    - User donation amount will be accumulated for NFT
    - Once user donation reach certain amount, they received another NFT for Fundraiser
    - Any Fundraiser NFT holder can create fundraiser
    - Fundraiser's fundraised amount will be accumulated inside their Fundraiser NFT
    - There should be a way to filter the ERC20 transfer from a certain fundraising program

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

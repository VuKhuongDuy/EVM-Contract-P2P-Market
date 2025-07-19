# ERC1155 Contract Deployment Guide

This guide will help you deploy the ERC1155 contract using Foundry.

## Prerequisites

1. **Private Key**: You need a private key for the account that will deploy the contract
2. **Network Access**: Access to the blockchain network you want to deploy to (local, testnet, or mainnet)

## Setup

### 1. Create Environment File

Create a `.env` file in the root directory:

```bash
# Your private key for deployment (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# Optional: RPC URL for specific network
# RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
```

**⚠️ Security Warning**: Never commit your `.env` file to version control. It's already in `.gitignore`.

### 2. Load Environment Variables

```bash
source .env
```

## Deployment Options

### Option 1: Deploy to Local Network (Anvil)

1. **Start local network**:
   ```bash
   anvil
   ```

2. **Deploy the contract**:
   ```bash
   forge script script/DeployERC1155.s.sol --rpc-url http://localhost:8545 --broadcast
   ```

### Option 2: Deploy to Testnet (Sepolia/Goerli)

1. **Set RPC URL** in your `.env`:
   ```bash
   RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
   ```

2. **Deploy the contract**:
   ```bash
   forge script script/DeployERC1155.s.sol --rpc-url $RPC_URL --broadcast --verify
   ```

### Option 3: Deploy to Mainnet

1. **Set RPC URL** in your `.env`:
   ```bash
   RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
   ```

2. **Deploy the contract**:
   ```bash
   forge script script/DeployERC1155.s.sol --rpc-url $RPC_URL --broadcast --verify
   ```

## Contract Features

The deployed ERC1155 contract includes:

- **Minting**: Single and batch minting capabilities
- **URI Management**: Set base URI and individual token URIs
- **Access Control**: Only owner can mint and set URIs
- **Metadata Support**: Flexible URI handling for token metadata

## Post-Deployment

After deployment, you can:

1. **Set Base URI**:
   ```solidity
   token.setURI("https://api.example.com/metadata/");
   ```

2. **Mint Tokens**:
   ```solidity
   token.mint(recipient, tokenId, amount, "");
   ```

3. **Set Individual Token URI**:
   ```solidity
   token.setTokenURI(tokenId, "https://api.example.com/metadata/token1.json");
   ```

## Testing

Run tests before deployment:

```bash
forge test --match-contract MyERC1155Test -vv
```

## Contract Address

After successful deployment, the contract address will be displayed in the console output. Save this address for future interactions.

## Verification

If you deployed with the `--verify` flag, your contract will be automatically verified on Etherscan (for supported networks).

## Troubleshooting

- **Insufficient Gas**: Ensure your account has enough ETH for deployment
- **Network Issues**: Check your RPC URL and network connectivity
- **Private Key**: Ensure your private key is correct and has sufficient funds 
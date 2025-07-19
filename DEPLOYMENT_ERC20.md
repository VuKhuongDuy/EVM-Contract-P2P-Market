# ERC20 Token Deployment Guide

This guide explains how to deploy the ERC20 token using the provided script.

## Prerequisites

1. **Foundry installed** - Make sure you have Foundry installed on your system
2. **Private key** - Your wallet's private key for deployment
3. **Environment variables** - Set up the required environment variables

## Environment Variables

Create a `.env` file in the project root with the following variables:

```bash
# Private key for deployment (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# Token configuration
TOKEN_NAME="My Token"
TOKEN_SYMBOL="MTK"
INITIAL_SUPPLY=1000000000000000000000000  # 1,000,000 tokens with 18 decimals
MAX_SUPPLY=2000000000000000000000000      # 2,000,000 tokens with 18 decimals

# Optional: Additional recipients for initial minting
# RECIPIENT_1=0x1234567890123456789012345678901234567890
# AMOUNT_1=100000000000000000000000  # 100,000 tokens
```

### Token Configuration Explained

- **TOKEN_NAME**: The full name of your token (e.g., "My Token")
- **TOKEN_SYMBOL**: The short symbol for your token (e.g., "MTK")
- **INITIAL_SUPPLY**: Initial token supply in wei (with 18 decimals)
- **MAX_SUPPLY**: Maximum token supply in wei (use 0 for unlimited supply)

### Supply Calculation

To calculate the supply values, multiply your desired token amount by 10^18:

```javascript
// Example: 1,000,000 tokens
const tokens = 1000000;
const supply = tokens * 10**18; // 1000000000000000000000000
```

## Deployment Commands

### 1. Local Testing (Anvil)

```bash
# Start local node
anvil

# In another terminal, deploy to local network
forge script script/DeployERC20.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### 2. Testnet Deployment (Sepolia)

```bash
# Deploy to Sepolia testnet
forge script script/DeployERC20.s.sol --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID --private-key $PRIVATE_KEY --broadcast --verify
```

### 3. Mainnet Deployment

```bash
# Deploy to Ethereum mainnet
forge script script/DeployERC20.s.sol --rpc-url https://mainnet.infura.io/v3/YOUR_PROJECT_ID --private-key $PRIVATE_KEY --broadcast --verify
```

## Post-Deployment

After successful deployment, you'll see output similar to:

```
ERC20 token deployed at: 0x1234567890123456789012345678901234567890
Token name: My Token
Token symbol: MTK
Initial supply: 1000000000000000000000000
Max supply: 2000000000000000000000000
Owner: 0xYourWalletAddress
```

## Token Features

The deployed token includes the following features:

### Owner Functions
- **Mint**: Create new tokens (when minting is enabled)
- **Burn From**: Burn tokens from any address
- **Set Max Supply**: Update the maximum supply
- **Set Minting Enabled**: Enable/disable minting

### User Functions
- **Transfer**: Standard ERC20 transfer
- **Transfer From**: Standard ERC20 transferFrom
- **Approve**: Standard ERC20 approve
- **Burn**: Burn your own tokens

### View Functions
- **Total Supply**: Get current total supply
- **Balance Of**: Get balance of any address
- **Remaining Supply**: Get remaining mintable supply
- **Is Max Supply Reached**: Check if max supply is reached

## Testing

Run the test suite to verify everything works:

```bash
forge test
```

## Verification

To verify your contract on Etherscan:

```bash
forge verify-contract 0xYourContractAddress src/MyERC20.sol:MyERC20 \
  --chain-id 1 \
  --etherscan-api-key YOUR_ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string,uint256,uint256)" "My Token" "MTK" 1000000000000000000000000 2000000000000000000000000)
```

## Security Considerations

1. **Private Key Security**: Never commit your private key to version control
2. **Max Supply**: Consider carefully whether to set a max supply or allow unlimited minting
3. **Minting Control**: The owner can mint unlimited tokens - ensure proper governance
4. **Access Control**: Only the owner can mint and burn tokens from other addresses

## Example Usage

### Minting Tokens
```javascript
// Mint 1000 tokens to a user
await token.mint(userAddress, ethers.utils.parseEther("1000"));
```

### Burning Tokens
```javascript
// User burns their own tokens
await token.burn(ethers.utils.parseEther("100"));

// Owner burns tokens from user
await token.burnFrom(userAddress, ethers.utils.parseEther("100"));
```

### Checking Supply
```javascript
// Get remaining mintable supply
const remaining = await token.remainingSupply();

// Check if max supply reached
const isMaxReached = await token.isMaxSupplyReached();
``` 
# P2P Market Contract

A decentralized peer-to-peer market contract for trading between two ERC20 tokens. This contract allows users to place sell orders and buyers to partially or fully fill them.

## Features

- **Place Sell Orders**: Users can place orders to sell tokens for other tokens
- **Partial Fills**: Orders can be filled partially or completely
- **Minimum Order Size**: Sellers can set minimum order sizes to prevent dust attacks
- **Order Management**: Sellers can cancel or update their orders
- **Platform Fees**: Configurable platform fees collected on trades
- **Security**: Reentrancy protection and comprehensive validation

## Contract Structure

### Order Structure
```solidity
struct Order {
    uint256 orderId;
    address seller;
    address tokenToSell;    // Token being sold
    address tokenToPay;     // Token used for payment
    uint256 amountToSell;   // Total amount to sell
    uint256 amountRemaining; // Remaining amount to sell
    uint256 pricePerToken;  // Price in tokenToPay per unit of tokenToSell
    uint256 minOrderSize;   // Minimum order size for partial fills
    bool isActive;
    uint256 createdAt;
}
```

### Fill Structure
```solidity
struct Fill {
    uint256 fillId;
    uint256 orderId;
    address buyer;
    uint256 amountFilled;
    uint256 paymentAmount;
    uint256 timestamp;
}
```

## Core Functions

### 1. Place Order
```solidity
function placeOrder(
    address tokenToSell,
    address tokenToPay,
    uint256 amountToSell,
    uint256 pricePerToken,
    uint256 minOrderSize
) external
```

**Parameters:**
- `tokenToSell`: Address of the token being sold
- `tokenToPay`: Address of the token used for payment
- `amountToSell`: Total amount to sell
- `pricePerToken`: Price in tokenToPay per unit of tokenToSell (with 18 decimals)
- `minOrderSize`: Minimum order size for partial fills

**Requirements:**
- User must approve the market contract to spend their tokens
- Tokens must be different
- All amounts must be greater than 0
- Minimum order size must be valid

### 2. Fill Order
```solidity
function fillOrder(uint256 orderId, uint256 amountToBuy) external
```

**Parameters:**
- `orderId`: ID of the order to fill
- `amountToBuy`: Amount of tokenToSell to buy

**Requirements:**
- Order must be active
- Amount must be within remaining supply
- Amount must meet minimum order size
- Buyer must approve payment tokens

### 3. Cancel Order
```solidity
function cancelOrder(uint256 orderId) external
```

**Requirements:**
- Only the seller can cancel their order
- Order must be active

### 4. Update Order
```solidity
function updateOrder(uint256 orderId, uint256 newPrice, uint256 newMinOrderSize) external
```

**Requirements:**
- Only the seller can update their order
- Order must be active

## Fee Structure

- **Platform Fee**: 0.25% (25 basis points) by default
- **Fee Collector**: Address that receives platform fees
- **Fee Calculation**: Applied to payment amount, deducted from seller's proceeds

## Events

- `OrderPlaced`: Emitted when a new order is placed
- `OrderFilled`: Emitted when an order is filled (partially or fully)
- `OrderCancelled`: Emitted when an order is cancelled
- `OrderUpdated`: Emitted when an order is updated
- `PlatformFeeUpdated`: Emitted when platform fee is changed
- `FeeCollectorUpdated`: Emitted when fee collector is changed

## Usage Examples

### 1. Place a Sell Order
```javascript
// Approve tokens first
await tokenA.approve(market.address, amountToSell);

// Place order to sell 1000 TokenA for 2 TokenB each
await market.placeOrder(
    tokenA.address,
    tokenB.address,
    ethers.utils.parseEther("1000"),
    ethers.utils.parseEther("2"),
    ethers.utils.parseEther("100") // Min order size
);
```

### 2. Fill an Order
```javascript
// Calculate payment amount
const order = await market.getOrder(1);
const amountToBuy = ethers.utils.parseEther("500");
const paymentAmount = amountToBuy.mul(order.pricePerToken).div(ethers.utils.parseEther("1"));

// Approve payment tokens
await tokenB.approve(market.address, paymentAmount);

// Fill order
await market.fillOrder(1, amountToBuy);
```

### 3. Cancel an Order
```javascript
await market.cancelOrder(1);
```

## Testing

Run the test suite:
```bash
forge test
```

The test suite includes:
- Order placement and validation
- Partial and full order fills
- Order cancellation and updates
- Error handling for invalid operations

## Deployment

Deploy the contract using the provided script:
```bash
forge script script/DeployMarket.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

**Constructor Parameters:**
- `_feeCollector`: Address that will receive platform fees

## Security Features

1. **Reentrancy Protection**: All state-changing functions are protected
2. **Input Validation**: Comprehensive checks for all parameters
3. **Access Control**: Only sellers can cancel/update their orders
4. **Safe Token Transfers**: Uses OpenZeppelin's safe transfer patterns
5. **Emergency Recovery**: Owner can recover stuck tokens

## Gas Optimization

- Efficient storage patterns
- Minimal external calls
- Optimized event emissions
- Batch operations where possible

## License

MIT License 
# SwapDex Module

The **SwapDex** module is a decentralized exchange (DEX) protocol built on the Sui blockchain. It supports token swaps, liquidity provision, staking, and loyalty rewards through a highly modular and scalable design. The module integrates **DeepBook**'s central limit order book (CLOB) functionality and incorporates loyalty incentives to enhance user engagement.

---

## Features

### Core Functionalities:
- **Token Minting**:
  - Mint WBTC, WETH, and SWAPDEX tokens with customizable amounts.
- **Liquidity Pools**:
  - Create and manage pools for WBTC-WETH trading pairs.
  - Deposit and withdraw assets from pools.
- **Trading**:
  - Place limit orders (bid and ask) with price and quantity specifications.
  - Execute market orders for instant trades.
  - Perform exact base-for-quote and quote-for-base swaps.

### Loyalty Program:
- Stake SWAPDEX tokens to earn loyalty points.
- Redeem loyalty points for NFTs as rewards.
- Reward users with SWAPDEX tokens for trading and pool interactions.

### Events:
- Emit informative events (e.g., `SwapEvent`, `RewardEvent`) for user actions, improving observability and feedback.

---

## Prerequisites

- **Sui Blockchain**: Ensure you have a Sui environment set up.
- **DeepBook**: This module requires DeepBook's `clob_v2` and `custodian_v2` libraries.
- **Dependencies**: Ensure the following libraries are imported:
  - `sui::coin`
  - `sui::balance`
  - `sui::transfer`
  - `sui::tx_context`
  - `sui::clock`
  - `sui::object`

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/rocknwa/SwapDex
   cd swapdex
   ```
2. Deploy the module on Sui blockchain:
   ```bash
   sui move publish --path .
   ```

---

## Usage Guide

### Token Minting
1. **Mint WBTC:**
   ```move
   public fun mint_wbtc(cap: &mut TreasuryCap<WBTC>, amount: u64, ctx: &mut TxContext)
   ```
   Mint WBTC tokens in the desired quantity.

2. **Mint WETH:**
   ```move
   public fun mint_weth(cap: &mut TreasuryCap<WETH>, amount: u64, ctx: &mut TxContext)
   ```
   Mint WETH tokens in the desired quantity.

---

### Liquidity Pool Management

1. **Create a New Pool**:
   ```move
   public fun new_pool<WBTC, WETH>(payment: &mut Coin<SUI>, ctx: &mut TxContext)
   ```
   Create a WBTC-WETH trading pool.

2. **Deposit Base Asset**:
   ```move
   public fun make_base_deposit<WBTC, WETH>(
       pool: &mut deepbook::Pool<WBTC, WETH>,
       coin: Coin<WBTC>,
       account_cap: &custodian::AccountCap
   )
   ```
   Deposit WBTC into a pool as the base asset.

3. **Withdraw Base Asset**:
   ```move
   public fun withdraw_base<BaseAsset, QuoteAsset>(
       pool: &mut deepbook::Pool<BaseAsset, QuoteAsset>,
       quantity: u64,
       account_cap: &custodian::AccountCap,
       ctx: &mut TxContext
   )
   ```

---

### Trading

1. **Place Ask Order**:
   ```move
   public fun place_ask_order<WBTC, WETH>(
       pool: &mut deepbook::Pool<WBTC, WETH>,
       client_order_id: u64,
       quantity: u64,
       self_matching_prevention: u8,
       is_bid: bool,
       expire_timestamp: u64,
       restriction: u8,
       clock: &Clock,
       account_cap: &custodian::AccountCap,
       treasury_cap: &mut TreasuryCap<WBTC>,
       ctx: &mut TxContext
   )
   ```
   Place a sell order in the WBTC-WETH pool.

2. **Execute Swap**:
   ```move
   public fun swap_exact_base_for_quote<WBTC, WETH>(
       pool: &mut deepbook::Pool<WBTC, WETH>,
       account: &mut LoyaltyAccount,
       client_order_id: u64,
       account_cap: &custodian::AccountCap,
       quantity: u64,
       base_coin: Coin<WBTC>,
       clock: &Clock,
       treasury_cap_dex: &mut TreasuryCap<SWAPDEX>,
       treasury_cap: &mut TreasuryCap<WETH>,
       ctx: &mut TxContext
   )
   ```
   Swap a specific quantity of WBTC for WETH.

---

### Loyalty Program

1. **Stake SWAPDEX**:
   ```move
   public fun stake(account: &mut LoyaltyAccount, stake: Coin<SWAPDEX>)
   ```
   Stake SWAPDEX tokens to start earning points.

2. **Redeem Rewards**:
   ```move
   public fun get_reward(account: &mut LoyaltyAccount, ctx: &mut TxContext): NFT
   ```
   Redeem loyalty points for an NFT.

3. **Unstake**:
   ```move
   public fun unstake(account: &mut LoyaltyAccount, ctx: &mut TxContext): Coin<SWAPDEX>
   ```

---

## Events

### Swap Event
Emits on successful swaps:
```move
emit(SwapEvent { message: b"Swap Successful!" });
```

### Reward Event
Emits when users earn rewards:
```move
emit(RewardEvent { message: b"DEX token reward granted" });
```

---

## Contributing

Feel free to open issues and submit pull requests. For major changes, please discuss them in an issue first.


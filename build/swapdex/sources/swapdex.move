#[lint_allow(self_transfer)]
module swapdex::swapdex {
    use deepbook::clob_v2 as deepbook;
    use deepbook::custodian_v2 as custodian;
    use std::option;
    use sui::sui::SUI;
    use sui::tx_context::{TxContext, Self};
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::balance::{Self};
    use sui::transfer::Self;
    use sui::clock::Clock;
    use swapdex::weth::WETH;
    use swapdex::wbtc::WBTC;
    use sui::object::{Self, UID};
    use sui::balance::Balance;
    use sui::event::emit;

    const FLOAT_SCALING: u64 = 1_000_000_000;

     const ENeeds10Points: u64 = 0;

    struct SWAPDEX has drop {}

    struct RewardEvent has copy, drop {
        message: vector<u8>
    }

    struct LoyaltyAccount has key, store {
    id: UID,

    stake: Balance<SWAPDEX>,
    
    points: u64
  }
  
  struct NFT has key, store {
    id: UID
  }

      fun init(witness: SWAPDEX, ctx: &mut TxContext) {
     
        let (treasury_cap, metadata) = coin::create_currency<SWAPDEX>(
            witness, 
            9, 
            b"SWAPDEX",
            b"SWAP DEX Coin", 
            b"Coin of SWAP DEX", 
            option::none(), 
            ctx
        );

      
      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(metadata);
    }

     public fun mint_weth(cap: &mut TreasuryCap<WETH>, amount: u64, ctx: &mut TxContext){
    let minted_coin = coin::mint(cap, amount * FLOAT_SCALING, ctx);
     let sender = tx_context::sender(ctx);
        transfer::public_transfer(minted_coin, sender);
   }
   
    public fun mint_wbtc(cap: &mut TreasuryCap<WBTC>, amount: u64, ctx: &mut TxContext){
    let minted_coin = coin::mint(cap, amount * FLOAT_SCALING, ctx);
     let sender = tx_context::sender(ctx);
        transfer::public_transfer(minted_coin, sender);
    }


    public fun new_pool<WBTC, WETH>(payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        let balance = coin::balance_mut(payment);
        let fee = balance::split(balance, 100 * 1_000_000_000);
        let coin = coin::from_balance(fee, ctx);

        deepbook::create_pool<WBTC, WETH>(
            1 * FLOAT_SCALING,
            1,
            coin,
            ctx
        );
    }

    public fun new_custodian_account(ctx: &mut TxContext) {
        transfer::public_transfer(deepbook::create_account(ctx), tx_context::sender(ctx))
    }

    public fun make_base_deposit<WBTC, WETH>(pool: &mut deepbook::Pool<WBTC, WETH>, coin: Coin<WBTC>, account_cap: &custodian::AccountCap) {
        deepbook::deposit_base(pool, coin, account_cap)
    }

    public fun make_quote_deposit<WBTC, WETH>(pool: &mut deepbook::Pool<WBTC, WETH>, coin: Coin<WETH>, account_cap: &custodian::AccountCap) {
        deepbook::deposit_quote(pool, coin, account_cap)
    }

    public fun withdraw_base<BaseAsset, QuoteAsset>(
        pool: &mut deepbook::Pool<BaseAsset, QuoteAsset>,
        quantity: u64,
        account_cap: &custodian::AccountCap,
        ctx: &mut TxContext
    ) {
        let base = deepbook::withdraw_base(pool, quantity, account_cap, ctx);
        transfer::public_transfer(base, tx_context::sender(ctx));
    }

    public fun withdraw_quote<WBTC, WETH>(
        pool: &mut deepbook::Pool<WBTC, WETH>,
        quantity: u64,
        account_cap: &custodian::AccountCap,
        ctx: &mut TxContext
    ) {
        let quote = deepbook::withdraw_quote(pool, quantity, account_cap, ctx);
        transfer::public_transfer(quote, tx_context::sender(ctx));
    }

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
): (u64, u64, bool, u64) {
    let price = 27 * FLOAT_SCALING; 
    deepbook::deposit_base(pool, coin::mint(treasury_cap, quantity * FLOAT_SCALING, ctx), account_cap);
    deepbook::place_limit_order(
        pool,
        client_order_id,
        price,
        quantity * FLOAT_SCALING,
        self_matching_prevention,
        is_bid,
        expire_timestamp,
        restriction,
        clock,
        account_cap,
        ctx
    )
}

public fun place_bid_order<WBTC, WETH>(
    pool: &mut deepbook::Pool<WBTC, WETH>,
    client_order_id: u64, 
    quantity: u64,
    self_matching_prevention: u8,
    is_bid: bool,
    expire_timestamp: u64,
    restriction: u8,
    clock: &Clock,
    account_cap: &custodian::AccountCap,
    treasury_cap: &mut TreasuryCap<WETH>,
    ctx: &mut TxContext
): (u64, u64, bool, u64) {
    let price = 30 * FLOAT_SCALING; 
    deepbook::deposit_quote(pool, coin::mint(treasury_cap, quantity * FLOAT_SCALING, ctx), account_cap);
    deepbook::place_limit_order(
        pool,
        client_order_id,
        price,
        quantity * FLOAT_SCALING,
        self_matching_prevention,
        is_bid,
        expire_timestamp,
        restriction,
        clock,
        account_cap,
        ctx
    )
}

    public fun place_base_market_order<WBTC, WETH>(
        pool: &mut deepbook::Pool<WBTC, WETH>,
        treasury_cap_dex: &mut TreasuryCap<SWAPDEX>,
        account: &mut LoyaltyAccount,
        account_cap: &custodian::AccountCap,
        base_coin: Coin<WBTC>,
        client_order_id: u64,
        is_bid: bool,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let quote_coin = coin::zero<WETH>(ctx);
        let quantity = coin::value(&base_coin);
        place_market_order(
            pool,
            treasury_cap_dex,
            account,
            account_cap,
            client_order_id,
            quantity,
            is_bid,
            base_coin,
            quote_coin,
            clock,
            ctx
        )
    }

    public fun place_quote_market_order<WBTC, WETH>(
        pool: &mut deepbook::Pool<WBTC, WETH>,
        treasury_cap_dex: &mut TreasuryCap<SWAPDEX>,
        account: &mut LoyaltyAccount,
        account_cap: &custodian::AccountCap,
        quote_coin: Coin<WETH>,
        client_order_id: u64,
        is_bid: bool,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let base_coin = coin::zero<WBTC>(ctx);
        let quantity = coin::value(&quote_coin);
        place_market_order(
            pool,
            treasury_cap_dex,
            account,
            account_cap,
            client_order_id,
            quantity,
            is_bid,
            base_coin,
            quote_coin,
            clock,
            ctx
        )
    }

    fun place_market_order<WBTC, WETH>(
        pool: &mut deepbook::Pool<WBTC, WETH>,
        treasury_cap_dex: &mut TreasuryCap<SWAPDEX>,
        account: &mut LoyaltyAccount,
        account_cap: &custodian::AccountCap,
        client_order_id: u64,
        quantity: u64,
        is_bid: bool,
        base_coin: Coin<WBTC>,
        quote_coin: Coin<WETH>,
        clock: &Clock, 
        ctx: &mut TxContext,
    ) {
        let (base, quote) = deepbook::place_market_order(
            pool, 
            account_cap, 
            client_order_id, 
            quantity * FLOAT_SCALING, 
            is_bid, 
            base_coin, 
            quote_coin, 
            clock, 
            ctx
        );

        if (loyalty_account_stake(account) != 0) {
        
          let points_ref = &mut account.points;
          *points_ref = *points_ref + 1;
      };
        transfer::public_transfer(base, tx_context::sender(ctx));
        transfer::public_transfer(quote, tx_context::sender(ctx));
         reward_user_with_dex(treasury_cap_dex, ctx);
    }

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
) {
    let base_quantity = quantity * FLOAT_SCALING; 
    let quote_quantity = base_quantity * 27; 
    let quote_coin = coin::mint::(treasury_cap, quote_quantity, ctx);

       let (base, quote, _) = deepbook::swap_exact_base_for_quote(
            pool,
            client_order_id,
            account_cap,
            base_quantity,
            base_coin,
            quote_coin,
            clock,
            ctx
        );

    if (loyalty_account_stake(account) != 0) {
        let points_ref = &mut account.points;
        *points_ref = *points_ref + 1;
    };
    transfer::public_transfer(base, tx_context::sender(ctx));
    transfer::public_transfer(quote, tx_context::sender(ctx));
    reward_user_with_dex(treasury_cap_dex, ctx);
}


    public fun swap_exact_quote_for_base<WBTC, WETH>(
    pool: &mut deepbook::Pool<WBTC, WETH>,
    account: &mut LoyaltyAccount,
    account_cap: &custodian::AccountCap,
    quote_coin: Coin<WETH>,
    client_order_id: u64,
    quantity: u64,
    clock: &Clock,
    treasury_cap_dex: &mut TreasuryCap<SWAPDEX>,
     treasury_cap: &mut TreasuryCap<WBTC>,
    ctx: &mut TxContext,
) {
    deepbook::deposit_base(pool, coin::mint(treasury_cap, quantity * FLOAT_SCALING, ctx), account_cap);
            let (base, quote, _) = deepbook::swap_exact_quote_for_base(
            pool,
            client_order_id,
            account_cap,
            quantity * FLOAT_SCALING,
            clock,
            quote_coin,
            ctx
        );

    if (loyalty_account_stake(account) != 0) {
        let points_ref = &mut account.points;
        *points_ref = *points_ref + 1;
    };
    transfer::public_transfer(base, tx_context::sender(ctx));
    transfer::public_transfer(quote, tx_context::sender(ctx));
    reward_user_with_dex(treasury_cap_dex, ctx);
}




    public fun reward_user_with_dex(cap: &mut TreasuryCap<SWAPDEX>, ctx: &mut TxContext) {
        let dex_reward_amount = 1 * FLOAT_SCALING;
        let sender = tx_context::sender(ctx);
        emit(RewardEvent {
            message: b"DEX token reward granted",
        });
         coin::mint_and_transfer(cap, dex_reward_amount, sender, ctx)
    }


  public fun create_account(ctx: &mut TxContext): LoyaltyAccount {
    LoyaltyAccount {
      id: object::new(ctx),
      stake: balance::zero(),
      points: 0
    }
  }


  public fun loyalty_account_stake(account: &LoyaltyAccount): u64 {
    balance::value(&account.stake)
  }

  
  public fun loyalty_account_points(account: &LoyaltyAccount): u64 {
    account.points
  }

  
  public fun get_reward(account: &mut LoyaltyAccount, ctx: &mut TxContext): NFT {
    assert!(account.points >= 10, ENeeds10Points);

    let points_ref = &mut account.points;
    *points_ref = *points_ref - 10;

    NFT {
      id: object::new(ctx)
    }
  }

  public fun stake(
    account: &mut LoyaltyAccount,
    stake: Coin<SWAPDEX>
  ) {
    balance::join(&mut account.stake, coin::into_balance(stake));
  }

  public fun unstake(
    account: &mut LoyaltyAccount,
    ctx: &mut TxContext
  ): Coin<SWAPDEX> {
    let value = loyalty_account_stake(account);

    coin::take(&mut account.stake, value, ctx)
  }

}
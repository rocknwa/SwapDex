module swapdex::weth {
  use std::option;

  use sui::url;
  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct WETH has drop {}

  fun init(witness: WETH, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<WETH>(
            witness, 
            9, 
            b"WETH",
            b"WETH Coin", 
            b"Ethereum Native Coin", 
            option::some(url::new_unsafe_from_bytes(b"https://s2.coinmarketcap.com/static/img/coins/64x64/1027.png")), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_freeze_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(WETH {}, ctx);
  }
}

 module swapdex::wbtc {
  use std::option;

  use sui::url;
  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct WBTC has drop {}

  fun init(witness: WBTC, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<WBTC>(
            witness, 
            9, 
            b"WBTC",
            b"Wrapped Bitcoin", 
            b"Digital Gold", 
            option::some(url::new_unsafe_from_bytes(b"https://th.bing.com/th/id/OIP.rLfnkcePW7yH3yf6ItmA4wHaHa?pid=ImgDet&w=178&h=178&c=7&dpr=1.5")), 
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


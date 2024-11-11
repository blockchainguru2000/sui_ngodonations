#[test_only]
module ngodonations::test_donate {
    use sui::test_scenario::{Self as ts, next_tx, ctx};
    use sui::test_utils::{assert_eq};
    use sui::coin::{Coin, mint_for_testing};
    use sui::clock::{Clock, Self};
    use sui::sui::{SUI};

    use std::string::{Self};
    use std::debug::print;

    use ngodonations::helpers::init_test_helper;
    use ngodonations::ngodonations::{Self as ng, Ngo, AdminCap, Activity};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS2: address = @0xbb;

    #[test]
    public fun test() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        next_tx(scenario, ADMIN);
        {
            let name = string::utf8(b"a");
            let description = string::utf8(b"b");
            let operationRegion = string::utf8(b"c");

            ng::create_ngo(name, description, operationRegion, ts::ctx(scenario))
        };

        next_tx(scenario, ADMIN);
        {
            let mut shared = ts::take_shared<Ngo>(scenario);
            let cap = ts::take_from_sender<AdminCap>(scenario);

            let name = string::utf8(b"a");
            let description = string::utf8(b"b");

            ng::add_activities(&cap, &mut shared, name, description );


            ts::return_shared(shared);
            ts::return_to_sender(scenario, cap);
        };

        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut shared = ts::take_shared<Ngo>(scenario);

            let name = string::utf8(b"a");
            let description = string::utf8(b"b");

            ng::user_register( &mut shared, name, description );

            ts::return_shared(shared);
        };

        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut shared = ts::take_shared<Ngo>(scenario);
            let coin = mint_for_testing<SUI>(100_000_000_000, ts::ctx(scenario));

            ng::donate( &mut shared, coin);
            
            ts::return_shared(shared);
        };

        next_tx(scenario, ADMIN);
        {
            let mut shared = ts::take_shared<Ngo>(scenario);
            let coin = mint_for_testing<SUI>(100_000_000_000, ts::ctx(scenario));

            ng::donate( &mut shared, coin);
            
            ts::return_shared(shared);
        };

        next_tx(scenario, ADMIN);
        {
            let mut shared = ts::take_shared<Ngo>(scenario);
            let cap = ts::take_from_sender<AdminCap>(scenario);

            let coin = ng::withdraw_funds(&cap, &mut shared, ts::ctx(scenario));

            transfer::public_transfer(coin, ADMIN);

            ts::return_shared(shared);
            ts::return_to_sender(scenario, cap);
        };

        ts::end(scenario_test);
    }



}
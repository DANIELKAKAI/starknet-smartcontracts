use starknet::ContractAddress;
use starknet::{
    contract_address_const
};

use snforge_std::{declare, ContractClassTrait};

use smart_contracts::ILetapaySafeDispatcher;
use smart_contracts::ILetapaySafeDispatcherTrait;
use smart_contracts::ILetapayDispatcher;
use smart_contracts::ILetapayDispatcherTrait;

use smart_contracts::Letapay::Payment;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_get_payment() {
    let contract_address = deploy_contract("Letapay");

    let dispatcher = ILetapayDispatcher { contract_address };

    let payment_id : felt252 = 112233;
    let address = contract_address_const::<'not owner'>();

    dispatcher.add_payment(
        payment_id: payment_id,
        address: address,
        amount: 8,
    );

    let payment: Payment = dispatcher.get_payment(payment_id);

    assert(payment.payment_id == payment_id, 'Not found');

}



use starknet::ContractAddress;
use starknet::{contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address
};

use smart_contracts::ILetapaySafeDispatcher;
use smart_contracts::ILetapaySafeDispatcherTrait;
use smart_contracts::ILetapayDispatcher;
use smart_contracts::ILetapayDispatcherTrait;

use smart_contracts::Letapay::{Payment, PaymentStatus};

const PAYMENT_ID: felt252 = 112233;
const AMOUNT: felt252 = 8;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn init_dispatcher() -> (ILetapayDispatcher, ContractAddress) {
    let contract_address = deploy_contract("Letapay");
    let dispatcher = ILetapayDispatcher { contract_address };
    (dispatcher, contract_address)
}

fn setup_addresses(contract_address: ContractAddress) -> (ContractAddress, ContractAddress) {
    let sender_address = contract_address_const::<'sender'>();
    let receiver_address = contract_address_const::<'receiver'>();
    (sender_address, receiver_address)
}

fn add_payment_with_cheat(
    dispatcher: ILetapayDispatcher,
    contract_address: ContractAddress,
    sender_address: ContractAddress,
    receiver_address: ContractAddress
) {
    start_cheat_caller_address(contract_address, sender_address);
    dispatcher
        .add_payment(payment_id: PAYMENT_ID, receiver_address: receiver_address, amount: AMOUNT);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_add_payment() {
    let (dispatcher, contract_address) = init_dispatcher();
    let (sender_address, receiver_address) = setup_addresses(contract_address);

    add_payment_with_cheat(dispatcher, contract_address, sender_address, receiver_address);
}

#[test]
fn test_get_payment() {
    let (dispatcher, contract_address) = init_dispatcher();
    let (sender_address, receiver_address) = setup_addresses(contract_address);

    add_payment_with_cheat(dispatcher, contract_address, sender_address, receiver_address);

    let payment: Payment = dispatcher.get_payment(PAYMENT_ID);

    assert_eq!(payment.payment_id, PAYMENT_ID, "Payment Not Found");
    assert_eq!(payment.sender_address, sender_address, "Wrong Sender Address");
}

#[test]
fn test_complete_payment() {
    let (dispatcher, contract_address) = init_dispatcher();
    let (sender_address, receiver_address) = setup_addresses(contract_address);

    add_payment_with_cheat(dispatcher, contract_address, sender_address, receiver_address);

    dispatcher.complete_payment(PAYMENT_ID);

    let payment: Payment = dispatcher.get_payment(PAYMENT_ID);

    assert_eq!(payment.status, PaymentStatus::COMPLETE, "Failed to Complete Payment");
}

#[test]
#[should_panic(expected: ("Only Owner can complete payment",))]
fn test_only_owner_can_complete_payment() {
    let (dispatcher, contract_address) = init_dispatcher();
    let (sender_address, receiver_address) = setup_addresses(contract_address);

    add_payment_with_cheat(dispatcher, contract_address, sender_address, receiver_address);
    
    start_cheat_caller_address(contract_address, sender_address);
    dispatcher.complete_payment(PAYMENT_ID);
    stop_cheat_caller_address(contract_address);
}

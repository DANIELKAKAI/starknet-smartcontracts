use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait};

use smart_contracts::ILetapaySafeDispatcher;
use smart_contracts::ILetapaySafeDispatcherTrait;
use smart_contracts::ILetapayDispatcher;
use smart_contracts::ILetapayDispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_get_payment() {
    let contract_address = deploy_contract("Letapay");

    let dispatcher = ILetapayDispatcher { contract_address };

    let payment = dispatcher.get_payment('abc');
    
    println!("{:?}", payment);

}



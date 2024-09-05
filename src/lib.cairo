use core::starknet::ContractAddress;

#[starknet::interface]
pub trait ILetapay<TContractState> {
    fn add_payment(
        ref self: TContractState, payment_id: felt252, address: ContractAddress, amount: felt252
    );

    fn get_payment(self: @TContractState, payment_id: felt252) -> Letapay::Payment;
}

#[starknet::contract]
mod Letapay {
    use core::starknet::{ContractAddress, get_caller_address, storage_access};
   
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PaymentAdded: PaymentAdded
    }

    #[derive(Drop, starknet::Event)]
    struct PaymentAdded {
        #[key]
        payment_id: felt252,
        amount: felt252,
        sender_address: ContractAddress,
        receiver_address: ContractAddress,
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        payments: LegacyMap<felt252, Payment>,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    pub enum PaymentStatus {
        AWAITING_TRANSFER,
        COMPLETE,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Payment {
        payment_id: felt252,
        amount: felt252,
        status: PaymentStatus,
        sender_address: ContractAddress,
        receiver_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_owner: ContractAddress) {
        self.owner.write(init_owner);
    }

    #[abi(embed_v0)]
    impl LetapayImpl of super::ILetapay<ContractState> {
        fn add_payment(
            ref self: ContractState,
            payment_id: felt252,
            address: ContractAddress,
            amount: felt252,
        ) {
            let sender = get_caller_address();

            let payment = Payment {
                payment_id: payment_id.clone(),
                amount: amount,
                status: PaymentStatus::AWAITING_TRANSFER,
                sender_address: sender,
                receiver_address: address,
            };

            self.payments.write(payment_id, payment);

            self
                .emit(
                    PaymentAdded {
                        payment_id, amount, sender_address: sender, receiver_address: address,
                    }
                );
        }

        fn get_payment(self: @ContractState, payment_id: felt252) -> Payment {
            self.payments.read(payment_id)
        }
    }
}

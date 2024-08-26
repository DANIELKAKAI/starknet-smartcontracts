use starknet::ContractAddress;
use starknet::storage::Map;

#[derive(Serde, Drop)]
enum PaymentStatus {
    AWAITING_TRANSFER,
    COMPLETE,
}

#[derive(Serde, Drop)]
struct Payment {
    payment_id: ByteArray,
    amount: felt252,
    status: PaymentStatus,
    sender_address: ContractAddress,
    receiver_address: ContractAddress,
}

#[starknet::interface]
pub trait ILetapay<TContractState> {
    fn add_payment(
        ref self: TContractState, payment_id: ByteArray, address: ContractAddress, amount: felt252
    );

    fn get_payment(self: @TContractState, payment_id: ByteArray) -> Payment;
}

#[starknet::contract]
mod Letapay {
    use super::{ContractAddress, Payment, PaymentStatus};
    use starknet::get_caller_address;

    #[derive(Drop, starknet::Event)]
    struct PaymentAdded {
        #[key]
        payment_id: ByteArray,
        amount: felt252,
        sender_address: ContractAddress,
        receiver_address: ContractAddress,
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        payments: super::Map<ByteArray, Payment>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_owner: ContractAddress) {
        self.owner.write(init_owner);
    }

    #[abi(embed_v0)]
    impl LetapayImpl of super::ILetapay<ContractState> {
        fn add_payment(
            ref self: ContractState,
            payment_id: ByteArray,
            address: ContractAddress,
            amount: felt252,
        ) {
            let sender = get_caller_address();

            let payment = Payment {
                payment_id,
                amount,
                status: PaymentStatus::AWAITING_TRANSFER,
                sender_address: sender,
                receiver_address: address,
            };

            self.payments.entry(payment_id).write(payment);

            self
                .emit(
                    PaymentAdded {
                        payment_id, amount, sender_address: sender, receiver_address: address,
                    }
                );
        }

        fn get_payment(self: @ContractState, payment_id: ByteArray) -> Payment {
            self.payments.read(payment_id)
        }
    }
}

use core::starknet::ContractAddress;

#[starknet::interface]
pub trait ILetapay<TContractState> {
    fn add_payment(
        ref self: TContractState, payment_id: felt252, receiver_address: ContractAddress, amount: felt252
    );

    fn get_payment(self: @TContractState, payment_id: felt252) -> Letapay::Payment;

    fn complete_payment(ref self: TContractState, payment_id: felt252);

    fn get_owner(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
pub mod Letapay {
    use core::starknet::{ContractAddress, get_caller_address, storage_access};

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PaymentAdded: PaymentAdded,
        PaymentCompleted: PaymentCompleted
    }

    #[derive(Drop, starknet::Event)]
    struct PaymentAdded {
        #[key]
        payment_id: felt252,
        amount: felt252,
        sender_address: ContractAddress,
        receiver_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct PaymentCompleted {
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

    #[derive(Copy, Drop, PartialEq, Serde, starknet::Store, Debug)]
    pub enum PaymentStatus {
        AWAITING_TRANSFER,
        COMPLETE,
    }

    #[derive(Drop, Serde, starknet::Store, Debug)]
    pub struct Payment {
        #[key]
        pub payment_id: felt252,
        pub amount: felt252,
        pub status: PaymentStatus,
        pub sender_address: ContractAddress,
        pub receiver_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let owner_address = get_caller_address();
        self.owner.write(owner_address);
    }

    #[abi(embed_v0)]
    impl LetapayImpl of super::ILetapay<ContractState> {
        fn add_payment(
            ref self: ContractState, payment_id: felt252, receiver_address: ContractAddress, amount: felt252,
        ) {
            let sender = get_caller_address();

            let payment = Payment {
                payment_id: payment_id.clone(),
                amount: amount,
                status: PaymentStatus::AWAITING_TRANSFER,
                sender_address: sender,
                receiver_address: receiver_address,
            };

            self.payments.write(payment_id, payment);

            self
                .emit(
                    PaymentAdded {
                        payment_id, amount, sender_address: sender, receiver_address: receiver_address,
                    }
                );
        }

        fn complete_payment(ref self: ContractState, payment_id: felt252) {
            assert!(self.owner.read() == get_caller_address(), "Only Owner can complete payment");
            assert!(
                self.payments.read(payment_id).status == PaymentStatus::AWAITING_TRANSFER,
                "Payment should have awaiting transfer status"
            );

            let mut payment = self.payments.read(payment_id);

            payment.status = PaymentStatus::COMPLETE;

            self.payments.write(payment_id, payment);
        }

        fn get_payment(self: @ContractState, payment_id: felt252) -> Payment {
            self.payments.read(payment_id)
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }
}

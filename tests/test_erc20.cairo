use core::byte_array::{ByteArray};
use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto};
use blockparty::contracts::erc20::BlockPartyToken::Event::{Transfer, Approval};
use blockparty::contracts::erc20::BlockPartyToken::Event;

use blockparty::interfaces::{IERC20Dispatcher, IERC20DispatcherTrait};


use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_block_timestamp, declare,
    start_cheat_caller_address, stop_cheat_caller_address, start_cheat_block_timestamp,
    start_cheat_block_timestamp_global, stop_cheat_block_timestamp, spy_events,
    EventSpyAssertionsTrait
};
use starknet::ContractAddress;

fn RECIPIENT() -> ContractAddress {
    return 'RECIPIENT'.try_into().unwrap();
}

fn SENDER() -> ContractAddress {
    return 'SENDERR'.try_into().unwrap();
}
fn OWNER() -> ContractAddress {
    return 'OWNER'.try_into().unwrap();
}

fn SPENDER() -> ContractAddress {
    return 'SPENDER'.try_into().unwrap();
}

fn __deploy_BlockParty_erc20__(admin: ContractAddress) -> ContractAddress {
    let blockparty_erc20_class_hash = declare("BlockPartyToken").unwrap().contract_class();
    let mut calldata = array![];
    admin.serialize(ref calldata);
    let (blockparty_erc20_contract_address, _) = blockparty_erc20_class_hash.deploy(@calldata).unwrap();
    return blockparty_erc20_contract_address;
}


#[test]
fn test_transfer() {
    let blockparty_erc20_contract_address = __deploy_BlockParty_erc20__(OWNER());
    let blockparty_erc20 = IERC20Dispatcher { contract_address: blockparty_erc20_contract_address };

    let recipient = RECIPIENT();
    let sender = SENDER();

    start_cheat_caller_address(blockparty_erc20_contract_address, OWNER());

    let before_balance = blockparty_erc20.balance_of(sender);
    blockparty_erc20.mint(sender, 1000);
    let after_balance = blockparty_erc20.balance_of(sender);
    assert!(after_balance != before_balance, "Balance could not be the same after minting");
    stop_cheat_caller_address(blockparty_erc20_contract_address);

    start_cheat_caller_address(blockparty_erc20_contract_address, sender);
    // transfer to the recipient address
    let before_sender_balance = blockparty_erc20.balance_of(sender);
    let befrore_recipient_balance = blockparty_erc20.balance_of(recipient);
    blockparty_erc20.transfer(recipient, 100);
    let after_recipient_balance = blockparty_erc20.balance_of(recipient);
    assert!(
        after_recipient_balance != befrore_recipient_balance,
        "Recipient balance could not be the same after transfering"
    );

    // check the sender balance
    let after_sender_balance = blockparty_erc20.balance_of(sender);
    assert!(
        after_sender_balance != before_sender_balance,
        "Sender balance could not be the same after transfering"
    );
    stop_cheat_caller_address(blockparty_erc20_contract_address);
}

#[test]
fn test_transfer_from() {
    let blockparty_erc20_contract_address = __deploy_BlockParty_erc20__(OWNER());
    let blockparty_erc20 = IERC20Dispatcher { contract_address: blockparty_erc20_contract_address };

    let recipient = RECIPIENT();
    let sender = SENDER();
    let spender = SPENDER();

    // deployer mints tokens for sender
    start_cheat_caller_address(blockparty_erc20_contract_address, OWNER());
    blockparty_erc20.mint(sender, 1000);
    blockparty_erc20.mint(spender, 1000);
    stop_cheat_caller_address(blockparty_erc20_contract_address);

    // now sender approves spender
    start_cheat_caller_address(blockparty_erc20_contract_address, sender);
    blockparty_erc20.approve(spender, 1000);
    stop_cheat_caller_address(blockparty_erc20_contract_address);

    // now spender calls transfer_from
    start_cheat_caller_address(blockparty_erc20_contract_address, spender);

    let before_sender_balance = blockparty_erc20.balance_of(sender);
    let before_recipient_balance = blockparty_erc20.balance_of(recipient);

    blockparty_erc20.transfer_from(sender, recipient, 1000);

    let after_sender_balance = blockparty_erc20.balance_of(sender);
    let after_recipient_balance = blockparty_erc20.balance_of(recipient);
    let after_allowance = blockparty_erc20.allowance(sender, spender);

    assert!(
        after_recipient_balance != before_recipient_balance,
        "Recipient balance could not be the same after transferring"
    );
    assert!(
        after_sender_balance != before_sender_balance,
        "Sender balance could not be the same after transferring"
    );
    assert!(after_allowance != 1000, "Allowance could not be the same after transferring");

    stop_cheat_caller_address(blockparty_erc20_contract_address);
}

#[test]
fn test_approve() {
    let blockparty_erc20_contract_address = __deploy_BlockParty_erc20__(OWNER());
    let blockparty_erc20 = IERC20Dispatcher { contract_address: blockparty_erc20_contract_address };

    let spender = SPENDER();
    let sender = SENDER();

    // deployer mints tokens for sender
    start_cheat_caller_address(blockparty_erc20_contract_address, OWNER());
    blockparty_erc20.mint(sender, 1000);
    stop_cheat_caller_address(blockparty_erc20_contract_address);

    // now sender approves spender
    start_cheat_caller_address(blockparty_erc20_contract_address, sender);
    blockparty_erc20.approve(spender, 1000);
    stop_cheat_caller_address(blockparty_erc20_contract_address);

    // check the allowance
    start_cheat_caller_address(blockparty_erc20_contract_address, spender);
    let allowance = blockparty_erc20.allowance(sender, spender);
    assert!(allowance == 1000, "Allowance should be 1000");
    stop_cheat_caller_address(blockparty_erc20_contract_address);
}

#[test]
fn test_mint() {
    let blockparty_erc20_contract_address = __deploy_BlockParty_erc20__(OWNER());
    let blockparty_erc20 = IERC20Dispatcher { contract_address: blockparty_erc20_contract_address };

    let recipient = RECIPIENT();
    let sender = SENDER();

    // deployer mints tokens for sender
    start_cheat_caller_address(blockparty_erc20_contract_address, OWNER());
    blockparty_erc20.mint(sender, 1000);
    stop_cheat_caller_address(blockparty_erc20_contract_address);

    // check the balance
    start_cheat_caller_address(blockparty_erc20_contract_address, sender);
    let balance = blockparty_erc20.balance_of(sender);
    assert!(balance == 1000, "Balance should be 1000");
    stop_cheat_caller_address(blockparty_erc20_contract_address);
}

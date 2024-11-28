// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import "forge-std/console.sol";

// Base State
contract BaseStateD {

	// Specific state data
    struct Channel {
        bytes32 trustAnchor;
        uint256 amount;
        uint256 numberOfTokens;
        uint256 withdrawAfterBlocks;
    }

    // General state data
	struct State {
		Channel channel;
	}

	// State (Slot1)
    // Nested mapping to store channels: user => merchant => Channel	
	mapping (address => mapping (address => State)) state;

	// Updates the base state data to the callers context when delegated
	function copyState(State memory _state) public virtual returns(bool success) {

		assembly {
		}

		success = true;
	}

    function getState(address payer, address merchant)
    	public virtual view returns (bytes memory _data) {

        assembly {
			 // Calculate the slot and store					
			 let p := mload(0x40)
			 mstore(p, payer)
			 mstore(0x40, add(p, 0x20))

			 mstore(add(p, 0x20), state.slot)
			 mstore(0x40, add(p, 0x40))

			 let q := mload(0x40)
			 mstore(q, merchant)
			 mstore(0x40, add(q, 0x20))

			 mstore(add(q, 0x20), keccak256(p, 0x40))
			 mstore(0x40, add(q, 0x40))

			 let bslot := keccak256(q, 0x40)
			 _data := mload(0x40)

			 mstore(_data, sload(bslot)) 
			 mstore(0x40, add(_data, 0x20))

			 mstore(add(_data, 0x20), sload(add(bslot, 1))) 
			 mstore(0x40, add(_data, 0x40))

			 mstore(add(_data, 0x40), sload(add(bslot, 2))) 
			 mstore(0x40, add(_data, 0x60))

			 mstore(add(_data, 0x60), sload(add(bslot, 3))) 
			 mstore(0x40, add(_data, 0x80))
        }

        console.log("In get state");
        console.log("trustAnchor:", uint256(state[payer][merchant].channel.trustAnchor));
        console.log("amount:", state[payer][merchant].channel.amount);
        console.log("numberOfTokens:", state[payer][merchant].channel.numberOfTokens);
        console.log("withdrawAfterBlocks:", state[payer][merchant].channel.withdrawAfterBlocks);

    }

    function setState(address merchant, bytes memory _data) public virtual {

        assembly {
			 // Calculate the slot and store					
			 let p := mload(0x40)
			 mstore(p, caller())
			 mstore(0x40, add(p, 0x20))

			 mstore(add(p, 0x20), state.slot)
			 mstore(0x40, add(p, 0x40))

			 let q := mload(0x40)
			 mstore(q, merchant)
			 mstore(0x40, add(q, 0x20))

			 mstore(add(q, 0x20), keccak256(p, 0x40))
			 mstore(0x40, add(q, 0x40))

			 let bslot := keccak256(q, 0x40)
			 sstore(bslot, mload(add(_data, 0x20))) //trustAnchor
			 sstore(add(bslot, 1), mload(add(_data, 0x40))) //amount
			 sstore(add(bslot, 2), mload(add(_data, 0x60))) //numberOfTokens
			 sstore(add(bslot, 3), mload(add(_data, 0x80))) //withdrawAfterBlocks
        }

        console.log("In set state");
        console.log("trustAnchor:", uint256(state[msg.sender][merchant].channel.trustAnchor));
        console.log("amount:", state[msg.sender][merchant].channel.amount);
        console.log("numberOfTokens:", state[msg.sender][merchant].channel.numberOfTokens);
        console.log("withdrawAfterBlocks:", state[msg.sender][merchant].channel.withdrawAfterBlocks);

    }

	// To be overriden by version
    function supportedStates() public pure virtual returns (bytes memory) {
	}
}

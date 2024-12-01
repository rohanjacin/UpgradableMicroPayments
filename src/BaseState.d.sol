// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import "forge-std/console.sol";

// Base State
contract BaseStateD {
    // General state data

	// Channel data
    struct Channel {
        bytes32 trustAnchor;
        uint256 amount;
        uint256 withdrawAfterBlocks;
        // tokenId (if then noOfTokens is amount, else ERC20 balance)
        bytes8[4] tokenIds;
    }

	// Tokens (32 bytes ERC20 token ids)
	struct Tokens {
		bytes32[] v;
	}

	Tokens tokens;

	// State (Slot1)
    // Nested mapping to store channels: user => merchant => Channel	
	mapping (address => mapping (address => Channel)) channel;

	// Updates the base state data to the callers context when delegated
	function copyState(Tokens memory _tokens)
		public virtual returns(bool success) {

		assembly {
			// Fetch dimension
			let ptr := mload(_tokens)
			let len := mload(ptr)
			ptr := add(ptr, 0x20)

			// Revert if length is greater than 255 or is 0
			if iszero(len) {
				revert (0, 0)
			}

			if gt(len, 255) {
				revert (0, 0)
			}

			// TODO: Check if all symbols are present in memory

			for { let i := 0 let v := 0 let s := 0 let p := 0 } 
				lt(i, 1) { i := add(i, 1) } {
				
				 // Calculate the slot and store
				 v := mload(add(ptr, mul(i, 0x20)))
				 p := mload(0x40)
				 mstore(p, tokens.slot)
				 mstore(0x40, add(p, 0x20))
				 s := add(keccak256(p, 0x20), i)
				 sstore(s, v)
			}
		}

		success = true;
	}

    function getState(uint8 _version)
    	public virtual view returns (bytes32 val) {

    	require((_version == 1 || _version == 2), "Wrong version");

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, tokens.slot)
            mstore(0x40, add(ptr, 0x20))
            let s := add(keccak256(ptr, 0x20), sub(_version, 1))
			val := sload(s)
        }
	}

    function getState(address payer, address merchant)
    	public virtual view returns (bytes memory _data) {

        assembly {
			 // Calculate the slot and store					
			 let p := mload(0x40)
			 mstore(p, payer)
			 mstore(0x40, add(p, 0x20))

			 mstore(add(p, 0x20), channel.slot)
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
    }

    function setState(address merchant, bytes memory _data) public virtual {

        assembly {
			 // Calculate the slot and store					
			 let p := mload(0x40)
			 mstore(p, caller())
			 mstore(0x40, add(p, 0x20))

			 mstore(add(p, 0x20), channel.slot)
			 mstore(0x40, add(p, 0x40))

			 let q := mload(0x40)
			 mstore(q, merchant)
			 mstore(0x40, add(q, 0x20))

			 mstore(add(q, 0x20), keccak256(p, 0x40))
			 mstore(0x40, add(q, 0x40))

			 let bslot := keccak256(q, 0x40)
			 sstore(bslot, mload(add(_data, 0x20))) //trustAnchor
			 sstore(add(bslot, 1), mload(add(_data, 0x40))) //amount
			 sstore(add(bslot, 2), mload(add(_data, 0x60))) //withdrawAfterBlocks
			 sstore(add(bslot, 3), mload(add(_data, 0x80))) //tokenIds
        }
    }

	// To be overriden by version
    function supportedStates() public pure virtual returns (bytes memory) {
	}
}

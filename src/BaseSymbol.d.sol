// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

import "forge-std/console.sol";

// Basic symbol layout
contract BaseSymbolD {

	// Symbols (unicode 4 bytes max)
	struct Symbols {
		bytes6[] v;
	}

	// Unicode mapping
	Symbols symbols;

	// Updates the base symbol data to the callers context when delegated
	function copySymbol(Symbols memory _symbols) public virtual returns(bool success) {

		assembly {
			// Fetch dimension
			let ptr := mload(_symbols)
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
				lt(i, len) { i := add(i, 1) } {
				
				 // Calculate the slot and store
				 v := mload(add(ptr, mul(i, 0x20)))
				 p := mload(0x40)
				 mstore(p, symbols.slot)
				 mstore(0x40, add(p, 0x20))
				 s := add(keccak256(p, 0x20), i)
				 sstore(s, v)
			}
		}

		success = true;
	}

    function getSymbol(uint8 id) internal view returns (bytes6 val) {

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, symbols.slot)
            mstore(0x40, add(ptr, 0x20))
            let s := add(keccak256(ptr, 0x20), id)
			val := sload(s)
        }
    }
}

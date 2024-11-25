// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

import "forge-std/console.sol";

// Basic symbol layout
contract BaseSymbolD {

	// Symbols (unicode 4 bytes max)
	struct Symbols {
		bytes4[] v;
	}

	// Unicode mapping
	Symbols symbols;

	// Updates the base symbol data to the callers context when delegated
	function copySymbol(Symbols memory _symbols) public virtual returns(bool success) {

		assembly {
		}

		success = true;
	}

    function getSymbol(uint8 id) internal view returns (bytes4 val) {

        assembly {
        }
    }
}

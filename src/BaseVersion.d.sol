// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import "forge-std/console.sol";

// Basic version layout
contract BaseVersionD {

	// Version number value
	uint8 public version;

	// Updates the base version data to the callers context when delegated
	function copyVersion(bytes memory data) internal returns(bool success) {

		// Copy the 1 byte version number assuming data is packed
		// with only version number
		assembly {
			let len := mload(data)
			let value := byte(0, mload(add(data, 0x20)))

			// Version 1 and Version 2 only currently!!
			if iszero(value) {
				revert (0, 0)
			}

			if gt(value, 2) {
				revert (0, 0)
			}

			// Store one byte in slot of version number
			if eq(len, 1) {
				sstore(version.slot, value)
			}
		}

		success = true;
	}

}

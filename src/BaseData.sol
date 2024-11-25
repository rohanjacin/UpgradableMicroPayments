// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import "forge-std/console.sol";

// Basic Data layout
contract BaseData {

	// Location of initial version data
	address public data;

	// Store version number, state and symbols as code  
	function _storeVersion(bytes memory _versionNum, bytes memory _state,
		bytes memory _symbols) internal returns (address location) {

		// Constructor wrapper to create contract with code
		// eqaul to _versionNum, _state, _symbols
		// Taken from https://github.com/0xsequence/sstore2
	    /*
	      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
	      0x01    0x80         0x80        DUP1                size size
	      0x02    0x60         0x600e      PUSH1 14            14 size size
	      0x03    0x60         0x6000      PUSH1 00            0 14 size size
	      0x04    0x39         0x39        CODECOPY            size
	      0x05    0x60         0x6000      PUSH1 00            0 size
	      0x06    0xf3         0xf3        RETURN
	      <CODE>
	    */

	    bytes memory _data = abi.encodePacked(
	    	hex"00",
	    	_versionNum,
	    	_state,
	    	_symbols
	    );

		bytes memory code = abi.encodePacked(
			hex"63",
			uint32(_data.length),
			hex"80_60_0E_60_00_39_60_00_F3",
			_data
		);

		assembly {
			location := create(0, add(code, 32), mload(code))
		}

		if (location == address(0)) {
			revert();
		}
	}

	// Retrieve version number, state and symbols as data  
	function _retrieveVersion(address loc) 
		internal view returns (bytes memory _data) {

		uint256 size;

		if (loc == address(0)) {
			revert();
		}

		assembly {
			size := extcodesize(loc)

			if iszero(size) {
				revert(0, 0)
			}

			// Allocate space for data starting from the free location
			_data := mload(0x40)

			// Reserve new memory to fit data size
			mstore(0x40, add(_data, and(add(add(size, 0x20), 0x1f), not(0x1f))))

			// Store length
			mstore(_data, size)

			// retrieve the code from location
			extcodecopy(loc, add(_data, 0x20), 1, sub(size, 1))
		}
	}

	// Updates the data to the callers context when delegated
	function copyData(address loc) public virtual returns(bytes memory){	
		return _retrieveVersion(loc);
	}
}

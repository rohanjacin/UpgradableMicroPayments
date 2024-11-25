// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import "forge-std/console.sol";

// Base State
contract BaseStateD {

	struct State {
		uint256[][] v;
	}

	// State (Slot1)
	State board; 

	// Updates the base state data to the callers context when delegated
	function copyState(State memory _state) public virtual returns(bool success) {

		assembly {
		}

		success = true;
	}

    function getState(uint8 a, uint8 b) public virtual view returns (uint256 c) {

        assembly {
        }
    }

    function setState(uint8 a, uint8 b, uint8 c) public virtual {

        assembly {
        }
    }

	// To be overriden by version
    function supportedStates() public pure virtual returns (bytes memory) {
	}
}

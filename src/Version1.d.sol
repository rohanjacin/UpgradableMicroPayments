// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

import "./BaseLevel.d.sol";
import "./BaseState.d.sol";
import "./BaseSymbol.d.sol";
import "./BaseData.d.sol";
import {console} from "forge-std/console.sol";

// Version 1 defination and implementation
contract Version1D is BaseLevelD, BaseStateD, BaseSymbolD, BaseDataD {
	constructor (bytes memory versionNum,
				 bytes memory state,
		         bytes memory symbols)
		BaseDataD(versionNum, state, symbols) {
	}

	// Fetched Version 1 pre-filled data
	function fetchVersionData() public returns(bytes memory) {
		return BaseDataD.copyData(data);
	}

	// Loads Version 1 with pre-filled data
	function copyVersionData(bytes calldata _versionNumData,
		bytes calldata _stateData, bytes calldata _symbolsData)
		public returns(bool success){

		// Copy version num
		success = BaseLevelD.copyLevel(_versionNumData);
		// Copy version state as per schema
		success = _copyState(_stateData);
		// Copy version symbols as per schema
		success =_copySymbol(_symbolsData);
	}

	// Copies state into micropay storage as per schema
	function _copyState(bytes calldata cell) internal returns (bool success){

		State memory _state = State({v: new uint256[][](3)});
        _state.v[0] = new uint256[](3);
        _state.v[1] = new uint256[](3);
        _state.v[2] = new uint256[](3);

	
		success = BaseStateD.copyState(_state);
	}	

	// Copies symbols into micropay storage as per schema
	function _copySymbol(bytes calldata _symbols) public returns (bool success){

        Symbols memory s = Symbols({v: new bytes4[](2)});
        s.v[0] = bytes4(_symbols[0:4]);
        s.v[1] = bytes4(_symbols[4:8]);

		success = BaseSymbolD.copySymbol(s);
	}

	//
	function setPaymentue29d8c00(uint8 a, uint8 b, uint8 c) external {
		BaseStateD.setState(a, b, c);
	}
	
	//  
	function setPaymentue2ad9500(uint8 a, uint8 b, uint8 c) external {
		BaseStateD.setState(a, b, c);
	}

	// Inherited from BaseState - all implemented and supported states in versions
    function supportedStates() public pure override returns (bytes memory) {

    	return abi.encodePacked(bytes4(this.setPaymentue29d8c00.selector),  //
    							bytes4(this.setPaymentue2ad9500.selector)); //
    }
}

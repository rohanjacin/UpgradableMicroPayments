// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./BaseVersion.d.sol";
import "./BaseState.d.sol";
import "./BaseSymbol.d.sol";
import "./BaseData.d.sol";

// Payment verison 1 defination and implementation
contract PaymentV1 is BaseVersionD, BaseStateD, BaseSymbolD, BaseDataD {
    constructor(bytes memory versionNum,
                bytes memory state,
                bytes memory symbols)
        BaseDataD(versionNum, state, symbols) {
    }

    fallback() external {
        console.log("in Fallback");
    }

    // Verifies payment hash
    function _verifyHashchain(bytes32 trustAnchor, bytes32 finalHashValue,
        uint256 numberOfTokensUsed) internal pure returns (bool) {

        for (uint256 i = 0; i < numberOfTokensUsed; i++) {
            finalHashValue = keccak256(abi.encode(finalHashValue));
        }
        return finalHashValue == trustAnchor;
    }

    // Loads version 1 with pre-filled data
    function copyVersionData(bytes calldata _versionNum,
        bytes calldata _versionState, bytes calldata _versionSymbol)
        public returns(bool success){

        // Copy version num
        success = BaseVersionD.copyVersion(_versionNum);
        // Copy version state as per schema
        success = _copyState(_versionState);
        // Copy version symbols as per schema
        success =_copySymbol(_versionSymbol);
    }

    // Copies state into payment storage as per schema
    function _copyState(bytes calldata _tokens) internal returns (bool success){

        Tokens memory _state = BaseStateD.Tokens({v: new bytes32[](1)});
        _state.v[0] = bytes32(_tokens[0:32]);

        success = BaseStateD.copyState(1, _state);
    }   

    // Copies symbols into payment storage as per schema
    function _copySymbol(bytes calldata _symbols)
        public returns (bool success){

        Symbols memory s = Symbols({v: new bytes6[](2)});
        s.v[0] = bytes6(_symbols[0:6]); //hex"f26be922V1"
        s.v[1] = bytes6(_symbols[6:12]); //hex"8d7cb017V1"

        success = BaseSymbolD.copySymbol(s);
    }

    // Create channel for payment
    function createChannelV1(address merchant, uint256 amount,
        uint256 numberOfTokens, bytes calldata data) public payable {
//bytes32 trustAnchor, uint256 numberOfTokens, uint256 withdrawAfterBlocks
       
        // Perform preset checks for channel
        require(msg.value == amount, "incorrect amount sent.");

        // Create a channel for merchant
        bytes memory _data = abi.encodePacked(data);
        BaseStateD.setState(merchant, _data);  
    }
/*
bytes32 finalHashValue,
        uint256 numberOfTokensUsed*/
    // Withdraw from channel
    function withdrawChannelV1(address payer, uint256 amount,
        uint256 numberOfTokensUsed, bytes calldata data) public
        returns(bytes memory _returnData) {

        bytes memory _data = BaseStateD.getState(payer, msg.sender);        
        
        bytes32 _trustAnchor;
        uint256 _withdrawAfterBlocks;
        uint256 _amount;
        uint256 numberOfTokens = 1;
        assembly {
            let ptr := mload(_data)

            _trustAnchor := mload(add(_data, 0x00))
            _amount := mload(add(_data, 0x20))
            _withdrawAfterBlocks := mload(add(_data, 0x40))
        }

        require(amount > 0, "Wrong channel");

        //require(_verifyHashchain(_trustAnchor, finalHashValue,
        //        numberOfTokensUsed), "Verification failed");

        _returnData = abi.encodePacked(_amount, numberOfTokens);
    }

    // Inherited from BaseState - all implemented and supported states in versions
    function supportedStates() public pure override returns (bytes memory) {

        return abi.encodePacked(bytes4(this.createChannelV1.selector),  //
                                bytes4(this.withdrawChannelV1.selector)); //
    }

}
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

    // Verifies payment hash
    function _verifyHashchain(bytes32 trustAnchor, bytes32 finalHashValue,
        uint256 numberOfTokensUsed) internal pure returns (bool) {

        for (uint256 i = 0; i < numberOfTokensUsed; i++) {
            finalHashValue = keccak256(abi.encode(finalHashValue));
        }
        return finalHashValue == trustAnchor;
    }

    // Create channel for payment
    function createChannelV1(address merchant, bytes32 trustAnchor,
        uint256 amount, uint256 numberOfTokens, uint256 withdrawAfterBlocks
    ) public payable {

        // Perform preset checks for channel
        require(msg.value == amount, "incorrect amount sent.");

        // Create a channel for merchant
        bytes memory _data = abi.encodePacked(trustAnchor, amount,
                             numberOfTokens, withdrawAfterBlocks);
        BaseStateD.setState(merchant, _data);        
    }

    // Withdraw from channel
    function withdrawChannelV1(address payer, bytes32 finalHashValue,
        uint256 numberOfTokensUsed) public
        returns(uint256 amount, uint256 numberOfTokens) {

        bytes memory _data = BaseStateD.getState(payer, msg.sender);        
        
        bytes32 _trustAnchor;

        assembly {
            let ptr := mload(_data)

            _trustAnchor := mload(add(_data, 0x20))
            amount := mload(add(_data, 0x40))
            numberOfTokens := mload(add(_data, 0x60))
        }

        console.log("amount:", amount);
        console.log("numberOfTokens:", numberOfTokens);

        require(amount > 0, "Wrong channel");

        require(_verifyHashchain(_trustAnchor, finalHashValue,
                numberOfTokensUsed), "Verification failed");
    }

    // Inherited from BaseState - all implemented and supported states in versions
    function supportedStates() public pure override returns (bytes memory) {

        return abi.encodePacked(bytes4(this.createChannelV1.selector),  //
                                bytes4(this.withdrawChannelV1.selector)); //
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./BaseVersion.d.sol";
import "./BaseState.d.sol";
import "./BaseSymbol.d.sol";
import "./BaseData.d.sol";
import "murky/src/CompleteMerkle.sol";

// Payment verison 2 defination and implementation
contract PaymentV2 is BaseVersionD, BaseStateD, BaseSymbolD, BaseDataD {
    constructor(bytes memory versionNum,
                bytes memory state,
                bytes memory symbols)
        BaseDataD(versionNum, state, symbols) {
        
        merkleTree = new CompleteMerkle();
    }

    // Merkle tree utility contract (occupies Slot 3)
    CompleteMerkle public merkleTree;

    event ChannelCreated(address indexed payer, uint256 amount,
                         uint256 numberOfTokens);

    event TokenAdded(address indexed payer, address indexed merchant,
                     bytes32 token);
    
    event MerchantPaid(address indexed payer, address indexed merchant,
                       uint256 amount);

    function verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public view returns (bool) {
        return merkleTree.verifyProof(root, proof, leaf);
    }

    // Get merchant balance
    function getBalance(address payer, address merchant)
        public view returns (uint256 amount) {

        bytes memory _data = BaseStateD.getState(payer, merchant);        
        
        assembly {
            amount := mload(add(_data, 0x40))
        }
    }

    // Create channel for payment
    function createChannelV2(address merchant, bytes32 trustAnchor,
        uint256 amount, uint256 numberOfTokens, uint256 withdrawAfterBlocks
    ) public payable {

        // Perform preset checks for channel
        require(msg.value == amount, "incorrect amount sent.");

        // Check if channel already exist
        bytes memory _state = BaseStateD.getState(msg.sender, merchant);

        assembly {
            let _amount := mload(add(_state, 0x40))

            if iszero(iszero(_amount)) {
                revert (0, 0)
            }
        }

        // Create a channel for merchant
        bytes memory _data = abi.encodePacked(trustAnchor, amount,
                             numberOfTokens, withdrawAfterBlocks);
        BaseStateD.setState(merchant, _data); 

        emit ChannelCreated(msg.sender, amount, numberOfTokens);               
    }


    // Withdraw from channel
    function withdrawChannelV2(address payer, bytes32 finalHashValue,
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

        require(amount > 0, "Amount not payable");

        //require(_verifyHashchain(_trustAnchor, finalHashValue,
        //        numberOfTokensUsed), "Verification failed");
    }

    // Inherited from BaseState - all implemented and supported states in versions
    function supportedStates() public pure override returns (bytes memory) {

        return abi.encodePacked(bytes4(this.createChannelV2.selector),  //
                                bytes4(this.withdrawChannelV2.selector)); //
    }

}
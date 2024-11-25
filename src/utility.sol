// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract Utility {

    function verifyHashchain (bytes32 trustAnchor, bytes32 finalHashValue, uint256 numberOfTokenUsed) external pure returns (bool)  {
        for (uint256 i = 0; i < numberOfTokenUsed; i++) {
            finalHashValue = keccak256(abi.encode(finalHashValue));
        }
        return finalHashValue == trustAnchor;
    }

    function verifyMerkleProof (bytes32 leaf, bytes32[] memory proof, bytes32 root) external pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}
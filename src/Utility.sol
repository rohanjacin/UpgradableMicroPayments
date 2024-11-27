// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "murky/src/CompleteMerkle.sol";

contract Utility {
    CompleteMerkle public merkleTree;

    constructor() {
        merkleTree = new CompleteMerkle();
    }

    function verifyHashchain(
        bytes32 trustAnchor,
        bytes32 finalHashValue,
        uint256 numberOfTokensUsed
    ) external pure returns (bool) {
        for (uint256 i = 0; i < numberOfTokensUsed; i++) {
            finalHashValue = keccak256(abi.encode(finalHashValue));
        }
        return finalHashValue == trustAnchor;
    }

    function verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public view returns (bool) {
        return merkleTree.verifyProof(root, proof, leaf);
    }

    // function verifyMerkleProof(
    //     bytes32 leaf,
    //     bytes32[] memory proof,
    //     bytes32 root
    // ) external pure returns (bool) {
    //     require(proof.length > 0, "Proof cannot be empty");
    //     require(root != bytes32(0), "Root cannot be zero");
    //     return MerkleProof.verify(proof, root, leaf);
    // }
}

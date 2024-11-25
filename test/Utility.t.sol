// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/Utility.sol";

contract UtilityTest is Test {
    Utility private utility;

    function setUp() public {
        utility = new Utility();
    }

    function bytes32ToString(
        bytes32 _bytes32
    ) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function testVerifyHashchain() public view {
        // Arrange
        bytes32 initialHashValue = keccak256(abi.encode("initialValue"));
        uint256 numberOfTokensUsed = 5;
        bytes32 trustAnchor = initialHashValue;

        for (uint256 i = 0; i < numberOfTokensUsed; i++) {
            trustAnchor = keccak256(abi.encode(trustAnchor));
        }

        // Act
        bool result = utility.verifyHashchain(
            trustAnchor,
            initialHashValue,
            numberOfTokensUsed
        );

        // Assert
        assertTrue(result, "Hashchain verification failed");
    }

    function testVerifyMerkleProof() public view {
        bytes32[] memory proof = new bytes32[](4); // Initialize proof array with correct size
        bytes32 leaf = 0x28cac318a86c8a0a6a9156c2dba2c8c2363677ba0514ef616592d81557e679b6; // Hashed Leaf for Bob
        proof[
            0
        ] = 0xe6f3a238a91ab6300589612c3e125d7769fd2e49302023767ac0abeda2b967df; // First proof element
        proof[
            1
        ] = 0xa97a5f7e722cafe00dab68569b07d6a0eb9ffff15b62bccf5442defb7f4e7eb8; // Second proof element
        bytes32 root = 0xe046c2b59d25a326d978fe9057f32d4c454a410b5cf8a284e836031de8bffc7a; // Merkle Root

        // Act
        bool result = utility.verifyMerkleProof(leaf, proof, root);

        // Assert
        assertTrue(result, "Merkle proof verification failed");
    }

    function testVerifyMerkleProofInvalid() public view {
        // Arrange
        bytes32 leaf = keccak256(abi.encode("leafValue"));
        bytes32[] memory proof = new bytes32[](4);
        bytes32 intermediateHash = keccak256(abi.encode("node1"));
        proof[0] = keccak256(abi.encode("wrongNode")); // Invalid node

        bytes32 root = keccak256(abi.encodePacked(intermediateHash, leaf));

        // Act
        bool result = utility.verifyMerkleProof(leaf, proof, root);

        // Assert
        assertFalse(result, "Invalid Merkle proof incorrectly verified");
    }
}

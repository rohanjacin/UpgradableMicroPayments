const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { ethers } = require("ethers");

function main() {
    const elements = [["Alice"], ["Bob"], ["Charlie"], ["Dave"]];
    const tree = StandardMerkleTree.of(elements, ["string"]);
    console.log("Merkle Root:", tree.root);

    // Generate a proof for a specific element
    const elementToProve = ["Bob"];
    for (const [index, value] of tree.entries()) {
        if (JSON.stringify(value) === JSON.stringify(elementToProve)) {
            const proof = tree.getProof(index);
            console.log(`Proof for ${elementToProve[0]}:`, proof);
            break;
        }
    }

    const leaf = ethers.keccak256(ethers.toUtf8Bytes("Bob"));
    console.log("Hashed Leaf:", leaf);
}

main();
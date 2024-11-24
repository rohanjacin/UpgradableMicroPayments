const { ethers } = require("ethers");

function main() {
    const seed = ethers.keccak256(ethers.randomBytes(32));
    console.log(seed);
    const hashChain = [];
    hashChain.push(seed);
    for (let i = 0; i < 1000; i++) {
        const nextHash = ethers.keccak256(hashChain[hashChain.length - 1]);
        hashChain.push(nextHash);
    }
    // console.log("Last 5 hashes in the chain:", hashChain.slice(hashChain.length - 5, hashChain.length));
    console.log(hashChain[400]);
    console.log(hashChain[1000]);
}

main();
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/PaymentChannel.sol";
import "../src/Utility.sol";

contract PaymentChannelTest is Test {
    PaymentChannel public paymentChannel;
    Utility public utility;

    address public payer = address(0x123);
    address public merchant = address(0x456);

    function setUp() public {
        // Deploy the Utility contract
        utility = new Utility();

        // Deploy the PaymentChannel contract, passing the utility address
        paymentChannel = new PaymentChannel(address(utility));
    }

    function testCreateChannel() public {
        bytes32 seed = keccak256(abi.encodePacked("seed"));
        uint256 amount = 1 ether;
        uint256 numberOfTokens = 1000;
        uint256 withdrawAfterBlocks = 100;

        vm.deal(payer, amount); // Fund the payer with the required amount

        // Generate the hash chain
        bytes32[] memory hashChain = new bytes32[](numberOfTokens + 1);
        hashChain[0] = keccak256(abi.encodePacked(seed)); // h_0 = h(seed)
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            hashChain[i] = keccak256(abi.encodePacked(hashChain[i - 1]));
        }

        bytes32 trustAnchor = hashChain[numberOfTokens]; // The last hash is the trust anchor

        vm.prank(payer); // Simulate transaction from the payer
        paymentChannel.createChannel{value: amount}(
            merchant,
            trustAnchor,
            amount,
            numberOfTokens,
            withdrawAfterBlocks
        );

        // Verify the channel details
        (
            bytes32 storedTrustAnchor,
            uint256 storedAmount,
            uint256 storedTokens,
            uint256 blocks
        ) = paymentChannel.channelsMapping(payer, merchant);
        assertEq(storedTrustAnchor, trustAnchor);
        assertEq(storedAmount, amount);
        assertEq(storedTokens, numberOfTokens);
        assertEq(blocks, withdrawAfterBlocks);
    }

    function testWithdrawChannel() public {
        bytes32 seed = keccak256(abi.encodePacked("seed"));
        uint256 amount = 1 ether;
        uint256 numberOfTokens = 1000;
        uint256 numberOfTokensUsed = 500;
        uint256 withdrawAfterBlocks = 100;

        // Generate the hash chain
        bytes32[] memory hashChain = new bytes32[](numberOfTokens + 1);
        hashChain[0] = keccak256(abi.encodePacked(seed)); // h_0 = h(seed)
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            hashChain[i] = keccak256(abi.encodePacked(hashChain[i - 1]));
        }

        bytes32 trustAnchor = hashChain[numberOfTokens];
        bytes32 finalHashValue = hashChain[numberOfTokensUsed]; // Hash after numberOfTokensUsed iterations

        // Setup a channel
        vm.deal(payer, amount);
        vm.prank(payer);
        paymentChannel.createChannel{value: amount}(
            merchant,
            trustAnchor,
            amount,
            numberOfTokens,
            withdrawAfterBlocks
        );

        // Simulate withdrawal
        vm.prank(merchant);
        paymentChannel.withdrawChannel(
            payer,
            finalHashValue,
            numberOfTokensUsed
        );

        // Verify channel deletion
        (, uint256 storedAmount, , ) = paymentChannel.channelsMapping(
            payer,
            merchant
        );
        assertEq(storedAmount, 0); // Channel should be deleted

        // Verify funds transfer
        uint256 expectedPayment = (amount * numberOfTokensUsed) /
            numberOfTokens;
        assertEq(merchant.balance, expectedPayment);
    }
}

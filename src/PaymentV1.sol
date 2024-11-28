// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Utility.sol";

contract PaymentV1 {
    Utility public utility;

    struct Channel {
        bytes32 trustAnchor;
        uint256 amount;
        uint256 numberOfTokens;
        uint256 withdrawAfterBlocks;
    }

    // Nested mapping to store channels: user => merchant => Channel
    mapping(address => mapping(address => Channel)) public channelsMapping;

    constructor(address utilityAddress) {
        utility = Utility(utilityAddress);
    }

    function createChannel(
        address merchant,
        bytes32 trustAnchor,
        uint256 amount,
        uint256 numberOfTokens,
        uint256 withdrawAfterBlocks
    ) public payable {
        require(msg.value == amount, "incorrect amount sent.");
        channelsMapping[msg.sender][merchant] = Channel({
            trustAnchor: trustAnchor,
            amount: amount,
            numberOfTokens: numberOfTokens,
            withdrawAfterBlocks: withdrawAfterBlocks
        });
    }

    function withdrawChannel(
        address payer,
        bytes32 finalHashValue,
        uint256 numberOfTokensUsed
    ) public {
        Channel storage channel = channelsMapping[payer][msg.sender]; // Use storage to update state directly
        require(
            channel.amount > 0,
            "Channel does not exist or has been withdrawn."
        );

        require(
            utility.verifyHashchain(
                channel.trustAnchor,
                finalHashValue,
                numberOfTokensUsed
            ),
            "Verification failed."
        );

        uint256 payableAmount = (channel.amount * numberOfTokensUsed) /
            channel.numberOfTokens;
        require(payableAmount > 0, "No amount is payable.");
        delete channelsMapping[payer][msg.sender];

        (bool sent, ) = payable(msg.sender).call{value: payableAmount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Utility.sol";

contract PaymentChannelV2 {
    Utility public utility;

    struct Channel {
        bytes32 trustAnchor;
        uint256 amount;
        uint256 withdrawAfterBlocks;
        uint256 numberOfTokens;
        // mapping(address => uint256) payableMerchants;
    }

    mapping(address => Channel) channelsMapping;
    mapping(address => mapping(address => uint256)) payableMerchants;
    mapping(bytes32 => bool) public consumedTokens;

    event ChannelCreated(
        address indexed payer,
        uint256 amount,
        uint256 numberOfTokens
    );
    event TokenAdded(
        address indexed payer,
        address indexed merchant,
        bytes32 token
    );
    event MerchantPaid(
        address indexed payer,
        address indexed merchant,
        uint256 amount
    );

    constructor(address utilityAddress) {
        utility = Utility(utilityAddress);
    }

    function createChannel(
        bytes32 trustAnchor,
        uint256 amount,
        uint256 withdrawAfterBlocks,
        uint256 numberOfTokens
    ) public payable {
        require(msg.value == amount, "incorrect amount sent.");
        // prevent accidental overwrite
        require(
            channelsMapping[msg.sender].amount == 0,
            "Channel already exists."
        );
        Channel memory newChannel = channelsMapping[msg.sender];
        newChannel.trustAnchor = trustAnchor;
        newChannel.amount = amount;
        newChannel.withdrawAfterBlocks = withdrawAfterBlocks;
        newChannel.numberOfTokens = numberOfTokens;

        emit ChannelCreated(msg.sender, amount, numberOfTokens);
    }

    function addTokenToChannel(
        address payer,
        bytes32[] calldata merkleProof,
        bytes32 token
    ) public {
        Channel memory channel = channelsMapping[payer];
        require(
            utility.verifyMerkleProof(merkleProof, channel.trustAnchor, token),
            "Token verification failed"
        );
        require(!consumedTokens[token], "Token already used.");
        consumedTokens[token] = true;
        // channel.payableMerchants[msg.sender] += 1;
        payableMerchants[payer][msg.sender] += 1;
        emit TokenAdded(payer, msg.sender, token);
    }

    function payMerchant(address payer, address merchant) public {
        Channel storage channel = channelsMapping[payer];
        uint256 payableAmount = (channel.amount *
            payableMerchants[payer][merchant]) / channel.numberOfTokens;
        require(payableAmount > 0, "No amount is payable.");

        payableMerchants[payer][merchant] = 0;

        (bool sent, ) = payable(merchant).call{value: payableAmount}("");
        require(sent, "Failed to send Ether");
        emit MerchantPaid(payer, merchant, payableAmount);
    }

    function getMerchantBalance(
        address payer,
        address merchant
    ) public view returns (uint256) {
        return payableMerchants[payer][merchant];
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

interface IPayment {

    function house() external view returns (address);

	function getVersionConfigurator() external view returns(address);

    // Starts a payment instance
    function newPayment(uint8 _version, address _bidder)
        external returns (bool success, string memory message);

    // Create channel for payment (9c2eb48b)
    function createChannel(address merchant, uint256 amount,
    	uint256 numberOfTokens, bytes calldata data,
        bytes calldata signature)
    	external payable;

    // Withdraw from channel (ad9085d1)
    function withdrawChannel(address payer, uint256 amount,
    	uint256 claimTokens, bytes calldata data)
    	external returns (bool sent);
}
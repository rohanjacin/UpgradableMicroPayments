// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

interface IPayment {

    function house() external view returns (address);

	function getVersionConfigurator() external view returns(address);

    // Create channel for payment
    function createChannel(address merchant, bytes32 trustAnchor,
        uint256 amount, uint256 numberOfTokens, uint256 withdrawAfterBlocks
    ) external;

    // Withdraw from channel
    function withdrawChannel(address payer, bytes32 finalHashValue,
        uint256 numberOfTokensUsed) external
        returns (uint256 amount, uint256 numberOfTokens);
}
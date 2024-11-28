// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

interface IVersionConfigurator {
	
    struct VersionConfig {
        // packed
        uint256 num; // 0x00
        uint256 versionLen; // 0x20 
        uint256 stateLen; // 0x40
        uint256 symbolLen; // 0x60
        bytes32 codeHash; // 0x80
        bytes32 hash; // 0xA0
        address codeAddress; // 0xC0
        address dataAddress; // 0xE0
    }

    // Reads the version proposal
    function initVersion(
        bytes calldata _versionLen,
        bytes calldata _versionState,
        bytes calldata _versionSymbols,
        bytes32 _versionCodeHash
    ) external payable returns (bool success);

    // Deploys the version
    function deployVersion(
        bytes calldata _versionCode,
        bytes calldata _versionNumber,
        bytes calldata _versionState,
        bytes calldata _versionSymbols,
        bytes32 msgHash,
        uint8 versionId,
        bytes memory signature
    ) external payable returns (bool success);

    // Fetches the proposal of a bidder
    function getProposal(address bidder) external view
        returns (VersionConfig memory config);
}
// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import {console} from "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "./IVersionConfigurator.sol";

error BiddersAddressInvalid();
error BiddersVersionCodeSizeInvalid();
error BiddersVersionStateSizeInvalid();
error BiddersStatesInvalid();
error FailedToCacheVersion();
error FailedToDeployVersion();

// Proposal Version configuration
struct VersionConfig {
    // packed
    uint256 num; // 0x00
    uint256 codeLen; // 0x20
    uint256 numLen; // 0x40
    uint256 stateLen; // 0x60
    uint256 symbolLen; // 0x80
    bytes32 hash; // 0xA0
    address codeAddress; // 0xC0
    address dataAddress; // 0xE0
}

contract VersionConfigurator {
    // Admin (Slot 0)
    address admin;

    // Constants (Slot 1)
    uint8 internal constant MAX_VERSION_STATE = type(uint8).max;
    uint32 internal constant MAX_VERSION_CODESIZE = 24000; // 24kB

    // Version Proposals (Slot 2)
    mapping(address => VersionConfig) proposals;

    constructor(address _admin) {
        admin = _admin;
    }

    function getProposal(address bidder) external view
        returns (VersionConfig memory config) {

        if (bidder == address(0)) {
            revert BiddersAddressInvalid();
        }

        config = proposals[bidder];
    }

    // Reads the version proposal
    function initVersion(
        bytes calldata _versionCode,
        bytes calldata _versionNumber,
        bytes calldata _versionState,
        bytes calldata _versionSymbols
    ) external payable returns (bool success) {
        // Check for sender's address
        if (msg.sender == address(0)) revert BiddersAddressInvalid();

        // Check for code length
        if (
            (_versionCode.length > MAX_VERSION_CODESIZE) || (_versionCode.length == 0)
        ) revert BiddersVersionCodeSizeInvalid();

        // Check for version number
        uint8 versionNum;
        assembly {
            versionNum := byte(0, calldataload(_versionNumber.offset))
        }

        // Check for version state length
        if ((_versionState.length >= MAX_VERSION_STATE) || (_versionState.length == 0)) {
            revert BiddersVersionStateSizeInvalid();
        }

        // Check for number of symbols in version

        // Check state against common version rules
        if (1 == _checkStateValidity(_versionNumber, _versionState, _versionSymbols)) {
            revert BiddersStatesInvalid();
        }

        // Cache reference for version (version code, version num, state and symbols)
        if (false == _cacheLevel(_versionCode, _versionNumber,
                            _versionState,_versionSymbols)) {
            revert FailedToCacheVersion();
        }

        success = true;
    }

    // Deploys the version
    function deployVersion(
        bytes calldata _versionCode,
        bytes calldata _versionNumber,
        bytes calldata _versionState,
        bytes calldata _versionSymbols,
        bytes32 msgHash,
        uint8 versionId,
        bytes memory signature
    ) external payable returns (bool success) {
        // Check in cached proposals if hash matches
        VersionConfig memory config = proposals[msg.sender];

        // Verify version configuration
        if (
            (config.codeLen != _versionCode.length) ||
            (config.numLen != _versionNumber.length) ||
            (config.stateLen != _versionState.length) ||
            (config.symbolLen != _versionSymbols.length)
        ) {
            revert FailedToDeployVersion();
        }

        bytes32 hash = keccak256(
            abi.encodePacked(
                _versionCode,
                _versionNumber,
                _versionState,
                _versionSymbols
            )
        );

        if ((config.hash != hash) || (config.hash != msgHash)) {
            revert FailedToDeployVersion();
        }

        // Verify signature
        bytes32 sigHash = MessageHashUtils.toEthSignedMessageHash(msgHash);

        // No precompiles on anvil local chain, uncomment when testing
        // on testnet.
        if (ECDSA.recover(sigHash, signature) != msg.sender) {
            revert FailedToDeployVersion();
        }

        // Deploy using create2
        bytes memory code = abi.encodePacked(_versionCode,
           abi.encode(_versionNumber, _versionState, _versionSymbols)
        );

        assembly {
            let target := create2(0, add(code, 0x20), mload(code), versionId)
            mstore(add(config, 0xC0), target)
        }

        // Register data address
        if (config.codeAddress != address(0)) {
            (bool ret, bytes memory addr) = config.codeAddress.call{value: 0}(
                abi.encodeWithSignature("data()")
            );

            if (ret == true) {
                config.dataAddress = abi.decode(addr, (address));
                proposals[msg.sender] = config;
            }

            success = true;
        }
    }

    // Cache the hash of proposal
    // i.e version code, number, state and symbols
    function _cacheLevel(
        bytes memory _versionCode,
        bytes memory _versionNumber,
        bytes memory _versionState,
        bytes memory _versionSymbols
    ) internal returns (bool success) {
        VersionConfig memory config = VersionConfig(
            uint256(0), uint256(0), uint256(0),
            uint256(0), uint256(0), bytes32(0),
            address(0), address(0)
        );

        // Register the lengths
        assembly {
            // num
            let ptr := config
            mstore(ptr, byte(0, mload(add(_versionNumber, 0x20))))

            // codeLen
            ptr := add(config, 0x20)
            mstore(ptr, mload(_versionCode))

            // numLen
            ptr := add(config, 0x40)
            mstore(ptr, mload(_versionNumber))

            // stateLen
            ptr := add(config, 0x60)
            mstore(ptr, mload(_versionState))

            // symbolLen
            ptr := add(config, 0x80)
            mstore(ptr, mload(_versionSymbols))
        }

        // Calculate hash
        config.hash = keccak256(
            abi.encodePacked(_versionCode, _versionNumber, _versionState, _versionSymbols)
        );

        proposals[msg.sender] = config;

        success = true;
    }

    // Check state validity
    function _checkStateValidity(
        bytes memory _versionNumber,
        bytes memory _versionState,
        bytes memory _versionSymbols
    ) internal pure returns (uint8 ret) {
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert("Not Admin");
        _;
    }
}

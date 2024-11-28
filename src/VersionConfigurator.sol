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
error BiddersStatesSymbolsInvalid();

// Proposal of ERC20 configuration
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

contract VersionConfigurator {
    // Admin (Slot 0)
    address admin;

    // Constants (Slot 1)
    uint8 internal constant MAX_VERSION_STATE = 138;

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
        bytes calldata _versionLen,
        bytes calldata _versionState,
        bytes calldata _versionSymbols,
        bytes32 _versionCodeHash
    ) external payable returns (bool success) {
        
        // Check for sender's address
        if (msg.sender == address(0)) {
            revert BiddersAddressInvalid();
        }

        // Check for version number
        uint8 versionNum;
        assembly {
            versionNum := byte(0, calldataload(_versionLen.offset))
        }

        // Check for version state length
        if ((_versionState.length >= MAX_VERSION_STATE) || (_versionState.length == 0)) {
            revert BiddersVersionStateSizeInvalid();
        }

        if (versionNum == 1) {

            // Check for number of symbols in version1
            // (i.e 6 bytes per method/symbol,
            // e.g "f26be922V1" is 6 bytes)
            if (!(_versionSymbols.length == 12)) {
                // "createChannel" and "withdrawChannel"
                revert BiddersStatesSymbolsInvalid();
            }
        }
        else if (versionNum == 2) {

            // Check for number of symbols in version1
            // (i.e 6 bytes per method/symbol,
            // e.g "f26be922V2" is 6 bytes)
            if (!(_versionSymbols.length == 18)) {
                // "createChannel", "withdrawChannel" and "addToken"
                revert BiddersStatesSymbolsInvalid();  
            }
        }

        // Check state against common version rules
        if (1 == _checkVersionValidity(_versionLen, _versionState, _versionSymbols)) {
            revert BiddersStatesInvalid();
        }

        // Cache reference for version (version num, state, symbols and code hash)
        if (false == _cacheLevel(_versionLen, _versionState,
                    _versionSymbols, _versionCodeHash)) {
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
        if (config.hash != msgHash) {
            revert FailedToDeployVersion();
        }

        if ((config.versionLen != _versionNumber.length) ||
            (config.stateLen != _versionState.length) ||
            (config.symbolLen != _versionSymbols.length)
        ) {
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
            // Store codeAddress
            mstore(add(config, 0xC0), target)
        }

        // Register data address
        if (config.codeAddress != address(0)) {
            (bool ret, bytes memory addr) = config.codeAddress.call{value: 0}(
                abi.encodeWithSignature("data()")
            );

            if (ret == true) {
                config.dataAddress = abi.decode(addr, (address));

                assembly {
                    let ptr := mload(0x40)

                    mstore(ptr, caller())
                    mstore(0x40, add(ptr, 0x20))

                    mstore(add(ptr, 0x20), proposals.slot)
                    mstore(0x40, add(ptr, 0x40))

                    let bslot := keccak256(ptr, 0x40)
                    // Store codeAddress
                    sstore(add(bslot, 6), mload(add(config, 0xC0)))
                    // Store dataAddress
                    sstore(add(bslot, 7), mload(add(config, 0xE0)))
                }
            }

            success = true;
        }
    }

    // Cache the hash of proposal
    // i.e version code, number, state and symbols
    function _cacheLevel(
        bytes memory _number,
        bytes memory _state,
        bytes memory _symbols,
        bytes32 _versionCodeHash
    ) internal returns (bool success) {

        // Calculate hash
        bytes32 _hash = keccak256(
            abi.encodePacked(_number, _state, _symbols, _versionCodeHash)
        );

        // Register the lengths
        assembly {
            let ptr := mload(0x40)

            mstore(ptr, caller())
            mstore(0x40, add(ptr, 0x20))

            mstore(add(ptr, 0x20), proposals.slot)
            mstore(0x40, add(ptr, 0x40))

            let bslot := keccak256(ptr, 0x40)
            sstore(bslot, byte(0, mload(add(_number, 0x20))))
            sstore(add(bslot, 1), mload(_number))
            sstore(add(bslot, 2), mload(_state))
            sstore(add(bslot, 3), mload(_symbols))
            sstore(add(bslot, 4), _versionCodeHash)
            sstore(add(bslot, 5), _hash)
        }

        success = true;
    }

    // Check state and symbol validity
    function _checkVersionValidity(
        bytes memory _number,
        bytes memory _state,
        bytes memory _symbols
    ) internal pure returns (uint8 ret) {

        // Channel
        //bytes32 trustanchor;
        //uint256 amount;
        //uint256 numberOfTokens;
        //uint256 withdrawAfterBlocks;

        // Check version number
        uint8 num;

        assembly {
            num := byte(0, mload(add(_number, 0x20)))
            
            // version number should not be zero
            if iszero(num) {
                revert (0, 0)
            }

            // version number should not be > 9
            if gt(num, 10) {
                revert (0, 0)
            }

        }

        // Check state
        assembly {

            // check if state length is multiple of 
            // size of channel (currently 1 channel only)
            let len := mload(_state)
            if iszero(eq(len, mul(1, 128))) {
                revert (0, 0)
            }

            // check if trust anchor is empty
            let trustanchor := mload(add(_state, 0x20))
            if iszero(iszero(trustanchor)) {
                revert (0, 0)
            }

            // check if amount is non zero
            let amount := mload(add(_state, 0x40))
            if iszero(amount) {
                revert (0, 0)
            }

            // check if number of tokens is non zero
            let numoftokens := mload(add(_state, 0x80))
            if iszero(numoftokens) {
                revert (0, 0)
            }

            // check if withdraw after blocks is non zero
            let withdrawafterblocks := mload(add(_state, 0xa0))
            if iszero(withdrawafterblocks) {
                revert (0, 0)
            }
        }
 
        // Check symbols 
        assembly {

            // check each symbol is of type "v(x)" i.e "v1", "v2", etc 
            let len := div(mload(_symbols), 6)
            let word := mload(add(_symbols, 0x20))
            
            for { let i := len let s := 0 let v := 0} gt(i, 0) { i := sub(i, 1) } {

                let shift := shr(sub(256, mul(i, 48)), word)
                s := shl(208, and(shift, 0xFFFFFFFFFFFFFFFFFFFFFFFF))

                if iszero(eq(shr(248, "V"), byte(4, s))) {
                    revert (0, 0)
                }

                v := byte(5, s)

                if gt(v, 0x3A) {
                    revert (0, 0)
                }

                if lt(v, 0x2F) {
                    revert (0, 0)
                }

                if iszero(eq(sub(v, 0x30), num)) {
                    revert (0, 0)
                }
            }
        }
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert("Not Admin");
        _;
    }
}

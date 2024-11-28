// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import "src/VersionConfigurator.sol";
import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract TestVersionConfigurator is Test {
    using ECDSA for bytes32;
    address admin;
    address bidder1;

    VersionConfigurator versionConfig;

    function setUp() public {
        
        admin = vm.addr(0xabc123);
        bidder1 = vm.addr(0xabc124);

        versionConfig = new VersionConfigurator(admin);
    }

    // Generates version code
    function _generateVersionCode(uint8 _num) internal pure
        returns (bytes memory _versionCode) {

        if (_num == 1)
            _versionCode = hex"60408012";
        else if (_num == 2) 
            _versionCode = hex"6040801223";
    }

    // Generates version number
    function _generateVersionNum(uint8 _num) internal pure
        returns (bytes memory _versionNum) {

        if (_num == 1)
            _versionNum = abi.encodePacked(_num);
        else if (_num == 2) 
            _versionNum = abi.encodePacked(_num);
    }

    // Generates state for a version
    function _generateState(uint8 _num) internal pure
        returns (bytes memory _versionState) {

        bytes32 trustAnchor;
        uint256 amount;
        uint256 numberOfTokens;
        uint256 withdrawAfterBlocks;

        if (_num == 1) {
            amount = 20000;
            numberOfTokens = 4000;
            withdrawAfterBlocks = 100;

            _versionState = abi.encodePacked(trustAnchor, amount,
                            numberOfTokens, withdrawAfterBlocks);
        }
        else if (_num == 2) {
            amount = 30000;
            numberOfTokens = 5000;
            withdrawAfterBlocks = 200;

            _versionState = abi.encodePacked(trustAnchor, amount,
                            numberOfTokens, withdrawAfterBlocks);            
        }
    }

    // Generates symbols for a version
    function _generateSymbols(uint8 _num) internal pure
        returns (bytes memory _versionSymbols) {

        if (_num == 1) {
            bytes6 createChannelV1 = bytes6(abi.encodePacked(hex"f26be922", "V1"));
            bytes6 withdrawChannelV1 = bytes6(abi.encodePacked(hex"8d7cb017", "V1"));
            _versionSymbols = abi.encodePacked(createChannelV1, withdrawChannelV1);
        }
        else if (_num == 2) {
            bytes6 createChannelV2 = bytes6(abi.encodePacked(hex"f26be922", "V2"));
            bytes6 withdrawChannelV2 = bytes6(abi.encodePacked(hex"8d7cb017", "V2"));
            bytes6 addTokenToChannelV2 = bytes6(abi.encodePacked(hex"2b01c5fe", "V2"));

            _versionSymbols = abi.encodePacked(createChannelV2,
                    withdrawChannelV2, addTokenToChannelV2);
        }
    }

    // Test if the contract was created properly
    function test_levelCofigurator() external {


    }

    // Test init version
    function test_initVersion() external {

        bytes memory number = _generateVersionNum(1);
        bytes memory state = _generateState(1);
        bytes memory symbols = _generateSymbols(1);
        bytes memory code = _generateVersionCode(1);
        bytes32 codeHash = keccak256(abi.encodePacked(code));

        vm.prank(bidder1);
        versionConfig.initVersion(number, state, symbols, codeHash);
        vm.stopPrank();
    }

    // Test cache version
    function test_cacheVersion() external {

/*        bytes memory number = _generateVersionNum(1);
        bytes memory state = _generateState(1);
        bytes memory symbols = _generateSymbols(1);
        bytes memory code = _generateVersionCode(1);
        bytes32 codeHash = keccak256(abi.encodePacked(code));

        vm.prank(bidder1);
        versionConfig._cacheLevel(number, state, symbols, codeHash);
        vm.stopPrank();
*/    }

    // Test deploy version
    function test_deployVersion() external {

/*        bytes memory number = _generateVersionNum(1);
        bytes memory state = _generateState(1);
        bytes memory symbols = _generateSymbols(1);
        bytes memory code = _generateVersionCode(1);
        bytes32 codeHash = keccak256(abi.encodePacked(code));

        vm.prank(bidder1);
        versionConfig._cacheLevel(number, state, symbols, codeHash);
        vm.stopPrank();

        bytes32 msghash = keccak256(abi.encodePacked(number,
            state, symbols, codeHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xabc124,
            MessageHashUtils.toEthSignedMessageHash(msghash));

        vm.prank(bidder1);
        versionConfig.deployVersion(code, number, state, symbols,
                        msghash, 0x01, abi.encodePacked(r, s, v));
        vm.stopPrank();
*/    }


    // Test Version contents
    function test__checkVersionValidity() external {

/*        bytes memory number = _generateVersionNum(1);
        bytes memory state = _generateState(1);
        bytes memory symbols = _generateSymbols(1);

        versionConfig._checkVersionValidity(number, state, symbols);
 */   }

}
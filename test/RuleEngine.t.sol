// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import "src/RuleEngine.d.sol";
import "src/PaymentV1.sol";

contract TestRuleEngine is Test {
    address admin;
    address bidder1;

    RuleEngine ruleEngine;

    function setUp() public {
        
        admin = vm.addr(0xabc123);
        bidder1 = vm.addr(0xabc124);

        //ruleEngine = new RuleEngine();
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

    // Sets symbols in format BaseSymbolD.Symbols
    function _setSymbols(uint8 _num) internal pure
        returns (BaseSymbolD.Symbols memory _symbols) {

        if (_num == 1) {
            _symbols = BaseSymbolD.Symbols({v: new bytes6[](2)});
            _symbols.v[0] = bytes6(abi.encodePacked(hex"f26be922", "V1"));
            _symbols.v[1] = bytes6(abi.encodePacked(hex"8d7cb017", "V1"));
        }
        else if (_num == 2) {
            _symbols = BaseSymbolD.Symbols({v: new bytes6[](2)});
            _symbols.v[0] = bytes6(abi.encodePacked(hex"f26be922", "V2"));
            _symbols.v[1] = bytes6(abi.encodePacked(hex"8d7cb017", "V2"));
        }
    }

    // Test add rules
    function test_addRulesV1() external {

        bytes memory number = _generateVersionNum(1);
        bytes memory state = _generateState(1);
        bytes memory symbols = _generateSymbols(1);
        BaseSymbolD.Symbols memory symbolsStates = _setSymbols(1);

        vm.prank(bidder1);
        PaymentV1 paymentV1 = new PaymentV1(number, state, symbols);
        vm.stopPrank();

        vm.prank(bidder1);
        //ruleEngine.addRules(address(paymentV1), symbolsStates);
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import "forge-std/console.sol";

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BaseVersionD} from "../src/BaseVersion.d.sol";
import {BaseStateD} from "../src/BaseState.d.sol";
import {BaseSymbolD} from "../src/BaseSymbol.d.sol";
import {BaseDataD} from "../src/BaseData.d.sol";
import {VersionConfigurator} from "../src/VersionConfigurator.sol";
import {IVersionConfigurator} from "../src/IVersionConfigurator.sol";
import {PaymentV1} from "../src/PaymentV1.sol";
import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../src/IVersionConfigurator.sol";
import {IPayment} from "../src/IPayment.sol";

contract ProposeVersion1 is Script {

	function run() external {

		bytes memory _versionNum = _generateVersionNum(1);
		bytes memory _state = _generateState(1);
		bytes memory _symbols = _generateSymbols(1);
        bytes memory code = _generateVersionCode(1);
        bytes32 codeHash = keccak256(abi.encodePacked(code));

        uint256 privKey = vm.envUint("PRIVATE_KEY_BIDDER1");
        address signer = vm.addr(privKey);

        vm.startBroadcast(signer);

        address versionConfigurator = IPayment(
            address(0x8464135c8F25Da09e49BC8782676a84730C318bC))
            .getVersionConfigurator();
        //address versionConfigurator = address(0x356bc565e99C763a1Ad74819D413A6D58E565Cf2);
        IVersionConfigurator(versionConfigurator)
		  .initVersion(_versionNum, _state, _symbols, codeHash);

        bytes32 _msghash = keccak256(abi.encodePacked(_versionNum,
                            _state, _symbols, codeHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey,
            MessageHashUtils.toEthSignedMessageHash(_msghash));

        IVersionConfigurator(versionConfigurator)
            .deployVersion(code, _versionNum, _state, _symbols, _msghash, 0x22, 
                          abi.encodePacked(r, s, v));

		vm.stopBroadcast();
	}

    // Generates version code
    function _generateVersionCode(uint8 _num) internal pure
        returns (bytes memory _versionCode) {

        if (_num == 1)
            _versionCode = type(PaymentV1).creationCode;
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

        if (_num == 1)
            _versionState = abi.encodePacked(abi.encode(address(0x5FbDB2315678afecb367f032d93F642f64180aa3)));
        else if (_num == 2)
            _versionState = abi.encodePacked(abi.encode(address(0x5FbDB2315678afecb367f032d93F642f64180aa3)));
    }

    // Generates symbols for a version
    function _generateSymbols(uint8 _num) internal pure
        returns (bytes memory _versionSymbols) {

        if (_num == 1) {
            bytes6 createChannelV1 = bytes6(abi.encodePacked(hex"2e1c7a83", "V1"));
            bytes6 withdrawChannelV1 = bytes6(abi.encodePacked(hex"d359b0ff", "V1"));
            _versionSymbols = abi.encodePacked(createChannelV1, withdrawChannelV1);
        }
        else if (_num == 2) {
            bytes6 createChannelV2 = bytes6(abi.encodePacked(hex"2e1c7a83", "V2"));
            bytes6 withdrawChannelV2 = bytes6(abi.encodePacked(hex"d359b0ff", "V2"));

            _versionSymbols = abi.encodePacked(createChannelV2, withdrawChannelV2);
        }
    }

    // Sets symbols in format BaseSymbolD.Symbols
    function _setSymbols(uint8 _num) internal pure
        returns (BaseSymbolD.Symbols memory _symbols) {

        if (_num == 1) {
            _symbols = BaseSymbolD.Symbols({v: new bytes6[](2)});
            _symbols.v[0] = bytes6(abi.encodePacked(hex"2e1c7a83", "V1"));
            _symbols.v[1] = bytes6(abi.encodePacked(hex"d359b0ff", "V1"));
        }
        else if (_num == 2) {
            _symbols = BaseSymbolD.Symbols({v: new bytes6[](2)});
            _symbols.v[0] = bytes6(abi.encodePacked(hex"2e1c7a83", "V2"));
            _symbols.v[1] = bytes6(abi.encodePacked(hex"d359b0ff", "V2"));
        }
    }

}
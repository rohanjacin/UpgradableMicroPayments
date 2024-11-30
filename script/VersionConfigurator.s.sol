import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BaseVersionD} from "../src/BaseVersion.d.sol";
import {BaseStateD} from "../src/BaseState.d.sol";
import {BaseSymbolD} from "../src/BaseSymbol.d.sol";
import {BaseDataD} from "../src/BaseData.d.sol";
import {VersionConfigurator} from "../src/VersionConfigurator.sol";
import {IVersionConfigurator} from "../src/IVersionConfigurator.sol";
import {PaymentV1} from "../src/PaymentV1.sol";
import {PaymentV2} from "../src/PaymentV2.sol";
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

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address signer = vm.addr(privKey);

        vm.startBroadcast(signer);

        address versionConfigurator = IPayment(
            address(0x4AE85136760964B0A2d87fF8CAB53014AE458237))
            .getVersionConfigurator();
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
        else if (_num == 2) 
            _versionCode = type(PaymentV2).creationCode;
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
            _versionState = abi.encodePacked(bytes32(0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8));
        else if (_num == 2)
            _versionState = abi.encodePacked(bytes32(0x0652eee475adfb5c8a28481abd58887b7722a06fc1f675ac72caac9c7fa9c98e));
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
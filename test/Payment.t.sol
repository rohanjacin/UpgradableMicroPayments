// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import "src/Payment.d.sol";
import "src/PaymentV1.sol";
import "src/PaymentV2.sol";
import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract TestRuleEngine is Test {
    address admin;
    address bidder1;
    address payer;
    address merchant;

    VersionConfigurator versionConfigurator;
    Payment payment;

    function setUp() public {
        
        admin = vm.addr(0xabc123);
        bidder1 = vm.addr(0xabc124);
        payer = vm.addr(0xabc125);
        merchant = vm.addr(0xabc126);

        vm.prank(admin);
        payment = new Payment(admin);
        versionConfigurator = VersionConfigurator(payment.getVersionConfigurator());
        vm.stopPrank();
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

    // Test add rules
    function test_newPayment() external {

        bytes memory number = _generateVersionNum(1);
        bytes memory state = _generateState(1);
        bytes memory symbols = _generateSymbols(1);
        BaseSymbolD.Symbols memory symbolsStates = _setSymbols(1);
        bytes memory code = _generateVersionCode(1);
        bytes32 codeHash = keccak256(abi.encodePacked(code));
        bytes32 msghash = keccak256(abi.encodePacked(number,
            state, symbols, codeHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xabc124,
            MessageHashUtils.toEthSignedMessageHash(msghash));

        vm.prank(bidder1);
        versionConfigurator.initVersion(number, state, symbols, codeHash);
        vm.stopPrank();

        vm.prank(bidder1);
        versionConfigurator.deployVersion(code, number, state, symbols,
                    msghash, 0x02, abi.encodePacked(r, s, v));
        vm.stopPrank();

        vm.prank(admin);
        payment.newPayment(1, bidder1);
        vm.stopPrank();

        bytes32 trustAnchor = bytes32(0x55b45826d9b44a79090d79bd36d5d1cc57e1b70e6c041f5d7b607f3bcd94afe8);
        uint256 amount = 1 ether;
        uint256 withdrawAfterBlocks = 10;
        uint8[] memory _tokens = new uint8[](4); _tokens[0] = 1;
        bytes memory _state = abi.encodePacked(trustAnchor, amount, withdrawAfterBlocks, _tokens);
        
        bytes32 permitHash = keccak256(abi.encodePacked(payer,
            address(payment), amount, withdrawAfterBlocks));

        //bytes32 separator = IERC20Permit(address(0x9458CaACa74249AbBE9E964b3Ce155B98EC88EF2)).DOMAIN_SEPARATOR();
        bytes32 separator = bytes32(0xf88cca535e7a2cbf5c1376507b9d72b371a0bba106dca0008d1dc38b9ad35fe4);
        (v, r, s) = vm.sign(0xabc125,
            MessageHashUtils.toTypedDataHash(separator, permitHash));

        bytes memory signature = abi.encode(v, r, s);
        vm.deal(payer, amount);
        vm.prank(payer);
        payment.createChannel{value: amount}(
            merchant, amount, 100, _state, signature);
        vm.stopPrank();

/*        bytes32 finalHashValue = bytes32(0x6f42d24852604630a6344c345128f9d4e8f8ae8ce0a1cd0a2e7149a84de66f68);
        bytes memory _state1 = abi.encodePacked(finalHashValue);

        vm.prank(merchant);
        payment.withdrawChannel(payer, amount, 90, _state1);        
        vm.stopPrank();
*/    }
}


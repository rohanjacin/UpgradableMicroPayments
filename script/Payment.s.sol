// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BaseVersionD} from "../src/BaseVersion.d.sol";
import {BaseStateD} from "../src/BaseState.d.sol";
import {BaseSymbolD} from "../src/BaseSymbol.d.sol";
import {BaseDataD} from "../src/BaseData.d.sol";
import {Payment} from "../src/Payment.d.sol";
import {IPayment} from "../src/IPayment.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {USDe} from "../src/USDe.sol";

contract DeployPayment is Script {

	function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY_ADMIN");
        address signer = vm.addr(privKey);
        vm.startBroadcast(signer);

		Payment payment1 = new Payment(signer);
        
        vm.stopBroadcast();
        payment1=payment1;
        
	}

}

contract NewPayment is Script {

    function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY_ADMIN");
        address signer = vm.addr(privKey);
       
        vm.startBroadcast(signer);
        
        IPayment(address(0x8464135c8F25Da09e49BC8782676a84730C318bC))
            .newPayment(1, address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));

        vm.stopBroadcast();
    }
}

contract CreateChannel is Script {

    bytes32 PERMIT_TYPEHASH =
            0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;        
    uint256 amount = 3 ether;
    uint256 withdrawAfterBlocks = 1733044908 + 100000;

    function run() external {

        address signer = vm.addr(vm.envUint("PRIVATE_KEY_PAYER"));
        address merchant = vm.envAddress("MERCHANT");
        address paymentAddr = vm.envAddress("PAYMENT_ADDRESS");
     
        uint8[] memory _tokens = new uint8[](4); _tokens[0] = 1;
        bytes memory _state = abi.encodePacked(_generateHashChain(amount), amount, withdrawAfterBlocks, _tokens);
        //bytes32 separator = bytes32(0xf88cca535e7a2cbf5c1376507b9d72b371a0bba106dca0008d1dc38b9ad35fe4);
        bytes32 separator = USDe(0x5FbDB2315678afecb367f032d93F642f64180aa3).DOMAIN_SEPARATOR();
      //0x9458CaACa74249AbBE9E964b3Ce155B98EC88EF2
        console.log("separator:", uint256(separator));
        console.log("PERMIT_TYPEHASH:", uint256(PERMIT_TYPEHASH));
        console.log("signer:", signer);
        console.log("paymentAddr:", paymentAddr);
        console.log("uint256(0):", uint256(0));
        console.log("withdrawAfterBlocks:", withdrawAfterBlocks);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("PRIVATE_KEY_PAYER"),
            MessageHashUtils.toTypedDataHash(separator, keccak256(abi.encode(PERMIT_TYPEHASH, signer, paymentAddr,
            uint256(3), uint256(0), withdrawAfterBlocks))));

        console.log("v:", v);
        console.log("r:", uint256(r));
        console.log("s:", uint256(s));

        bytes memory signature = abi.encode(v, r, s);

        vm.deal(signer, amount);
        vm.startBroadcast(signer);

        IPayment(paymentAddr).createChannel{value: amount}
                (merchant, amount, 3, _state, signature);
        vm.stopBroadcast();
    }

    function _generateHashChain(uint256 amt) internal returns(bytes32 anchor)  {
        // Generate the hash chain
        bytes32[] memory hashChain = new bytes32[](amt / 1 ether + 1);
        hashChain[0] = keccak256(abi.encodePacked(keccak256(abi.encodePacked("seed")))); // h_0 = h(seed)
        for (uint256 i = 1; i <= amt / 1 ether; i++) {
            hashChain[i] = keccak256(abi.encodePacked(hashChain[i - 1]));
        }

        anchor = hashChain[amt / 1 ether];
        console.log("anchor:", uint256(anchor));
    }
}

contract WithdrawChannel is Script {

    function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY_MERCHANT");
        address signer = vm.addr(privKey);
        address payer = vm.envAddress("PAYER");
        address paymentAddr = vm.envAddress("PAYMENT_ADDRESS");
       
        uint256 amount = 1 ether;
        bytes32 finalHashValue = _generateHashChain(amount);      
        //bytes32 finalHashValue = bytes32(0x6f42d24852604630a6344c345128f9d4e8f8ae8ce0a1cd0a2e7149a84de66f68);
        bytes memory _state = abi.encodePacked(finalHashValue);

        vm.startBroadcast(signer);
        IPayment(paymentAddr).withdrawChannel(payer, amount, 1, _state);        
        vm.stopBroadcast();
        
    }

    function _generateHashChain(uint256 amt) internal returns(bytes32 anchor)  {
        // Generate the hash chain
        bytes32[] memory hashChain = new bytes32[](amt / 1 ether + 1);
        hashChain[0] = keccak256(abi.encodePacked(keccak256(abi.encodePacked("seed")))); // h_0 = h(seed)
        for (uint256 i = 1; i <= amt / 1 ether; i++) {
            hashChain[i] = keccak256(abi.encodePacked(hashChain[i - 1]));
        }

        anchor = hashChain[amt / 1 ether];
        console.log("anchor:", uint256(anchor));
    }

}
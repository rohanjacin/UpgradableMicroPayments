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

contract DeployPayment is Script {

	function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY_ADMIN");
        address signer = vm.addr(privKey);
        vm.startBroadcast(signer);

		Payment payment1 = new Payment(signer);
        
        vm.stopBroadcast();
        
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

    function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY_PAYER");
        address signer = vm.addr(privKey);
        address merchant = vm.envAddress("MERCHANT");
        address paymentAddr = vm.envAddress("PAYMENT_ADDRESS");
       
        bytes32 trustAnchor = bytes32(0xf88cca535e7a2cbf5c1376507b9d72b371a0bba106dca0008d1dc38b9ad35fe3);
        uint256 amount = 1 ether;
        uint256 withdrawAfterBlocks = 10;

        uint8[] memory _tokens = new uint8[](4); _tokens[0] = 1;
        bytes memory _state = abi.encodePacked(trustAnchor, amount, withdrawAfterBlocks, _tokens);
        bytes32 separator = bytes32(0xf88cca535e7a2cbf5c1376507b9d72b371a0bba106dca0008d1dc38b9ad35fe4);
        bytes32 permitHash = keccak256(abi.encodePacked(signer,
            address(0x8464135c8F25Da09e49BC8782676a84730C318bC),
            amount, withdrawAfterBlocks));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey,
            MessageHashUtils.toTypedDataHash(separator, permitHash));

        bytes memory signature = abi.encode(v, r, s);

        vm.deal(signer, amount);
        vm.startBroadcast(signer);

        IPayment(paymentAddr).createChannel{value: amount}
                (merchant, amount, 1, _state, signature);
        vm.stopBroadcast();
    }
}

contract WithdrawChannel is Script {

    function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY_MERCHANT");
        address signer = vm.addr(privKey);
        address payer = vm.envAddress("PAYER");
        address paymentAddr = vm.envAddress("PAYMENT_ADDRESS");
       
        uint256 amount = 1 ether;
        bytes32 finalHashValue = bytes32(0x6f42d24852604630a6344c345128f9d4e8f8ae8ce0a1cd0a2e7149a84de66f68);
        bytes memory _state = abi.encodePacked(finalHashValue);

        vm.startBroadcast(signer);
        IPayment(paymentAddr).withdrawChannel(payer, amount, 1, _state);        
        vm.stopBroadcast();
        
    }
}
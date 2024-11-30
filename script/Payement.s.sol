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

contract DeployPayment is Script {

	function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address signer = vm.addr(privKey);
        vm.startBroadcast(signer);

		Payment payment1 = new Payment(signer);
        
        vm.stopBroadcast();
        
        payment1=payment1;
	}

}

contract NewPayment is Script {

    function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address signer = vm.addr(privKey);
       
        vm.startBroadcast(signer);
        
        IPayment(address(0x8464135c8F25Da09e49BC8782676a84730C318bC))
            .newPayment(1, address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));

        vm.stopBroadcast();
    }
}
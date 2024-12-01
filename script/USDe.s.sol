// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {USDe} from "../src/USDe.sol";

contract DeployUSDe is Script {

	function run() external {

        uint256 privKey = vm.envUint("PRIVATE_KEY_USDE_DEPLOYER");
        address deployer = vm.addr(privKey);
        
        address payer = vm.envAddress("PAYER");
        address paymentAddr = vm.envAddress("PAYMENT_ADDRESS");
        address merchant = vm.envAddress("MERCHANT");

        vm.startBroadcast(deployer);
		USDe usde = new USDe("test", "USDE");
        vm.stopBroadcast();
        console.log("DOMAINSEPARATOR:", uint256(usde.DOMAIN_SEPARATOR()));

        vm.startBroadcast(deployer);
        usde.mint(payer, 6 ether);
        usde.mint(paymentAddr, 1 ether);
        usde.mint(merchant, 1 ether);
        vm.stopBroadcast();


	}

}
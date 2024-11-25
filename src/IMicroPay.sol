// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

interface IMicroPay {

    function house() external view returns (address);

    //function version() external view returns (uint256);

	function getVersionConfigurator() external view returns(address);
}
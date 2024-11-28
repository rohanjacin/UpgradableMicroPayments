// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

interface IPayment {

    function house() external view returns (address);

	function getVersionConfigurator() external view returns(address);
}
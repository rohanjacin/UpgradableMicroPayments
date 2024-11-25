// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

interface IVersion {

	function copyVersionData(bytes calldata _versionNumData,
		bytes calldata _stateData, bytes calldata _symbolsData)
		external returns(bool success);
}
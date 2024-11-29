// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

interface IVersion {

    function copyVersionData(bytes calldata _versionNum,
        bytes calldata _versionState, bytes calldata _versionSymbol)
        external returns(bool success);
}
// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;

import "./BaseVersion.d.sol";
import "./BaseState.d.sol";
import "./BaseSymbol.d.sol";
import "./BaseData.sol";
import "./RuleEngine.d.sol";
import "./VersionConfigurator.sol";
import "./IVersionConfigurator.sol";
import { IVersion } from "./IVersion.d.sol";
import { IPayment } from "./IPayment.sol";
import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Errors
error VersionInvalid();
error VersionCopyFailed();
error BidderAddressInvalid();

contract PaymentHouse {
	address public versionConfigurator;

	constructor(address _admin) {
		versionConfigurator = address(new VersionConfigurator(_admin));
	}
}

// Payment info
struct PaymentInfo {
	address versionCode;
	address versionData;	
	string message;
}

// Payment
contract Payment is BaseVersionD, BaseStateD, BaseSymbolD, BaseData, RuleEngine {

	// SLOT 0 is from  (Do NOT use SLOT 0)

	// SLOT 1 is from  (Do NOT use SLOT 1)

	// SLOT 2 is from  (Do NOT use SLOT 2)

	// SLOT 3 is from  (Do NOT use SLOT 3)

	// SLOT 4 is from  (Do NOT use SLOT 4)

	// SLOT 5 is from  (Do NOT use SLOT 5)

	// SLOT 6 is for Payment Admin
	address admin;

	// SLOT 7 is house
	PaymentHouse public house;

	// SLOT 8 is payment instance
	PaymentInfo paymentInfo;

	// Load the default state in Base 
	constructor(address _admin) {
		admin = _admin;

		// Payment House components
		house = new PaymentHouse(admin);
	}

	fallback() external {
	}

	// Fetches version configurator
	function getVersionConfigurator() external view returns(address) {
		return house.versionConfigurator();
	}

	// Direct calls to valid MicroPay Version Contract
	function callVersion(bytes calldata versionCall)
		external payable returns(bool success, bytes memory data) {

		// PaymentVersion Address + encoded Function Data (i.e sel, params)
        (address target, bytes memory callData) = abi.decode(versionCall,
													(address, bytes));

		if (target ==  paymentInfo.versionCode) {
			(success, data) = target.call{value: msg.value}(callData);
		}
	}

	// Retrieves the payment version contract's data
	function retrieveVersion(address data)
		internal returns (bytes memory _num,
		bytes memory _state, bytes memory _symbol) {

		bytes memory _data = BaseData.copyData(data);
		uint8 _numlen;
		uint8 _statelen;
		uint8 _symbollen;

		_numlen = 1;
		_statelen = 32;
		_symbollen = 2;

		assembly {
			// Total length and start
			let len := mload(_data)
			let ptr := add(_data, 0x20)

			// Reserve and copy version data 
			_num := mload(0x40)
			mcopy(add(_num, 0x20), ptr, _numlen)
			mstore(_num, _numlen)
			mstore(0x40, add(_num, 0x40))

			// Reserve and copy version state 
			_state := mload(0x40)
			mcopy(add(_state, 0x20), add(ptr, _numlen), _statelen)
			mstore(_state, _statelen)
			mstore(0x40, add(_state, 0x40))

			// Reserve and copy version state 
			_symbol := mload(0x40)
			mcopy(add(_symbol, 0x20), add(ptr, add(_numlen, _statelen)), mul(_symbollen, 6))
			mstore(_symbol, mul(_symbollen, 6))
			mstore(0x40, add(_symbol, 0x40))			
		}

	}

	// Loads the version
	function _loadVersion(uint8 _version, address bidder)
		internal returns(bool success, string memory message) {

		IVersionConfigurator.VersionConfig memory config;

		config = IVersionConfigurator(house.versionConfigurator())
						.getProposal(bidder);		

		// Level version for V1 or V2
		if (!(config.num == _version)) {
			//revert VersionInvalid();
		}

		(bytes memory _versionnum, 
		 bytes memory _versionstate,
		 bytes memory _versionsymbol) = retrieveVersion(config.dataAddress);

		// Copy Version via delegatecall	
		bytes memory cdata = abi.encodeCall(IVersion.copyVersionData,
			(_versionnum, _versionstate, _versionsymbol));
		
		uint256 size;
		address addr = config.codeAddress;
		assembly {
			size := extcodesize(addr)
		}
		(success, ) = config.codeAddress.delegatecall(cdata);

		if (success == false) {
			revert VersionCopyFailed();
		}

		// Store version address
		paymentInfo.versionCode = config.codeAddress;
		paymentInfo.versionData = config.dataAddress;

		// Add version rules
		uint8 _symbolLen = uint8(config.symbolLen/6);

		BaseSymbolD.Symbols memory _symbols = BaseSymbolD.Symbols(
			{v: new bytes6[](_symbolLen)});
		
		for (uint8 i = 0; i < _symbolLen; i++) {
			_symbols.v[i] = getSymbol(i);
		}

		addRules(paymentInfo.versionCode, _symbols);

		return (true, "Version loaded");
	}

	// Starts a payment instance
	function newPayment(uint8 _version, address _bidder)
		external onlyAdmin returns (bool success, string memory message) {

		// Check if version requested is for configured versions
		if (!((_version == 1) || (_version == 2))) {
			revert VersionInvalid();
		}

		if (_bidder == address(0)) {
			revert BidderAddressInvalid();
		}

		(success, message) = _loadVersion(_version, _bidder);

		if (success == true) {
			// Initalize payments

			// emit event
		}
	}

/*	function getPayments(uint8 id) external view returns(MicroPayInfo memory info){
		return payments[id];
	}
*/

    // Create channel for payment
    function createChannel(address merchant, uint256 amount,
    	uint256 numberOfTokens, bytes calldata data, 
    	bytes calldata signature)
    	public payable {

    	require (amount == msg.value, "Amount mismatch");
    	require (merchant != address(0), "Invalid address");

    	// Call version1 or version 2 createChannel method
    	//bytes4 sel = IPayment(address(this)).createChannel.selector;

    	bool success;
    	bytes memory _data;
    	(success, _data) = execRule(IPayment(address(this)).createChannel.selector,
    						merchant, amount, numberOfTokens,
    						paymentInfo.versionCode, data, signature);
    	
    	require(success, "Payment call failed");

    	uint256 deadline = channel[msg.sender][merchant].withdrawAfterBlocks;
    	bytes32 tokenId = BaseStateD.getState(version);
    	
    	(uint8 v, bytes32 r, bytes32 s) = abi.decode(signature,
    								(uint8, bytes32, bytes32));

    	IERC20Permit(address(uint160(uint256(tokenId))))
    		.permit(msg.sender, address(this), numberOfTokens,
    			  	deadline, v, r, s);
    }

    // Withdraw from channel
    function withdrawChannel(address payer, uint256 amount, 
    	uint256 claimTokens, bytes calldata data)
    	public returns (bool sent) {

    	require (payer != address(0), "Invalid address");
    	require (claimTokens != 0, "Invalid tokens");

    	// Call version1 or version 2 withdrawChannel method
    	bytes4 sel = IPayment(address(this)).withdrawChannel.selector;

    	bool success; 
    	bytes memory _data;
    	(success, _data) = execRule(
    						sel, payer, amount, claimTokens,
    						paymentInfo.versionCode, data);

    	uint256 _amount;
    	uint256 numberOfTokens;
    	assembly {
    		_amount := mload(add(_data, 0x60))
    		numberOfTokens := mload(add(_data, 0x80))
    	}
    	require(success, "Payment call failed");

        uint256 payableAmount = ((_amount / 1 ether) * claimTokens) /
                                 numberOfTokens;    		

        require(payableAmount > 0, "No amount is payable");

        bytes32 tokenId = BaseStateD.getState(version);
        sent = IERC20(address(uint160(uint256(tokenId)))).transferFrom(payer, msg.sender, payableAmount);
        
        require(sent, "Failed to send token");
    }

    modifier onlyAdmin {
        if (msg.sender != admin) revert("Not Admin");
        _;
    }
}
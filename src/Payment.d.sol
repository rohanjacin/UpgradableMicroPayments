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
	function callVersion(uint8 id, bytes calldata versionCall)
		external payable returns(bool success, bytes memory data) {

		// PaymentVersion Address + encoded Function Data (i.e sel, params)
        (address target, bytes memory callData) = abi.decode(versionCall,
													(address, bytes));

		if (target ==  paymentInfo.versionCode) {
			(success, data) = target.call{value: msg.value}(callData);
		}
	}

	// Retrieves the payment version contract's data
	function retrieveVersion(uint8 num, address data)
		internal returns (bytes memory _num,
		bytes memory _state, bytes memory _symbol) {

		bytes memory _data = BaseData.copyData(data);
		uint8 _numlen;
		uint8 _statelen;
		uint8 _symbollen;

		if (num == 1) {
			_numlen = 1;
			_statelen = 32;
			_symbollen = 2;
		}
		else if (num == 2) {
			_numlen = 1;
			_statelen = 32;
			_symbollen = 2;
		}

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

		console.log("");
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
		 bytes memory _versionsymbol) = retrieveVersion(uint8(config.num),
		 								config.dataAddress);

		// Copy Version via delegatecall	
		bytes memory cdata = abi.encodeCall(IVersion.copyVersionData,
			(_versionnum, _versionstate, _versionsymbol));
		
		console.log("config.codeAddress:", config.codeAddress);

		uint256 size;
		address addr = config.codeAddress;
		assembly {
			size := extcodesize(addr)
		}
		console.log("SIZE:", size);
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
    	uint256 numberOfTokens, bytes calldata data)
    	public payable {

    	require (amount == msg.value, "Amount mismatch");
    	require (merchant != address(0), "Invalid address");

    	// Call version1 or version 2 createChannel method
    	bytes4 sel = IPayment(address(this)).createChannel.selector;

    	bool success;
    	bytes memory _data;
    	(success, _data) = execRule(
    						sel, merchant, amount, numberOfTokens,
    						paymentInfo.versionCode, data);
    	
    	require(success, "Payment call failed");
    }

    // Withdraw from channel
    function withdrawChannel(address payer, uint256 amount, 
    	uint256 claimTokens, bytes calldata data)
    	public returns (uint256 _amount, uint256 numberOfTokens) {

    	require (payer != address(0), "Invalid address");
    	require (claimTokens != 0, "Invalid tokens");

    	// Call version1 or version 2 withdrawChannel method
    	bytes4 sel = IPayment(address(this)).withdrawChannel.selector;

    	bool success; 
    	bytes memory _data;
    	(success, _data) = execRule(
    						sel, payer, amount, claimTokens,
    						paymentInfo.versionCode, data);

    	assembly {
    		_amount := mload(add(_data, 0x60))
    		numberOfTokens := mload(add(_data, 0x80))
    	}
    	require(success, "Payment call failed");

        uint256 payableAmount = ((_amount / 1 ether) * claimTokens) /
                                 numberOfTokens;    		

        require(payableAmount > 0, "No amount is payable");

        (bool sent, ) = payable(msg.sender).call{value: payableAmount}("");
        
        require(sent, "Failed to send Ether");
    }

    modifier onlyAdmin {
        if (msg.sender != admin) revert("Not Admin");
        _;
    }
}
Upgradable Payments

The project is a simple concept of an upgradable 
auto payment channel between a merchant and a payer.

It works with any ERC20Permit token and is compatiable
with USDe tokens as well. 

![UpgradablePayments](./UpgradablePayment.jpg?raw=true "UpgradablePayment")

The following steps are required for it functioning

1. The payer creates a channel to pay a merchant
   - the channel if defined by the following
     a. The amount deposited by the payer
     b. The number of blocks after which the
        payment is available for the merchant to withdraw
     c. The token id to be used for the transaction

2. The merchant withdraws from the channel
   - the withdraw if defined by the following
     a. the payer address
     b. the number of tokens to withdraw

3. The criteria for withdrawal is depends on the 
   version of the payment system being currently used.
   - In version 1 we use knowledge of pre-hash image
     for the merchant to withdraw successfully.
   - In version 2 we use merkel proofs.  

4. The admin can upgrade the payment channels to
   support new tokens and new withdrawal schemes.

5. These new tokens support and withdrawal criteria
   can be proposed by the community dev's and be deployed
   programatically by the dapp itself. 

6. For the demo, it is shown that the Ethena token USDe
   can be proposed as supported token to extended the 
   payment channels to trade in USDe.


Project Limitations

1. Although we tested the project on the localnet with a simulation
   of the USDe ERC20Permit token, we were unable to test on sepolia with USDe due to an unknown issue on the testnet.

2. This project trys to showcase the use-case where a DeFi app 
   can easily add support for tokens like USDe in a programmatical way.


The steps to test (on anvil)

1. Deployer deploys the simpluated USDe token contract

	forge script script/USDe.s.sol:DeployUSDe --fork-url http://localhost:8545 --broadcast -vvvv --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

2. Admin deploys the Payment Contract

	forge script script/Payment.s.sol:DeployPayment --fork-url http://localhost:8545 --broadcast -vvvv --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

2. Bidder proposes a version of the Payment app to support USDe

	forge script script/VersionConfigurator.s.sol:ProposeVersion1 --fork-url http://localhost:8545 --broadcast -vvvv --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

3. Admin creates the new version proposed by the bidder & loads it 
	forge script script/Payment.s.sol:NewPayment --fork-url http://localhost:8545 --broadcast -vvvv --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

4. Payer created a payment channel for the merchant

	forge script script/Payment.s.sol:CreateChannel --fork-url http://localhost:8545 --broadcast -vvvv --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a

5. Merchant withdraws the tokens 

	forge script script/Payment.s.sol:WithdrawChannel --fork-url http://localhost:8545 --broadcast -vvvv --private-key 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba


Local anvil net only, Please do no use these keys in production

Copy in .env and "source .env" 

PRIVATE_KEY_USDE_DEPLOYER="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

PRIVATE_KEY_ADMIN="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

PRIVATE_KEY_BIDDER1="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

PRIVATE_KEY_PAYER="0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"

PRIVATE_KEY_MERCHANT="0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"

USDE_DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
ADMIN="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
BIDDER1="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
PAYER="0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
MERCHANT="0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"

// Contract Addresses
PAYMENT_ADDRESS="0x8464135c8F25Da09e49BC8782676a84730C318bC"
PAYMENT_HOUSE_ADDRESS="0x8398bCD4f633C72939F9043dB78c574A91C99c0A"
VERSIONCONFIGURATOR_ADDRESS="0x356bc565e99C763a1Ad74819D413A6D58E565Cf2"
PAYMENTV1_ADDRESS="0x87FBe30a4bb9B8D42ea1b05B1E75de1D43f66846"
PAYMENTV1_DATA_ADDRESS="0xa28CA2B6cc9C5E1277d997Fa6b1A0BB034eF810C"

# ICO-Code
This repository includes token creation and token sales code.  
## CrowdSale Functions:  

### Token.sol (main contract: AssetToken):
1.	AssetToken ():  total supply, administrator, token name, symbol and decimal units are set up.
2.	transfer ():  transfer tokens from your address to another. 
3.	balance_fun (): check the balance of specific address.
4.	approve (): allow another contract to spend some tokens from your address.
5.	buy (): buy tokens from the original token contracts. *need to run setPrice_onlyAdmin () first.
6.	sell (): sell tokens to the original token contracts. *need to run setPrice_onlyAdmin () first.
7.	transferFrom (): use contracts to transfer tokens from one account to another. *need to run approve () first.  
#### Following functions need administrator’s allowance to execute:
8.	transferAdminship_onlyAdmin (): change administrator to another address.
9.	mintToken _onlyAdmin ():  mint a fixed number of tokens to the total supply and also to target address.
10.	freezeAccount _onlyAdmin (): freeze typical users’ accounts. (who then can’t run functions of transfer(), buy(), sell(), transferFrom())
11.	setPrices_onlyAdmin (): set tokens' buying and selling prices.
12.	liquidate_onlyAdmin (): liquidate ether to administrator’s address.
13.	selfdestruct_onlyAdmin(): self destruct the tokens.

### Crowdsale-stage-4.sol (main contract: CrowdSale):
1.	CrowdSale (): set up parameters of lasting time, campaign URL, beneficiary address, token address, token’s value by ether, minimum and maximum of funding.
2.	contribute (): let investor send ether to contract address to get tokens. And check if ICO expires.
3.	checkIfFundingCompleteOrExpired (): check if ICO completes or expires.
4.	payOut (): send ethers and remaining tokens to beneficiary address.
5.	getRefund (): if the ICO fails, investors trigger this function to get refunds.  
#### Following functions need contract creator’s allowance to execute:
6.	removeContract (): self-destroy contract and send remaining tokens and ether to the creator.

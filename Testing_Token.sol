pragma solidity ^0.4.11;
 
contract admined {
	address public admin;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
	function admined(){ admin = msg.sender;}

	modifier onlyAdmin(){
		if(msg.sender != admin) throw;
		_;
	}

	function transferAdminship_onlyAdmin(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}

}

contract Token {
    mapping (address => mapping (address => uint256)) public allowance;
	mapping (address => uint256) public balanceOf;
	
	string public name;
	string public symbol;
	uint8 public decimal; 
	uint256 public totalSupply;
	event Transfer(address indexed from, address indexed to, uint256 value);


	function Token(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits){
		balanceOf[msg.sender] = initialSupply;
		totalSupply = initialSupply;
		decimal = decimalUnits;
		symbol = tokenSymbol;
		name = tokenName;
	}

	function transfer(address _to, uint256 _value){
		if(balanceOf[msg.sender] < _value) throw;
		if(balanceOf[_to] + _value < balanceOf[_to]) throw;
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

    // Allow another contract to spend some tokens from your address.
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    //check the balance of specific address.
    function balance_fun(address _ad) returns(uint256 bala){
        bala=balanceOf[_ad];
    }
    
}

contract AssetToken is admined, Token{
    uint256 public sellPrice;
    uint256 public buyPrice;
    
	function AssetToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) Token (0, tokenName, tokenSymbol, decimalUnits ){
		totalSupply = initialSupply;
		if(centralAdmin != 0)
			admin = centralAdmin;
		else
			admin = msg.sender;
		balanceOf[admin] = initialSupply;
	}
    
	function transfer(address _to, uint256 _value){
		if (frozenAccount[msg.sender]) throw;
		if(balanceOf[msg.sender] <= 0) throw;
		if(balanceOf[msg.sender] < _value) throw;
		if(balanceOf[_to] + _value < balanceOf[_to]) throw;
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}
	
	//buy tokens from the originial token contracts (need to set buyPrice first)
    function buy() payable returns (uint amount){
        amount = msg.value / buyPrice;                    
        if (balanceOf[this] < amount) throw; 
        if (frozenAccount[msg.sender]) throw;
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
        return amount;                                     
    }

    //sell tokens to the originial token contracts (need to set sellPrice first)
    function sell(uint amount) returns (uint revenue){
        if (balanceOf[msg.sender] < amount ) throw; 
        if (frozenAccount[msg.sender]) throw;
        balanceOf[this] += amount;                         
        balanceOf[msg.sender] -= amount;                   
        revenue = amount * sellPrice;
        if (!msg.sender.send(revenue)) {                   
            throw;                                         
        } else {
            Transfer(msg.sender, this, amount);             
            return revenue;                                 
        }
    }
	
	//use contracts to transfer tokens from one account to another(should previously run function approve())
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                                    
        if (balanceOf[_from] < _value) throw;                 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
	
	function () payable{}
	
	/* Following functions are prepared for adminstrator's use. */
	
	//mint tokens when it is scarce
	function mintToken_onlyAdmin(address target, uint256 mintedAmount) onlyAdmin{
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
	}
	
	//freeze users' account
	function freezeAccount_onlyAdmin(address target, bool freeze) onlyAdmin {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    //set up tokens' buying and selling prices
    function setPrices_onlyAdmin(uint256 newSellPrice, uint256 newBuyPrice) onlyAdmin {
        sellPrice = newSellPrice * 1 ether;
        buyPrice = newBuyPrice * 1 ether;
    }
    
    //selfdestruct the tokens
    function selfdestruct_onlyAdmin() onlyAdmin{
       selfdestruct(msg.sender);
    }
    
    //liquidate ether to the administrator
    function liquidate_onlyAdmin(uint256 _ether, bool _liquidateall) onlyAdmin returns(uint256){
        if(_liquidateall){_ether=this.balance;}
        if (!admin.send(_ether)) {                   
                throw;                                         
            } else {
                return _ether;                                 
            }
    }
    
}

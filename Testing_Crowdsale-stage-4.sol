pragma solidity ^0.4.11;

contract token { function transfer(address receiver, uint amount);
                 function balance_fun(address _ad) returns(uint256);
                }

contract CrowdSale {
    enum State {
        Fundraising,
        Failed,
        Successful,
        Closed
    }
    State public state = State.Fundraising;

    struct Contribution {
        uint amount;
        address contributor;
    }
    Contribution[] contributions;

    
    
    uint public totalRaised;
    uint public currentBalance;
    uint public deadline;
    uint public completedAt;
    uint public priceInWei;
    uint public fundingMinimumTargetInWei; 
    uint public fundingMaximumTargetInWei; 
    token public tokenReward;
    address public creator;
    address public beneficiary; 
    string campaignUrl;
    byte constant version = 1;

    
    event LogFundingReceived(address addr, uint amount, uint currentTotal);
    event LogFundingRefunded(address addr, uint amount, uint currentTotal);
    event LogFundingFailed(address thiscontract);
    event LogWinnerPaid(address winnerAddress);
    event LogFundingSuccessful(uint totalRaised);
    event LogFunderInitialized(
        address creator,
        address beneficiary,
        string url,
        uint _fundingMaximumTargetInEther, 
        uint256 deadline);


    modifier inState(State _state) {
        checkIfFundingCompleteOrExpired();
        if (state != _state) throw;
        _;
    }

     modifier isMinimum() {
        if(msg.value < priceInWei) throw;
        _;
    }

    modifier inMultipleOfPrice() {
        if(msg.value%priceInWei != 0) throw;
        _;
    }

    modifier isCreator() {
        if (msg.sender != creator) throw;
        _;
    }

    
    modifier atEndOfLifecycle() {
        if(!((state == State.Failed || state == State.Closed) && completedAt + 1 hours < now)) {
            throw;
        }
        _;
    }

    
    function CrowdSale(
        uint _timeInMinutesForFundraising,
        string _campaignUrl,
        address _ifSuccessfulSendTo,
        uint _fundingMinimumTargetInEther,
        uint _fundingMaximumTargetInEther,     //have to be larger than minimum 
        token _addressOfTokenUsedAsReward,
        uint _finneyCostOfEachToken)
    {
        creator = msg.sender;
        beneficiary = _ifSuccessfulSendTo;
        campaignUrl = _campaignUrl;
        fundingMinimumTargetInWei = _fundingMinimumTargetInEther * 1 ether; 
        fundingMaximumTargetInWei = _fundingMaximumTargetInEther * 1 ether;
        if(fundingMaximumTargetInWei<fundingMinimumTargetInWei){throw;}
        deadline = now + (_timeInMinutesForFundraising * 1 minutes);
        currentBalance = 0;
        tokenReward = token(_addressOfTokenUsedAsReward);
        priceInWei = _finneyCostOfEachToken * 1 finney;   //1 ether = 1000 finney
        LogFunderInitialized(
            creator,
            beneficiary,
            campaignUrl,
            fundingMaximumTargetInWei,
            deadline);
    }

    function contribute()
    public
    inState(State.Fundraising) isMinimum() inMultipleOfPrice() payable returns (uint256)
    {
        uint256 amountInWei = msg.value;

        contributions.push(
            Contribution({
                amount: msg.value,
                contributor: msg.sender
                }) 
            );

        totalRaised += msg.value;
        currentBalance = totalRaised;

        tokenReward.transfer(msg.sender, amountInWei / priceInWei);
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        checkIfFundingCompleteOrExpired();
        return contributions.length; 
    }

    function checkIfFundingCompleteOrExpired() {
        if (totalRaised >= fundingMaximumTargetInWei) {
            state = State.Successful;
            LogFundingSuccessful(totalRaised);
            payOut();
            completedAt = now;
            
        } else if ( now > deadline )  {
            if(totalRaised >= fundingMinimumTargetInWei){
                state = State.Successful;
                LogFundingSuccessful(totalRaised);
                payOut();  
                completedAt = now;
            }
            else{
                state = State.Failed;
                LogFundingFailed(this);
                completedAt = now;    
            }
          } 
        
    }

    function payOut()
    public
    {
        uint bala;
        if (state != State.Successful) {throw;}
        bala=tokenReward.balance_fun(this);
        if(!beneficiary.send(this.balance)) {
            throw;
        }
        if(bala!=0){
        tokenReward.transfer(beneficiary,bala);
        }
        currentBalance = 0;
        LogWinnerPaid(beneficiary);
        state=State.Closed;
    }

    function getRefund()
    public
    returns (bool)
    {
        if (state != State.Failed) {throw;}
        
        for(uint i=0; i<contributions.length; i++)
        {
            if(contributions[i].contributor == msg.sender){
                uint amountToRefund = contributions[i].amount;
                contributions[i].amount = 0;
                if(!contributions[i].contributor.send(amountToRefund)) {
                    contributions[i].amount = amountToRefund;
                    return false;
                }
                else{
                    currentBalance -= amountToRefund;
                    LogFundingRefunded(msg.sender, amountToRefund, currentBalance);
                }
                return true;
            }
        }
        return false;
    }

    function removeContract()
    public
    isCreator()
    atEndOfLifecycle()
    {
        uint bala;
        bala=tokenReward.balance_fun(this);
        if(bala!=0){
        tokenReward.transfer(msg.sender,bala);
        }
        selfdestruct(msg.sender);
            
    }

    function () payable { 
        uint contri_num;
        contri_num=contributions.length;
        if(contri_num!=contribute()-1) {throw;}
    }
}

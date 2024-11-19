/// Module: ngodonations
module ngodonations::ngodonations {
use std::string::{String};
use sui::coin::{Self,Coin,split, put,take};
use sui::object::uid_to_inner;
use sui::balance::{Self, Balance,zero};
use sui::sui::SUI;
use sui::event;

     //define errors
     const ENOTAVAILABLE:u64=0;
     const ENOTOWNER:u64=1;
     const EINVALIDAMOUNT:u64=2;

     const USERNOTREGISTERED:u64=3;
     const EINVALAIDAMAOUNT:u64=4;


    //define the structs for the ngo
    public struct Ngo has key,store{

        id:UID,
        ngoid:ID,
        name:String,
        description:String,
        operationRegion:String,
        activities:vector<Activity>,
        members:vector<Member>,
        targetaamount:u64,
        enquiries:vector<Enquire>,
        balance:Balance<SUI>,
        donationhistory:vector<History>,
        transactionhistory:vector<Transaction>
    }

    public struct Transaction has store{
        amount:u64,
        recipient:address
    }

    public struct History has store{
        by:u64,
        amountdonated:u64
    }
    //admin cap
    public struct AdminCap has key{
        id:UID,
        ngoid:ID
    }
    //define type activity
    public struct Activity has store{
        id:u64,
        name:String,
        description:String
    }
    //define type member
    public struct Member has store{
        id:u64,
        name:String,
        region:String
    }

    //define the enquire type
    public struct Enquire has store{
        id:u64,
        enquire:String,
        by:u64
    }

    //define events
    public struct UmbrellaCraeated has drop,copy{
        name:String
    }

    public struct Withdrawal has copy,drop{
    recipient:address,
    amount:u64
}

//CRETE NGO

public entry fun create_ngo(name:String,description:String,operationRegion:String,target:u64,ctx:&mut TxContext){


//check if the name of the ngo is already taken;

let id=object::new(ctx);
let ngoid=object::uid_to_inner(&id);

//create a new ngo
let new_ngo=Ngo{
        id,
        ngoid,
        name,
        description,
        operationRegion,
        activities:vector::empty(),
        targetaamount:target,
        members:vector::empty(),
        enquiries:vector::empty(),
        balance:zero<SUI>(),
        donationhistory:vector::empty(),
        transactionhistory:vector::empty()
};
//add admin capabilities

 transfer::transfer(AdminCap {
        id:object::new(ctx),
        ngoid,
}, tx_context::sender(ctx));

transfer::share_object(new_ngo);
}

//function to change donation amount

public entry fun change_donations_amount(owner:&AdminCap,ngo:&mut Ngo,newamount:u64,_ctx:&mut TxContext){

    //check if the amount is greater than zero
    assert!(newamount >=1,EINVALAIDAMAOUNT);

    //verify its the owner performing the action

    assert!(owner.ngoid==ngo.ngoid,ENOTOWNER);

    //now update the ngo
    ngo.targetaamount=newamount;
}

//function  to add activities to ngo

public entry fun add_activities(owner:&AdminCap,ngo:&mut Ngo,name:String,description:String,_ctx:&mut TxContext){

    //check if its the owner perfroming the action
    assert!(owner.ngoid==&ngo.ngoid,ENOTOWNER);
    let activitiesid=ngo.activities.length();
    //create new activity
    let new_activity=Activity{
        id:activitiesid,
        name,
        description
    };

    //add new activity
    ngo.activities.push_back(new_activity);

}

//check the amount donated in ngo

public entry fun check_amount_donated(ngo:&mut Ngo,_ctx:&mut TxContext):u64{

    return ngo.balance.value()
}


//register new users to the ngo

public entry fun user_register(ngo:&mut Ngo,name:String,region:String,_ctx:&mut TxContext){

//create a new  id
  let userid=ngo.members.length();

//check if the username is already taken 
let mut index=0;
while(index < userid){
    let user=&ngo.members[index];

    if(user.name==name){
        abort 0
    };
    index=index+1;
};
    //register new member
    let new_member=Member{
        id:userid,
        name,
        region
    };

    //add new member
    ngo.members.push_back(new_member);

}
//users enquires from the ngo


public entry fun user_enquire(ngo:&mut Ngo,userid:u64,enquire:String,_ctx:&mut TxContext){

     //check if user is registered
    assert!(ngo.members.length()>=userid,USERNOTREGISTERED);

     let enquireid=ngo.enquiries.length();
     //create a new enquire
    let new_enquire=Enquire{
        id:enquireid,
        enquire,
        by:userid
    };

    //add new member
    ngo.enquiries.push_back(new_enquire)

}
//donate to ngo


public entry fun donate(ngo:&mut Ngo,amount:Coin<SUI>,userid:u64,_ctx:&mut TxContext){
    
    //check if amount is greater than zero

    assert!(amount.value()>0,EINVALIDAMOUNT);

    let donation_amount = amount.value();
     
    // Convert the Coin<SUI> to a Balance<SUI>
    let coin_balance = coin::into_balance(amount);

    balance::join(&mut ngo.balance, coin_balance);
     //  balance::join(&mut ngo.balance, coin::into_balance(amount));

     //create history

     let new_history=History { 
        
        by:userid, 
        amountdonated:donation_amount
     };

     ngo.donationhistory.push_back(new_history)

    
}
//transfer  funds from ngo

 public entry fun transfer_funds(
        owner: &AdminCap,
        ngo:&mut Ngo,
        amount:u64,
        recipient:address,
         ctx: &mut TxContext,
    ) {

        //verify amount
      assert!(amount > 0 && amount <= ngo.balance.value(), EINVALIDAMOUNT);

    
    //check if its the owner perfroming the action
    assert!(owner.ngoid==&ngo.ngoid,ENOTOWNER);

        let _balance=&ngo.balance.value();
        
        let remaining = take(&mut ngo.balance, amount, ctx);  // Withdraw amount
        transfer::public_transfer(remaining, recipient);  // Transfer withdrawn funds
       

       //create transaction history

       let new_history=Transaction{
            amount,
            recipient
       };

       ngo.transactionhistory.push_back(new_history);

        event::emit(Withdrawal {  // Emit FundWithdrawal event
            amount,
            recipient,
        });
    }


    //get information about a transaction

    public entry fun get_transaction_history(ngo:&mut Ngo,transactionid:u64,_ctx:&mut TxContext):(u64,address){

         //check if transaction is avaialble

         assert!(transactionid>=ngo.transactionhistory.length(),ENOTAVAILABLE);


         return (ngo.transactionhistory[transactionid].amount,ngo.transactionhistory[transactionid].recipient)

    }

}


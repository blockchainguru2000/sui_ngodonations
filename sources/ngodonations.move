
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
    //define the structs for the ngo
    public struct Ngo has key,store{

        id:UID,
        ngoid:ID,
        name:String,
        description:String,
        operationRegion:String,
        activities:vector<Activity>,
        members:vector<Member>,
        enquiries:vector<Enquire>,
        balance:Balance<SUI>,
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

public entry fun create_ngo(name:String,description:String,operationRegion:String,ctx:&mut TxContext){


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
        members:vector::empty(),
        enquiries:vector::empty(),
        balance:zero<SUI>()
};
//add admin capabilities

 transfer::transfer(AdminCap {
        id:object::new(ctx),
        ngoid,
    }, tx_context::sender(ctx));

transfer::share_object(new_ngo);
}
//add activities to ngo

public entry fun add_activities(owner:&AdminCap,ngo:&mut Ngo,name:String,description:String,ctx:&mut TxContext){

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
//register users

public entry fun user_register(ngo:&mut Ngo,name:String,region:String,ctx:&mut TxContext){

//get id
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


public entry fun user_enquire(ngo:&mut Ngo,userid:u64,enquire:String,ctx:&mut TxContext){

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


public entry fun donate(ngo:&mut Ngo,amount:Coin<SUI>,ctx:&mut TxContext){
    
    //check if amount is greater than zero

    assert!(amount.value()>0,EINVALIDAMOUNT);

    //let donation_amount = amount.value();
     
    // Convert the Coin<SUI> to a Balance<SUI>
    let coin_balance = coin::into_balance(amount);

    balance::join(&mut ngo.balance, coin_balance);
     //  balance::join(&mut ngo.balance, coin::into_balance(amount));
}
//widthdraw from ngo

 public entry fun withdraw_funds(
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
       
        event::emit(Withdrawal {  // Emit FundWithdrawal event
            amount,
            recipient,
        });
    }

}


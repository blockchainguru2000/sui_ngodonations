module ngodonations::ngodonations {
    use std::string::{String};
    use sui::coin::{Self, Coin, take};

    use sui::balance::{Self, Balance, zero};
    use sui::sui::SUI;
    use sui::event;

     //define errors
     const ENOTAVAILABLE:u64=0;
     const ENOTOWNER:u64=1;
     const EINVALIDAMOUNT:u64=2;

    //define ngo type
    public struct Ngo has key, store {
        id:UID,
        num: u64,
        name: String,
        description: String,
        operationRegion: String,
        activities: vector<Activity>,
        members: vector<Member>,
        enquiries: vector<Enquire>,
        balance: Balance<SUI>
    }

    //admin cap
    public struct AdminCap has key {
        id: UID,
        ngoid: ID
    }
    //define type activity
    public struct Activity has store {
        name: String,
        description: String
    }
    //define type member
    public struct Member has store {
        name: String,
        region: String
    }

    //define the enquire type
    public struct Enquire has store {
        enquire: String
    }

    //define events
    public struct UmbrellaCraeated has drop,copy {
        name: String
    }

    public struct Withdrawal has copy,drop {
        recipient: address,
        amount: u64
    }
    //CRETE NGO
    public entry fun create_ngo(name:String, description:String ,operationRegion:String, ctx:&mut TxContext) {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
 
        //create a new ngo
        let new_ngo=Ngo{
                id,
                num: 0,
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
            id: object::new(ctx),
            ngoid: inner,
        }, tx_context::sender(ctx));

        transfer::share_object(new_ngo);

    }

    //add activities to ngo
    public entry fun add_activities(self: &mut Ngo, owner:&AdminCap, ngoid:u64, name:String, description:String, ctx:&mut TxContext) {
        assert!(owner.ngoid == object::id(self), ENOTOWNER);
        //add new activity
        let new_activity=Activity{
            name,
            description
        };
        self.activities.push_back(new_activity);
    }

    //register users
    public entry fun user_register(self: &mut Ngo, name: String, region: String, ctx: &mut TxContext) {
        //check aveilablity of ngo
        // assert!(umbrella.ngos.length()>=ngoid,ENOTAVAILABLE);
        
        //register new member
        let new_member=Member{
            name,
            region
        };
        //add new member
        self.members.push_back(new_member);
    }

    //users enquires from the ngo
    public entry fun user_enquire(self: &mut Ngo, ngoid: u64, enquire: String, ctx: &mut TxContext){
        // check aveilablity of ngo
        // assert!(umbrella.ngos.length()>=ngoid,ENOTAVAILABLE);

         //create a new enquire
        let new_enquire=Enquire{
            enquire
        };
        //add new member
        self.enquiries.push_back(new_enquire);

    }

    //donate to ngo
    public entry fun donate(umbrella:&mut NgoUmbrella, ngoid:u64, amount:Coin<SUI>, by:String, ctx:&mut TxContext) {
        //check aveilablity of ngo
        assert!(umbrella.ngos.length()>=ngoid,ENOTAVAILABLE);
        //check if amount is greater than zero
        assert!(amount.value()>0,EINVALIDAMOUNT);
        //let donation_amount = amount.value();
        let ngo = &mut umbrella.ngos[ngoid];
        // Convert the Coin<SUI> to a Balance<SUI>
        let coin_balance = coin::into_balance(amount);
        balance::join(&mut ngo.balance, coin_balance);
        // balance::join(&mut ngo.balance, coin::into_balance(amount));
    }

    //widthdraw from ngo
    public entry fun withdraw_funds(
        owner: &AdminCap,
        umbrella: &mut NgoUmbrella,
        amount: u64,
        ngoid: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        //verify amount
        assert!(amount > 0 && amount <= umbrella.ngos[ngoid].balance.value(), EINVALIDAMOUNT);
           //check aveilablity of ngo
        assert!(umbrella.ngos.length()>=ngoid,ENOTAVAILABLE);
        //check if its the owner perfroming the action
        assert!(owner.ngoid==&umbrella.ngos[ngoid].ngoid,ENOTOWNER);
        let _balance=&umbrella.ngos[ngoid].balance.value();
        let remaining = take(&mut umbrella.ngos[ngoid].balance, amount, ctx);  // Withdraw amount
        transfer::public_transfer(remaining, recipient);  // Transfer withdrawn funds
        event::emit(Withdrawal {  // Emit FundWithdrawal event
            amount,
            recipient,
        });
    }

}


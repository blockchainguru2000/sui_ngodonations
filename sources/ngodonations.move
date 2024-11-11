module ngodonations::ngodonations {
    use std::string::{String};
    use sui::coin::{Self, Coin};

    use sui::balance::{Self, Balance, zero};
    use sui::sui::SUI;


     //define errors
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
    public entry fun create_ngo(name:String, description: String , operationRegion:String, ctx: &mut TxContext) {
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
    public fun add_activities(owner:&AdminCap, self: &mut Ngo, name:String, description:String) {
        assert!(owner.ngoid == object::id(self), ENOTOWNER);
        //add new activity
        let new_activity=Activity{
            name,
            description
        };
        self.activities.push_back(new_activity);
    }

    //register users
    public fun user_register(self: &mut Ngo, name: String, region: String) {
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
    public entry fun user_enquire(self: &mut Ngo, enquire: String){
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
    public fun donate(self: &mut Ngo, coin:Coin<SUI>) {
        //check if amount is greater than zero
        assert!(coin.value()  >0, EINVALIDAMOUNT);
        coin::put(&mut self.balance, coin)
    }

    //widthdraw from ngo
    public fun withdraw_funds(
        owner: &AdminCap,
        self: &mut Ngo,
        ctx: &mut TxContext
    ) : Coin<SUI> {
        assert!(owner.ngoid == object::id(self), ENOTOWNER);
        let balance = balance::withdraw_all(&mut self.balance);
        let coin = balance.into_coin(ctx);
        coin
    }

}


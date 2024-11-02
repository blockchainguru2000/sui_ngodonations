/// Module: ngodonations
module ngodonations::ngodonations {
    use std::string::{String};
    use sui::coin::{Coin, split, put, take};
    use sui::balance::{Balance, zero};
    use sui::sui::SUI;
    use sui::event;
    
    // Define custom errors for better clarity
    pub enum NgodonationsError {
        NotAvailable,
        NotOwner,
        InvalidAmount,
        NameAlreadyTaken,
    }

    // Define the structs for the NGO umbrella
    public struct NgoUmbrella has key, store {
        id: UID,
        name: String,
        ngos: vector<Ngo>,
        ngoscount: u64,
    }

    // Define NGO type
    public struct Ngo has store {
        id: u64,
        ngoid: ID,
        name: String,
        description: String,
        operationRegion: String,
        activities: vector<Activity>,
        members: vector<Member>,
        enquiries: vector<Enquire>,
        balance: Balance<SUI>,
    }

    // Admin capabilities
    public struct AdminCap has key {
        id: UID,
        ngoid: ID,
    }

    // Define activity type
    public struct Activity has store {
        id: u64,
        name: String,
        description: String,
    }

    // Define member type
    public struct Member has store {
        id: u64,
        name: String,
        region: String,
    }

    // Define enquiry type
    public struct Enquire has store {
        id: u64,
        enquire: String,
    }

    // Define events
    public struct UmbrellaCreated has drop, copy {
        name: String,
    }

    public struct Withdrawal has copy, drop {
        recipient: address,
        amount: u64,
    }

    // Create NGO umbrella
    public entry fun create_ngo_umbrella(name: String, ctx: &mut TxContext) {
        let id = object::new(ctx);

        let new_umbrella = NgoUmbrella {
            id,
            name,
            ngos: vector::empty(),
            ngoscount: 0,
        };

        // Emit event after creation
        event::emit(UmbrellaCreated {
            name: name.clone(),
        });

        transfer::share_object(new_umbrella);
    }

    // Create NGO
    public entry fun create_ngo(umbrella: &mut NgoUmbrella, name: String, description: String, operationRegion: String, ctx: &mut TxContext) {
        // Check if the name of the NGO is already taken
        let existing_names: HashSet<String> = umbrella.ngos.iter().map(|ngo| ngo.name.clone()).collect();
        assert!(!existing_names.contains(&name), NgodonationsError::NameAlreadyTaken);

        // Create a new NGO
        let new_ngo = Ngo {
            id: umbrella.ngoscount, // Use ngoscount for ID
            ngoid: object::uid_to_inner(&object::new(ctx)),
            name,
            description,
            operationRegion,
            activities: vector::empty(),
            members: vector::empty(),
            enquiries: vector::empty(),
            balance: zero<SUI>(),
        };

        // Add admin capabilities
        transfer::transfer(AdminCap {
            id: object::new(ctx),
            ngoid: new_ngo.ngoid,
        }, tx_context::sender(ctx));

        // Add NGO to the list of NGOs in the umbrella
        umbrella.ngos.push_back(new_ngo);
        umbrella.ngoscount += 1; // Increment the count
    }

    // Add activities to NGO
    public entry fun add_activities(owner: &AdminCap, umbrella: &mut NgoUmbrella, ngoid: u64, name: String, description: String, ctx: &mut TxContext) {
        // Check availability of NGO
        assert!(umbrella.ngos.length() > ngoid, NgodonationsError::NotAvailable);
        // Check if it's the owner performing the action
        assert!(owner.ngoid == &umbrella.ngos[ngoid].ngoid, NgodonationsError::NotOwner);

        // Create new activity
        let new_activity = Activity {
            id: umbrella.ngos[ngoid].activities.length(),
            name,
            description,
        };

        // Add new activity
        umbrella.ngos[ngoid].activities.push_back(new_activity);
    }

    // Register users
    public entry fun user_register(umbrella: &mut NgoUmbrella, ngoid: u64, name: String, region: String, ctx: &mut TxContext) {
        // Check availability of NGO
        assert!(umbrella.ngos.length() > ngoid, NgodonationsError::NotAvailable);

        // Register new member
        let new_member = Member {
            id: umbrella.ngos[ngoid].members.length(),
            name,
            region,
        };

        // Add new member
        umbrella.ngos[ngoid].members.push_back(new_member);
    }

    // Users enquire from the NGO
    public entry fun user_enquire(umbrella: &mut NgoUmbrella, ngoid: u64, enquire: String, ctx: &mut TxContext) {
        // Check availability of NGO
        assert!(umbrella.ngos.length() > ngoid, NgodonationsError::NotAvailable);

        // Create a new enquiry
        let new_enquire = Enquire {
            id: umbrella.ngos[ngoid].enquiries.length(),
            enquire,
        };

        // Add new enquiry
        umbrella.ngos[ngoid].enquiries.push_back(new_enquire);
    }

    // Donate to NGO
    public entry fun donate(umbrella: &mut NgoUmbrella, ngoid: u64, amount: &mut Coin<SUI>, by: String, ctx: &mut TxContext) {
        // Check availability of NGO
        assert!(umbrella.ngos.length() > ngoid, NgodonationsError::NotAvailable);
        // Check if amount is greater than zero
        assert!(amount.value() > 0, NgodonationsError::InvalidAmount);

        // Add the donation to the NGO's balance
        let donation_amount = amount.value();
        let ngo = &mut umbrella.ngos[ngoid];
        ngo.balance.deposit(donation_amount);

        // Optionally, emit an event for donation received
        // event::emit(DonationReceived { ngoid, amount: donation_amount, by });
    }

    // Withdraw from NGO
    public entry fun withdraw_funds(owner: &AdminCap, umbrella: &mut NgoUmbrella, amount: u64, ngoid: u64, recipient: address, ctx: &mut TxContext) {
        // Verify amount
        assert!(amount > 0 && amount <= umbrella.ngos[ngoid].balance.value(), NgodonationsError::InvalidAmount);
        // Check availability of NGO
        assert!(umbrella.ngos.length() > ngoid, NgodonationsError::NotAvailable);
        // Check if it's the owner performing the action
        assert!(owner.ngoid == &umbrella.ngos[ngoid].ngoid, NgodonationsError::NotOwner);

        // Withdraw amount
        let remaining = take(&mut umbrella.ngos[ngoid].balance, amount, ctx);  
        transfer::public_transfer(remaining, recipient);  // Transfer withdrawn funds

        event::emit(Withdrawal {  // Emit FundWithdrawal event
            amount,
            recipient,
        });
    }
}

/// Module: ngodonations
module ngodonations::ngodonations {
    use std::string::{String};
    use sui::coin::{Coin, take};
    use sui::balance::{Balance, zero};
    use sui::sui::SUI;
    use sui::event;
    use sui::tx_context::TxContext;
    use sui::object;

    // Define errors with descriptive messages for better debugging
    const ENGO_NOT_AVAILABLE: u64 = 0; // "NGO not found in the umbrella"
    const INVALID_OWNER: u64 = 1;      // "Only the authorized owner can perform this action"
    const INVALID_AMOUNT: u64 = 2;     // "Donation or withdrawal amount must be greater than zero"

    // Struct for NgoUmbrella with key and store
    public struct NgoUmbrella has key, store {
        id: UID,
        name: String,
        ngos: vector<Ngo>,
        ngos_count: u64,
    }

    // Struct for Ngo with store
    public struct Ngo has store {
        id: u64,
        ngoid: ID,
        name: String,
        description: String,
        operation_region: String,
        activities: vector<Activity>,
        members: vector<Member>,
        enquiries: vector<Enquire>,
        balance: Balance<SUI>,
    }

    // Admin capability struct for managing specific NGOs
    public struct AdminCap has key {
        id: UID,
        ngoid: ID,
    }

    // Struct for Activity
    public struct Activity has store {
        id: u64,
        name: String,
        description: String,
    }

    // Struct for Member
    public struct Member has store {
        id: u64,
        name: String,
        region: String,
    }

    // Struct for Enquire
    public struct Enquire has store {
        id: u64,
        enquiry: String,
    }

    // Struct for UmbrellaCreated event
    public struct UmbrellaCreated has drop, copy {
        name: String,
    }

    // Struct for Withdrawal event
    public struct Withdrawal has copy, drop {
        recipient: address,
        amount: u64,
    }

    // Helper function to check NGO existence by name
    fun is_name_taken(umbrella: &NgoUmbrella, name: &String): bool {
        for ngo in &umbrella.ngos {
            if ngo.name == *name {
                return true;
            }
        }
        false
    }

    // Helper function to verify if caller is the owner of an NGO
    fun check_owner(admin: &AdminCap, ngoid: ID) {
        assert!(admin.ngoid == ngoid, INVALID_OWNER);
    }

    // Create NgoUmbrella
    public entry fun create_ngo_umbrella(name: String, ctx: &mut TxContext): NgoUmbrella {
        let id = object::new(ctx);
        let new_umbrella = NgoUmbrella {
            id,
            name,
            ngos: vector::empty(),
            ngos_count: 0,
        };
        event::emit(UmbrellaCreated { name });
        transfer::share_object(new_umbrella);
        new_umbrella // Return for further processing if needed
    }

    // Create a new NGO within an umbrella
    public entry fun create_ngo(
        umbrella: &mut NgoUmbrella,
        name: String,
        description: String,
        operation_region: String,
        ctx: &mut TxContext
    ): Ngo {
        assert!(!is_name_taken(umbrella, &name), ENGO_NOT_AVAILABLE);

        let ngo_uid = object::new(ctx);
        let ngoid = object::uid_to_inner(&ngo_uid);
        let new_ngo = Ngo {
            id: umbrella.ngos_count,
            ngoid,
            name,
            description,
            operation_region,
            activities: vector::empty(),
            members: vector::empty(),
            enquiries: vector::empty(),
            balance: zero<SUI>(),
        };
        umbrella.ngos.push_back(new_ngo.clone());
        umbrella.ngos_count += 1;
        transfer::transfer(AdminCap { id: ngo_uid, ngoid }, tx_context::sender(ctx));
        new_ngo
    }

    // Add activities to an NGO
    public entry fun add_activity(
        owner: &AdminCap,
        umbrella: &mut NgoUmbrella,
        ngoid: u64,
        name: String,
        description: String
    ) {
        assert!(ngoid < umbrella.ngos.length(), ENGO_NOT_AVAILABLE);
        check_owner(owner, umbrella.ngos[ngoid].ngoid);

        let new_activity = Activity {
            id: umbrella.ngos[ngoid].activities.length(),
            name,
            description,
        };
        umbrella.ngos[ngoid].activities.push_back(new_activity);
    }

    // Register a new member to an NGO
    public entry fun register_member(
        umbrella: &mut NgoUmbrella,
        ngoid: u64,
        name: String,
        region: String
    ) {
        assert!(ngoid < umbrella.ngos.length(), ENGO_NOT_AVAILABLE);

        let new_member = Member {
            id: umbrella.ngos[ngoid].members.length(),
            name,
            region,
        };
        umbrella.ngos[ngoid].members.push_back(new_member);
    }

    // Add an enquiry to an NGO
    public entry fun add_enquiry(
        umbrella: &mut NgoUmbrella,
        ngoid: u64,
        enquiry: String
    ) {
        assert!(ngoid < umbrella.ngos.length(), ENGO_NOT_AVAILABLE);

        let new_enquiry = Enquire {
            id: umbrella.ngos[ngoid].enquiries.length(),
            enquiry,
        };
        umbrella.ngos[ngoid].enquiries.push_back(new_enquiry);
    }

    // Donate to an NGO
    public entry fun donate(
        umbrella: &mut NgoUmbrella,
        ngoid: u64,
        amount: &mut Coin<SUI>,
        donor: String
    ) {
        assert!(ngoid < umbrella.ngos.length(), ENGO_NOT_AVAILABLE);
        assert!(amount.value() > 0, INVALID_AMOUNT);

        umbrella.ngos[ngoid].balance.deposit(take(amount.value(), &mut TxContext));
    }

    // Withdraw funds from an NGO
    public entry fun withdraw_funds(
        owner: &AdminCap,
        umbrella: &mut NgoUmbrella,
        amount: u64,
        ngoid: u64,
        recipient: address
    ) {
        assert!(amount > 0, INVALID_AMOUNT);
        assert!(ngoid < umbrella.ngos.length(), ENGO_NOT_AVAILABLE);
        check_owner(owner, umbrella.ngos[ngoid].ngoid);
        assert!(umbrella.ngos[ngoid].balance.value() >= amount, INVALID_AMOUNT);

        let withdrawn_amount = take(amount, &mut umbrella.ngos[ngoid].balance);
        transfer::public_transfer(withdrawn_amount, recipient);

        event::emit(Withdrawal {
            recipient,
            amount,
        });
    }
}

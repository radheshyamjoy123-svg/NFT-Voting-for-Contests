module MyModule::NFTVoting {
    use aptos_framework::signer;
    use std::vector;
    use aptos_framework::table::{Self, Table};

    /// Struct representing an NFT voting contest.
    struct Contest has store, key {
        nft_votes: Table<u64, u64>,  // Maps NFT token_id to vote count
        voters: vector<address>,      // Tracks who has voted to prevent double voting
        winner_nft: u64,             // NFT with the highest votes
        is_active: bool,             // Contest status
    }

    /// Error codes
    const E_CONTEST_NOT_ACTIVE: u64 = 1;
    const E_ALREADY_VOTED: u64 = 2;

    /// Function to create a new NFT voting contest.
    public fun create_contest(owner: &signer) {
        let contest = Contest {
            nft_votes: table::new(),
            voters: vector::empty<address>(),
            winner_nft: 0,
            is_active: true,
        };
        move_to(owner, contest);
    }

    /// Function for users to vote for an NFT by token ID.
    public fun vote_for_nft(
        voter: &signer, 
        contest_owner: address, 
        nft_token_id: u64
    ) acquires Contest {
        let contest = borrow_global_mut<Contest>(contest_owner);
        let voter_addr = signer::address_of(voter);
        
        // Check if contest is active
        assert!(contest.is_active, E_CONTEST_NOT_ACTIVE);
        
        // Check if voter has already voted
        assert!(!vector::contains(&contest.voters, &voter_addr), E_ALREADY_VOTED);
        
        // Add voter to the list
        vector::push_back(&mut contest.voters, voter_addr);
        
        // Increment vote count for the NFT
        if (table::contains(&contest.nft_votes, nft_token_id)) {
            let current_votes = table::borrow_mut(&mut contest.nft_votes, nft_token_id);
            *current_votes = *current_votes + 1;
        } else {
            table::add(&mut contest.nft_votes, nft_token_id, 1);
        };
        
        // Update winner if this NFT now has the most votes
        let new_votes = *table::borrow(&contest.nft_votes, nft_token_id);
        if (contest.winner_nft == 0 || 
            new_votes > *table::borrow(&contest.nft_votes, contest.winner_nft)) {
            contest.winner_nft = nft_token_id;
        };
    }
}
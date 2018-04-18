pragma solidity ^0.4.21;

contract MediaMarket {

    struct StakeHolder {address addr; uint256 share;}

    struct Media {

        // Unique identifier for a media

        uint256 id;

        // Can be a song or a movie name

        string name;

        // Account adding the media

        address creator;

        // Cost of the media, for individuals or companies

        uint256 cost_individual;

        uint256 cost_company;

        mapping(uint256 => StakeHolder) stakeholders;

        uint stakeholder_count;

    }
	
	struct Records {
		uint256 media_id;
		string url;
		//uint256 purchase_count;
	}

    /////////////////////////////////////////////////////////////////////////

    // Store accounts that have bought a media.

    mapping(address => Records[]) public purchases;
	//mapping(address => bool) public purchase_exist;

    // Store all available media

    mapping(uint256 => Media) public media_store;

    uint public media_count;

    // Will be fired when a buyer wants to buy a media

    // Will be captured by the creator who will send back an encrypted URL

    // TODO: Add purchase ID, to uniquely identify a purchase

    event evConsumerWantsToBuy(address buyer, uint256 media_id);

    // Will be fired when a creator has sent an encrypted URL

    // Will be captured by the buery who needs this

    // TODO: Add purchase ID, to uniquely identify a purchase

    event evURLForMedia(address buyer, uint256 media_id, string url);

    /////////////////////////////////////////////////////////////////////////

    // This will be called when someone wants to add a new media

    function add_media (string _name, uint256 _cost_individual, uint256 _cost_company) public {

        media_count++;

        media_store[media_count] = Media(media_count, _name, msg.sender, _cost_individual, _cost_company, 0);

    }

    /////////////////////////////////////////////////////////////////////////

    // This will be called by the creator to add stakeholders of a media

    function add_stakeholder(uint256 _media_id, address _addr, uint256 _share) public {

        // TODO: Require that stakeholders have different addresses?

        // TODO: Require that sum of shares of each StakeHolder should be < 100?

        // Only a media creator should be able to add stakeholders

        require(msg.sender == media_store[_media_id].creator);
		
		// Require that stakeholders have different addresses
		
		bool flag = check_stakeholder(_media_id,_addr);
		require(flag == true);

        // A media may have a maximum of 5 stakeholders

        require(media_store[_media_id].stakeholder_count < 5);

        media_store[_media_id].stakeholder_count++;

        media_store[_media_id].stakeholders[media_store[_media_id].stakeholder_count] = StakeHolder(_addr, _share);

    }

    function get_stakeholder(uint256 _media_id, uint256 _idx) public constant returns (address, uint256) {

        // Require a valid stakeholder

        require(_idx > 0 && _idx <= media_store[_media_id].stakeholder_count);

        StakeHolder memory S = media_store[_media_id].stakeholders[_idx];

        return (S.addr, S.share);
		
    }

    /////////////////////////////////////////////////////////////////////////
	
	function check_stakeholder(uint256 _media_id,address _addr) public returns (bool){
		Media memory M = media_store[_media_id];
		
		for (uint i = 1; i <= M.stakeholder_count; i++) {
			StakeHolder memory S = media_store[_media_id].stakeholders[i];
			if (S.addr == _addr)
				return false;
		}
		return true;
	}
	/////////////////////////////////////////////////////////////////////////
	
	function check_purchased_media(address _buyer, uint256 _media_id) public returns (bool) {
		//uint256 len = purchases[_buyer].length;
		
		for (uint i = 0; i < purchases[_buyer].length; i++) {
			if (purchases[_buyer][i].media_id == _media_id)
				return false;
		}
		return true;
	}
	
	/////////////////////////////////////////////////////////////////////////

    // This will be called when someone wants to buy a media

    function buy_media (uint256 _media_id, uint _customer_type) public payable {

        // TODO: Require that they haven't already bought the same media before
        // require(purchases[msg.sender] != media_store[_media_id]);
		
		bool flag = check_purchased_media(msg.sender, _media_id);
		require(flag == true);
	
        // Require a valid media

        require(_media_id > 0 && _media_id <= media_count);

        Media memory M = media_store[_media_id];

        // Cost depends on the type of user

        uint256 cost = M.cost_company;

        if (_customer_type == 0)
            cost = M.cost_individual;

        // Require that consumer has sufficient balance
        // require(msg.sender.balance >= cost);

        require(msg.value == cost);

        // TODO: Send amounts to stakeholders depending on their shares

        uint256 stakeholders_total = 0;

        for (uint i = 1; i <= M.stakeholder_count; i++) {

            StakeHolder memory S =  media_store[_media_id].stakeholders[i];

            // Share of this stakeholder

            uint256 share_value = (S.share * cost) / 100;

            S.addr.transfer(share_value);

            stakeholders_total += share_value;

        }

        // TODO: Send remaining amount to creator

        M.creator.transfer(cost - stakeholders_total);

        // Record that a buyer has bought a media
		//if(purchase_exist[msg.sender] == False)
			//purchases[msg.sender] = Purchase_records(0);
		//purchases[msg.sender].purchase_count++;
		//purchases[msg.sender].list[purchases[msg.sender].purchase_count] = M;
		//purchases[msg.sender].urls[purchases[msg.sender].purchase_count] = "";
		purchases[msg.sender].push(Records(_media_id,""));

        emit evConsumerWantsToBuy(msg.sender, _media_id);

    }
	
	
	
    /////////////////////////////////////////////////////////////////////////

    // This will be called when a creator wants to send an encrypted URL back to buyer

    function url_for_media (address _buyer, uint256 _media_id, string _url) public {

        // Require a valid media

        require(_media_id > 0 && _media_id <= media_count);

        // TODO: require that this call is in response to an appropriate evConsumerWantsToBuy event!?
        // So that not anyone can call this anytime
        // require that this is only called by the creator of the media

        Media memory media = media_store[_media_id];

        require(msg.sender == media.creator);

        // TODO: Save URL into a mapping so buyer can access it later
		uint256 len = purchases[_buyer].length;
		purchases[_buyer][len-1].url= _url;

        emit evURLForMedia(_buyer, _media_id, _url);

    }
}

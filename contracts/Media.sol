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

    /////////////////////////////////////////////////////////////////////////

    // Store accounts that have bought a media.
    // TODO: Allow people to buy more than one media
    mapping(address => Media[]) public purchases;

    // Store all available media
    mapping(uint256 => Media) public media_store;
    uint public media_count;

    // Will be fired when a buyer wants to buy a media
    // Will be captured by the creator who will send back an encrypted URL
    // TODO: Need to send the media, instead of media id?
    // TODO: Add purchase ID, to uniquely identify a purchase
    event evConsumerWantsToBuy(address buyer, uint256 media_id);

    // Will be fired when a creator has sent an encrypted URL
    // Will be captured by the buery who needs this
    // TODO: Add purchase ID, to uniquely identify a purchase
    event evURLForMedia(address buyer, uint256 media_id, string url);

    /////////////////////////////////////////////////////////////////////////

    // Constructor
    function MediaMarket () public {
        add_media("If I lose myself", 10000000000, 20000000000);
    }

    /////////////////////////////////////////////////////////////////////////

    // This will be called when someone wants to add a new media
    function add_media (string _name, uint256 _cost_individual, uint256 _cost_company) public {
        media_count++;
        media_store[media_count] = Media(media_count, _name, msg.sender, _cost_individual, _cost_company, 0);
    }

    // TODO: Function to get all media?

    /////////////////////////////////////////////////////////////////////////

    // This will be called by the creator to add stakeholders of a media
    function add_stakeholder(uint256 _media_id, address _addr, uint256 _share) public {

        // TODO: Require that stakeholders have different addresses?
        // TODO: Require that sum of shares of each StakeHolder should be < 100?

        // Only a media creator should be able to add stakeholders
        require(msg.sender == media_store[_media_id].creator);

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

    // This will be called when someone wants to buy a media
    // TODO: Receive public key of consumer
    function buy_media (uint256 _media_id, uint _customer_type) public payable {

        // Require that they haven't already bought the same media before
        // FIXME: Results in some struct error
        // require(purchases[msg.sender] != media_store[_media_id]);

        // Require a valid media
        require(_media_id > 0 && _media_id <= media_count);

        // Check and Deduct cost
        uint256 cost = media_store[_media_id].cost_company;
        if (_customer_type == 0)
            cost = media_store[_media_id].cost_individual;

        uint256 balance = msg.sender.balance;

        // Require that consumer has sufficient balance
        require(balance >= cost);

        // uint256 total = 0;
        // for (uint i = 0; i < media_store[_media_id].stake_holders.length; i++)
        //     uint256 share_value = (media_store[_media_id].shares[i]*cost) / 100;
        //     media_store[_media_id].stake_holders[i].transfer(share_value);
        //     total += share_value;

        // uint256 remainder = cost - total;
        // media_store[_media_id].creator.transfer(remainder);

        // Record that a buyer has bought a media
        purchases[msg.sender].push(media_store[_media_id]);

        // TODO: Deduct amount from buyer's account

        // TODO: Send amount to creator?
        // TODO: OR Send amounts to stakeholders?

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

        emit evURLForMedia(_buyer, _media_id, _url);
    }

}

pragma solidity ^0.4.21;

contract MediaMarket {

    // NOTE: Sum of shares of each StakeHolder should sum to 1?
    //struct StakeHolder {address addr; uint256 share;}

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

        address[] stake_holders;
        uint256[] shares;

        uint256 stakeholder_count;
    }

    /////////////////////////////////////////////////////////////////////////

    // Store the type of a buyer - decided once randomly!
    // enum AccountType { Individual, Company }
    // mapping(address => AccountType) public buyer_type;

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

        // TODO: Make StakeHolders work
        // StakeHolder[2] memory stake_holders = [
        //     StakeHolder(msg.sender, 1.1),
        //     StakeHolder(msg.sender, 2.1)
        // ];

        add_media("If I lose myself", 1000000000000, 2000000000000);
        //add_stakeholders(1,0x34084959fa381774ea862266ae752253b91916dd, 10);
        //add_stakeholders(1,0xc797dbe6389698cfb840693e62467380a5d436a6, 20);
    }

    /////////////////////////////////////////////////////////////////////////

    // This will be called when someone wants to add a new media
    function add_media (
        string _name,
        uint256 _cost_individual,
        uint256 _cost_company)
    public {

        address[] storage saddr;
        uint256[] storage share;

        media_count++;

        media_store[media_count] = Media(
            media_count,
            _name,
            msg.sender,
            _cost_individual,
            _cost_company,
            //new address[](5),
            //new uint256[](5),
            saddr,
            share,
        0
        );

    }

    /////////////////////////////////////////////////////////////////////////

    //This will add stakeholders of a media

    function add_stakeholders( uint256 _media_id, address addr, uint256 share) public {
        require(msg.sender == media_store[_media_id].creator);

        media_store[_media_id].stakeholder_count++;
        media_store[_media_id].stake_holders.push(addr);
        media_store[_media_id].shares.push(share);
        //media_store[_media_id].stake_holders[media_store[_media_id].stakeholder_count] = addr;
        //media_store[_media_id].shares[media_store[_media_id].stakeholder_count] = share;
    }

    /////////////////////////////////////////////////////////////////////////

    // This will be called when someone wants to buy a media
    // TODO: Receive type of consumer - Individual / Company
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

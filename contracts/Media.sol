pragma solidity ^0.4.2;

contract MediaMarket {

    // NOTE: Sum of shares of each StakeHolder should sum to 1?
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

        // StakeHolder[] stake_holders;
    }

    // Store accounts that have bought a media.
    // TODO: Allow people to buy more than one media
    mapping(address => Media) public purchases;

    // Store all available media
    mapping(uint256 => Media) public media_store;
    uint public media_count;

    // Constructor
    function MediaMarket () public {

        // TODO: Make StakeHolders work
        // StakeHolder[2] memory stake_holders = [
        //     StakeHolder(msg.sender, 1.1),
        //     StakeHolder(msg.sender, 2.1)
        // ];

        add_media("If I lose myself", 1500, 2500);
    }

    // This will be called when someone wants to add a new media
    function add_media (
        string _name,
        uint256 _cost_individual,
        uint256 _cost_company)
    public {

        media_count++;
        media_store[media_count] = Media(
            media_count,
            _name,
            msg.sender,
            _cost_individual,
            _cost_company
        );

    }

    // This will be called when someone wants to buy a media
    function buy_media (uint256 _media_id) public payable {

        // Require that they haven't already bought the same media before
        // FIXME: Results in some struct error
        // require(purchases[msg.sender] != media_store[_media_id]);

        // Require a valid media
        require(_media_id > 0 && _media_id <= media_count);

        // Record that a buyer has bought a media
        purchases[msg.sender] = media_store[_media_id];

    }
}

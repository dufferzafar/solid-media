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

        // Stakeholders of this media
        mapping(uint256 => StakeHolder) stakeholders;
        uint stakeholder_count;

    }

    // Store available media
    mapping(uint256 => Media) public media_store;
    uint public media_count;

    // Store accounts that have bought a media.
    struct PurchaseRecord {bool purchased; string url;}
    mapping(address => mapping(uint256 => PurchaseRecord)) public purchases;

    /////////////////////////////////////////////////////////////////////////

    // Will be fired when a buyer wants to buy a media
    // Will be captured by the creator who will send back an encrypted URL
    event evConsumerWantsToBuy(address buyer, uint256 media_id);

    // Will be fired when a creator has sent an encrypted URL
    // Will be captured by the buyer who needs this
    event evURLForMedia(address buyer, uint256 media_id, string url);

    /////////////////////////////////////////////////////////////////////////

    function add_media (string _name, uint256 _cost_individual, uint256 _cost_company) public {
        media_store[++media_count] = Media(media_count, _name, msg.sender, _cost_individual, _cost_company, 0);
    }

    /////////////////////////////////////////////////////////////////////////

    function add_stakeholder(uint256 _media_id, address _addr, uint256 _share) public {

        // Require a valid media
        require(_media_id > 0 && _media_id <= media_count);

        Media storage M = media_store[_media_id];

        // Require that only a media creator is able to add stakeholders
        require(msg.sender == M.creator);

        // Require that stakeholders have different addresses
        require(not_already_stakeholder(_media_id, _addr));

        // We could also require that sum of shares of each StakeHolder should be < 100
        // But since we assume that the creator is honest, these checks aren't neccessary?

        // A media may have a maximum of 5 stakeholders
        require(M.stakeholder_count < 5);

        // Add the stakeholder
        M.stakeholders[++M.stakeholder_count] = StakeHolder(_addr, _share);
    }

    function get_stakeholder(uint256 _media_id, uint256 _idx) public view returns (address, uint256) {

        // Require a valid media
        require(_media_id > 0 && _media_id <= media_count);

        // Require a valid stakeholder
        require(_idx > 0 && _idx <= media_store[_media_id].stakeholder_count);

        StakeHolder memory S = media_store[_media_id].stakeholders[_idx];

        return (S.addr, S.share);
    }

    function not_already_stakeholder(uint256 _media_id, address _addr) private view returns (bool) {
        Media memory M = media_store[_media_id];

        for (uint i = 1; i <= M.stakeholder_count; i++) {
            StakeHolder memory S = media_store[_media_id].stakeholders[i];
            if (S.addr == _addr)
                return false;
        }

        return true;
    }

    /////////////////////////////////////////////////////////////////////////

    function buy_media (uint256 _media_id, uint _customer_type) public payable {

        // Require a valid media
        require(_media_id > 0 && _media_id <= media_count);

        // Require that they haven't already bought the same media before
        require(purchases[msg.sender][_media_id].purchased == false);

        Media memory M = media_store[_media_id];

        // Cost depends on the type of user
        uint256 cost = M.cost_company;
        if (_customer_type == 0)
            cost = M.cost_individual;

        // Require that consumer has sent the cost
        require(msg.value == cost);

        // Send amounts to stakeholders depending on their shares
        uint256 stakeholders_total = 0;

        for (uint i = 1; i <= M.stakeholder_count; i++) {

            StakeHolder memory S = media_store[_media_id].stakeholders[i];

            // Share of this stakeholder
            uint256 share_value = (S.share * cost) / 100;
            S.addr.transfer(share_value);

            stakeholders_total += share_value;
        }

        // Send remaining amount to creator
        M.creator.transfer(cost - stakeholders_total);

        // Record that a buyer has bought a media
        purchases[msg.sender][_media_id] = PurchaseRecord(true, "");

        emit evConsumerWantsToBuy(msg.sender, _media_id);
    }

    /////////////////////////////////////////////////////////////////////////

    function url_for_media (address _buyer, uint256 _media_id, string _url) public {

        // Require a valid media
        require(_media_id > 0 && _media_id <= media_count);

        Media memory media = media_store[_media_id];

        // We could require that this call is in response to an appropriate
        // evConsumerWantsToBuy event so that not anyone can call this anytime !?

        // Currently, this function can be called by the creator at some later time
        // in case they want to update the URLs of users
        // (say when the storage server moves etc.)

        // require that this is only called by the creator of the media
        require(msg.sender == media.creator);

        // Save URL into a mapping so buyer can access it later
        purchases[_buyer][_media_id].url = _url;

        emit evURLForMedia(_buyer, _media_id, _url);
    }
}

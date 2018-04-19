const EthEnc = require("ethereum-encryption");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);
global.assert = chai.assert;

const MediaMarket = artifacts.require("./MediaMarket.sol");

// Ethereum Units
const finney = Math.pow(10, 15);
const ether = Math.pow(10, 18);

// Type of consumer
const INDIVIDUAL = 0;
const COMPANY = 1;

// These tests are not really unit tests, since a lot of them
// depend on other tests to run (which modify state)

contract("MediaMarket", function(accounts) {
    let market; // Will store an instance of our contract

    beforeEach("setup contract for each test", async function() {
        market = await MediaMarket.deployed();
    });

    it("initializes with no media files", async function() {
        assert.equal(await market.media_count(), 0);
    });

    it("allows adding media entries", async function() {
        await market.add_media(
            "If I lose myself", 1000 * finney, 2000 * finney, {from: accounts[3]}
        );

        await market.add_media(
            "Avengers: Infinity War", 2000 * finney, 4000 * finney, {from: accounts[4]}
        );

        await market.add_media(
            "Harry Potter & The Cursed Child", 1 * ether, 1.5 * ether, {from: accounts[5]}
        );

        assert.equal(await market.media_count(), 3);
    });

    it("allows listing available media", async function() {
        let media_count = await market.media_count();

        let observed_list = [];
        for (let i = 1; i <= media_count; i++) {
            let media = await market.media_store(i);
            observed_list.push(media[1]);
        }

        let expected_list = [
            "If I lose myself",
            "Avengers: Infinity War",
            "Harry Potter & The Cursed Child",
        ];

        assert.deepEqual(observed_list, expected_list);
    });

    // /////////////////////////////////////////////////////////////////////////
    //                               Stakeholders
    // /////////////////////////////////////////////////////////////////////////

    it("initializes with 0 stakeholders", async function() {
        let media_id = 1;
        let media = await market.media_store(media_id);
        assert.equal(media[5], 0);
    });

    it("fails when someone else tries to add a stakeholder", async function() {
        try { // The creator of Media 1 is accounts[3]
            await market.add_stakeholder(1, accounts[4], 5);
        } catch (e) {
            assert(e.message.endsWith("revert"));
        }
    });

    it("allows adding stakeholders dynamically", async function() {
        let media_id = 2;

        // Add 2 stakeholders
        await market.add_stakeholder(
            media_id, accounts[5], 25, {from: accounts[4]}
        );

        await market.add_stakeholder(
            media_id, accounts[6], 15, {from: accounts[4]}
        );

        // Ensure proper count
        let media = await market.media_store(media_id);
        assert.equal(media[5], 2, "has 2 stakeholders");
    });

    it("fails when adding same stakeholder twice", async function() {
        let media_id = 2;

        // accounts[5] has already been added as a stakeholder above
        // Adding it again should fail!
        assert.isRejected(market.add_stakeholder(media_id, accounts[5], 5, {from: accounts[4]}));

        let media = await market.media_store(media_id);
        assert.equal(media[5], 2, "still has 2 stakeholders");
    });

    it("allows upto 5 stakeholders", async function() {
        let media_id = 2;

        // Add three more stakeholders
        await market.add_stakeholder(
            media_id, accounts[7], 5, {from: accounts[4]}
        );
        await market.add_stakeholder(
            media_id, accounts[8], 5, {from: accounts[4]}
        );
        await market.add_stakeholder(
            media_id, accounts[9], 5, {from: accounts[4]}
        );

        let media = await market.media_store(media_id);
        assert.equal(media[5], 5, "has 5 stakeholders");
    });

    it("fails when adding more than 5 stakeholders", async function() {
        let media_id = 2;

        // Try adding 1 more stakeholder; should fail!
        assert.isRejected(market.add_stakeholder(media_id, accounts[4], 5, {from: accounts[4]}));

        let media = await market.media_store(media_id);
        assert.equal(media[5], 5, "still has 5 stakeholders");
    });

    // /////////////////////////////////////////////////////////////////////////
    //                             Buying Media
    // /////////////////////////////////////////////////////////////////////////

    it("allows buying a media", async function() {
        let media_id = 2;
        let buyer = accounts[0];

        // Find proper costs of the media
        let media = await market.media_store(media_id);
        let media_cost = media[3];

        // It wasn't already bought
        let purchased_record = await market.purchases(buyer, media_id);
        assert(purchased_record[0] == false);

        // Buy it
        await market.buy_media(media_id, INDIVIDUAL, {from: buyer, value: media_cost});

        // Has been bought now
        purchased_record = await market.purchases(buyer, media_id);
        assert(purchased_record[0] == true);
    });

    it("fails when buying a media again", async function() {
        let media_id = 2;
        let buyer = accounts[0];

        // Find proper costs of the media
        let media = await market.media_store(media_id);
        let media_cost = media[3];

        // Media 2 was bought by accounts[0] above
        // Buying it again should fail!
        assert.isRejected(market.buy_media(media_id, INDIVIDUAL, {from: buyer, value: media_cost}));
    });

    it("allows buying as a company", async function() {
        let media_id = 2;
        let buyer = accounts[1];

        // Find proper costs of the media
        let media = await market.media_store(media_id);
        let media_cost = media[4]; // For company

        // Buy it
        await market.buy_media(media_id, COMPANY, {from: buyer, value: media_cost});
        purchased_record = await market.purchases(buyer, media_id);
        assert(purchased_record[0] == true);
    });

    it("fails when paying anything except the right cost", async function() {
        let media_id = 1;
        let buyer = accounts[1];

        assert.isRejected(
            market.buy_media(media_id, INDIVIDUAL, {from: buyer, value: 0}),
            /revert/, "can't buy for free"
        );

        // Find proper cost of the media
        let media = await market.media_store(media_id);
        let media_cost = media[3];

        assert.isRejected(
            market.buy_media(media_id, INDIVIDUAL, {from: buyer, value: media_cost + 1}),
            /revert/, "can't pay more"
        );

        assert.isRejected(
            market.buy_media(media_id, INDIVIDUAL, {from: buyer, value: media_cost + 1}),
            /revert/, "can't pay less"
        );
    });

    it("triggers an event when buying", async function() {
        let buyer = accounts[1];

        // Start watching for the Buy event to pop up
        let event = market.evConsumerWantsToBuy({}, {});
        event.watch(function(error, ev) {
            if (!error && (ev.args.buyer == buyer)) {
                assert.equal(ev.args.media_id, 1);
                event.stopWatching();
            }
        });

        // Initiate a purchase
        await market.buy_media(1, INDIVIDUAL, {from: buyer, value: 1000 * finney});
    });

    it("pays the creator when buying", async function() {
        // Details of the media being bought
        let media_id = 1;
        let media = await market.media_store(media_id);
        let media_cost = media[3].toNumber();
        let media_creator = media[2];

        // Find balance of creator, before
        let cbal_before = web3.eth.getBalance(media_creator).toNumber();

        await market.buy_media(
            media_id, INDIVIDUAL, {from: accounts[4], value: media_cost}
        );

        // Find balance of creator, after
        let cbal_after = web3.eth.getBalance(media_creator).toNumber();

        // The entire cost must go to the creator as media 1 has no stakeholders
        assert.equal(cbal_after, cbal_before + media_cost);

        // The same test wouldn't work for buyer since
        // we're executing a transaction from him
        // and will also need to account for the Gas used.
    });

    it("also pays the stakeholders when buying", async function() {
        // Details of the media being bought
        let media_id = 2;
        let media = await market.media_store(media_id);
        let media_cost = media[3].toNumber();
        let media_creator = media[2];
        let stakeholder_count = media[5];

        // Account 5, 6, 7, 8, 9 are the 5 stakeholders of media 2
        // with 25, 15, 5, 5, 5 % stake each.
        // Account 4 is the creator!

        // Get all stakeholders of media 2
        let parties = [];
        let total_stake_share = 0;
        for (let i = 1; i <= stakeholder_count; i++) {
            let h = await market.get_stakeholder(media_id, i);
            let holder = {addr: h[0].toString(), share: h[1].toNumber()};

            total_stake_share += holder.share;
            parties.push(holder);
        }

        // Technically, a creator is a stakeholder too
        parties.push({addr: media_creator, share: 100 - total_stake_share});

        // Find balances of all involved parties, before
        let bal_before = parties.map((h) => web3.eth.getBalance(h.addr).toNumber());

        // Sanity check
        assert.equal(bal_before.length, 6);

        // Buy the media
        await market.buy_media(
            media_id, INDIVIDUAL, {from: accounts[3], value: media_cost}
        );

        // Find balances of all involved parties, after
        let bal_after = parties.map((h) => web3.eth.getBalance(h.addr).toNumber());

        // Confirm that every party got their share
        parties.forEach((h, i) => assert.equal(bal_after[i], bal_before[i] + (h.share / 100) * media_cost));
    });

    // /////////////////////////////////////////////////////////////////////////
    //                          Full Integration Test
    // /////////////////////////////////////////////////////////////////////////

    it("fully works", async function() {
        // These values will be filled by the creator/buyer
        // Initial values should be different!
        // so we can show that everything is working correctly.
        let observed_url = "X";
        let expected_url = "Y";

        // TODO: Find a way to extract the public key from a buyer's address (using on-chain data)
        let buyers_pub_key = "03463c760cabfe2ea0529c0335656fd12b0c81fc40c478d197ae7384f197bfca1b";

        // This simulates a creator
        // who is watching for a buy event to happen
        // and will respond with an encrypted URL
        async function creator_ev_handler(error, event) {
            if (!error) {
                let buyers_address = event.args.buyer;
                let media_id = event.args.media_id;

                // A creator knows URLs to all media
                let media_urls = {
                    1: "http://creator.storage.com/media/1",
                    2: "http://creator.storage.com/media/2",
                };

                let plain_url = media_urls[media_id];
                expected_url = plain_url;

                let encrypted_url = await EthEnc.encryptWithPublicKey(buyers_pub_key, plain_url);

                // console.log("Sending URL to contract: " + encrypted_url);

                // TODO: Add failure test if someone else tries to send instead of creator?

                // Send the URL back to contract who will forward to buyer
                await market.url_for_media(
                    buyers_address, media_id, encrypted_url, {from: accounts[3]}
                );

                buy_event.stopWatching();
            }
        }

        let buy_event = market.evConsumerWantsToBuy({}, {});
        buy_event.watch(creator_ev_handler);

        // The placement of these lines signifies that:
        // the creator, defined above, doesn't know who a particular buyer is
        // while the buyer, defined below, knows their own address
        let buyer = accounts[2];

        // Similarly, only a buyer knows their own private key
        let buyers_pvt_key = "43137cdb869f4375abfce46910aa24d528b2152c5a396158550158fbdb160b4f";

        // This simulates a buyer
        // who is waiting to receive an encrypted URL
        async function buyer_ev_handler(error, event) {
            if (!error) {
                // React only if this message was meant for me
                // Other people won't be able to decrypt this message anyway
                if (event.args.buyer == buyer) {
                    let encrypted_url = event.args.url;
                    let decrypted_url = await EthEnc.decryptWithPrivateKey(buyers_pvt_key, encrypted_url);

                    observed_url = decrypted_url;

                    // console.log("Received URL for media " + event.args.media_id + " is " + decrypted_url);
                    assert.equal(observed_url, expected_url);

                    // Confirm that the encrypted URL was stored on the chain
                    let purchased_record = await market.purchases(buyer, event.args.media_id);
                    assert.equal(purchased_record[1], encrypted_url);

                    // I got what I wanted, game over!
                    url_event.stopWatching();
                }
            }
        }

        let url_event = market.evURLForMedia({}, {});
        url_event.watch(buyer_ev_handler);

        // Initiate a purchase for media 1
        await market.buy_media(1, INDIVIDUAL, {from: buyer, value: 1000 * finney});
    });

    // TODO: Write failure tests
    // it("fails when buyer has insufficient balance");
    // it("fails when stakeholder shares don't sum up to 100");

    // it("doesn't allow buying a media again");
    // it("returns encrypted URL if media is already bought");

    // it("deducts the right cost for individual")
    // it("deducts the right cost for company")
    // it("fails when paying anything except the right cost")
});

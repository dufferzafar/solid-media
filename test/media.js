// const EthCrypto = require("eth-crypto");

const MediaMarket = artifacts.require("./MediaMarket.sol");

contract("MediaMarket", function(accounts) {
    let market; // Will store an instance of our contract

    beforeEach("setup contract for each test", async function() {
        market = await MediaMarket.deployed();
    });

    it("initializes with one media file", async function() {
        assert.equal(await market.media_count(), 1);
    });

    it("initializes the media file with 'correct' values", async function() {
        media = await market.media_store(1);
        assert.equal(media[0], 1);
        assert.equal(media[1], "If I lose myself");
    });

    it("allows adding a media entry", async function() {
        await market.add_media("Avengers: Infinity War", 5000, 7000);
        assert.equal(await market.media_count(), 2);
    });

    it("allows listing available media", async function() {
        media_count = await market.media_count();

        observed_list = [];
        for (let i = 1; i <= media_count; i++) {
            media = await market.media_store(i);
            observed_list.push(media[1]);
        }

        expected_list = ["If I lose myself", "Avengers: Infinity War"];

        assert.deepEqual(observed_list, expected_list);
    });

    it("allows buying a media", async function() {
        buyer = accounts[0];

        await market.buy_media(1, {from: buyer});

        purchased_media = await market.purchases(buyer);
        assert.equal(purchased_media[0], 1);
    });

    it("triggers an event when buying", async function() {
        buyer = accounts[1];

        // Start watching for the Buy event to pop up
        let event = market.evConsumerWantsToBuy({}, {});
        event.watch(function(error, ev) {
            if (!error && (ev.args.buyer == buyer)) {
                assert.equal(ev.args.media_id, 1);
            }
        });

        await market.buy_media(1, {from: buyer});

        purchased_media = await market.purchases(buyer);
        assert.equal(purchased_media[0], 1);

        event.stopWatching();
    });

    it("allows communication via contract", async function() {
        // This simulates a creator
        // who is watching for a buy event to happen
        // and will respond with an encrypted URL
        async function creator_ev_handler(error, event) {
            if (!error) {
                buyers_address = event.args.buyer;
                media_id = event.args.media_id;

                // TODO: Find public key corresponding to buyer's address

                // TODO: Encrypt URL using the public key
                encrypted_url = "http://www.google.com"

                // Send the URL back to contract who will forward to buyer
                // console.log("Sending URL to contract: " + encrypted_url);
                await market.url_for_media(buyers_address, media_id, encrypted_url);

                // FIXME: Is it wrong to put this here? Or should this be done at end?
                buy_event.stopWatching();
            }
        }

        buy_event = market.evConsumerWantsToBuy({}, {});
        buy_event.watch(creator_ev_handler);

        // The placement of this line signifies that:
        // the creator, defined above, doesn't know who a particular buyer is
        // while the buyer, defined below, knows their own address
        buyer = accounts[2];

        // This simulates a buyer
        // who is waiting to receive an encrypted URL
        async function buyer_ev_handler(error, event) {
            if (!error) {
                // If this message was meant for me
                if (event.args.buyer == buyer) {

                    // TODO: Decrypt URL using Private Key
                    console.log("Received URL for media " + event.args.media_id +
                                " is " + event.args.url);

                    // I got what I wanted, game over!
                    url_event.stopWatching();
                }
            }
        }

        url_event = market.evURLForMedia({}, {});
        url_event.watch(buyer_ev_handler);

        // These lines are also executed by a buyer
        await market.buy_media(1, {from: buyer});

        // Test that everything worked correctly
        purchased_media = await market.purchases(buyer);
        assert.equal(purchased_media[0], 1);

    });
});

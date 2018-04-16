const EthEnc = require("ethereum-encryption");

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
        // These values will be filled by the creator/buyer
        // Initial values should be different!
        // so we can show that everything is working correctly.
        observed_url = "X";
        expected_url = "Y";

        // TODO: Find a way to extract the public key from a buyer's address (using on-chain data)
        buyers_pub_key = "03463c760cabfe2ea0529c0335656fd12b0c81fc40c478d197ae7384f197bfca1b";

        // This simulates a creator
        // who is watching for a buy event to happen
        // and will respond with an encrypted URL
        async function creator_ev_handler(error, event) {
            if (!error) {
                buyers_address = event.args.buyer;
                media_id = event.args.media_id;

                // TODO: A dict of URLs for other media ?!
                plain_url = "http://www.google.com";
                expected_url = plain_url;

                encrypted_url = await EthEnc.encryptWithPublicKey(buyers_pub_key, plain_url);

                // Send the URL back to contract who will forward to buyer
                // console.log("Sending URL to contract: " + encrypted_url);
                await market.url_for_media(buyers_address, media_id, encrypted_url);

                buy_event.stopWatching();
            }
        }

        buy_event = market.evConsumerWantsToBuy({}, {});
        buy_event.watch(creator_ev_handler);

        // The placement of these lines signifies that:
        // the creator, defined above, doesn't know who a particular buyer is
        // while the buyer, defined below, knows their own address
        buyer = accounts[2];

        // Similarly, only a buyer knows their own private key
        buyers_pvt_key = "43137cdb869f4375abfce46910aa24d528b2152c5a396158550158fbdb160b4f";

        // This simulates a buyer
        // who is waiting to receive an encrypted URL
        async function buyer_ev_handler(error, event) {
            if (!error) {
                // React only if this message was meant for me
                // Other people won't be able to decrypt this message anyway
                if (event.args.buyer == buyer) {
                    decrypted_url = await EthEnc.decryptWithPrivateKey(buyers_pvt_key, event.args.url);

                    observed_url = decrypted_url;

                    // console.log("Received URL for media " + event.args.media_id + " is " + decrypted_url);

                    assert.equal(observed_url, expected_url);

                    // I got what I wanted, game over!
                    url_event.stopWatching();
                }
            }
        }

        url_event = market.evURLForMedia({}, {});
        url_event.watch(buyer_ev_handler);

        // Buyer starts the game asking to buy
        await market.buy_media(1, {from: buyer});
    });

    // TODO: Write failure tests
    // it("fails when wrong media is bought");
    // it("fails when buyer has insufficient balance");
    // it("fails when stakeholder shares don't sum up to 100");

    // it("doesn't allow buying a media again");
    // it("returns encrypted URL if media is already bought");

    // it("deducts the right cost for individual")
    // it("deducts the right cost for company")


});

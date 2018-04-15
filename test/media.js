var MediaMarket = artifacts.require("./MediaMarket.sol");

contract("MediaMarket", function(accounts) {
    var market;  // Will store an instance of our contract

    beforeEach('setup contract for each test', async function () {
        market = await MediaMarket.deployed();
    })

    it("initializes with one media file", async function() {
        assert.equal(await market.media_count(), 1);
    });

    it("initializes the media file with \'correct\' values", async function() {
        media = await market.media_store(1);
        assert.equal(media[0], 1);
        assert.equal(media[1], "If I lose myself");
    });

    it("adds a media entry", async function() {
        await market.add_media("Avengers: Infinity War")
        assert.equal(await market.media_count(), 2);
    });

    it("lists available media", async function() {
        observed_list = [];
        expected_list = ["If I lose myself", "Avengers: Infinity War"];

        media_count = await market.media_count();
        for (let i = 1; i <= media_count; i++) {

            media = await market.media_store(i)
            observed_list.push(media[1]);

            // TODO: Find a way to do this outside the loop
            // Just moving this down won't work
            // Because the list gets created after some time
            // and is still empty before the code reaches there
            if (i == media_count) {
                assert.deepEqual(observed_list, expected_list);
            }
        }
    });

});

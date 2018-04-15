var MediaMarket = artifacts.require("./MediaMarket.sol");

contract("MediaMarket", function(accounts) {
    var MediaInstance;

    it("initializes with two media files", function() {

        return MediaMarket.deployed()

        .then(function(instance) {
            return instance.media_count();
        })

        .then(function(count) {
            assert.equal(count, 2);
        });

    });

    it("initializes the media files with \'correct\' values", function() {

        return MediaMarket.deployed()

        .then(function(instance) {
            MediaInstance = instance;
            return MediaInstance.media_store(1);
        })

        .then(function(media) {
            assert.equal(media[0], 1, "contains the correct id");
            assert.equal(media[1], "If I lose myself", "contains the correct name");
            return MediaInstance.media_store(2);
        })

        .then(function(media) {
            assert.equal(media[0], 2, "contains the correct id");
            assert.equal(media[1], "Avengers: Infinity War", "contains the correct name");
        });
    });

    // TODO: More tests here

    // it("adds a media entry", function() {});

    it("lists available media", function() {

        return MediaMarket.deployed().then(function(instance) {
            MediaInstance = instance;
            return MediaInstance.media_count();
        })

        .then(function(media_count) {

            // Store names of all available media
            // So that we can list compare
            var media_list = [];
            var expected_list = ["If I lose myself", "Avengers: Infinity War"];

            // Build media list one by one
            // Promise chain is needed because it is all async!
            for (var i = 1; i <= media_count; i++) {
                MediaInstance.media_store(i).then(function(media) {
                    var name = media[1];
                    media_list.push(name);

                    // TODO: Find a way to do this outside the loop
                    // Just moving this down won't work
                    // Because the list gets created after some time
                    // and is still empty before the code reaches there
                    if (i == media_count) {
                        assert.deepEqual(media_list, expected_list);
                    }
                });
            }
        })
    });
});

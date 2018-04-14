var MediaMarket = artifacts.require("./MediaMarket.sol");

contract("MediaMarket", function(accounts) {
    var MediaInstance;

    it("initializes with two media files", function() {

        return MediaMarket.deployed().then(function(instance) {
            return instance.media_count();

        }).then(function(count) {
            assert.equal(count, 2);
        });
    });

    it("initializes the media files with \'correct\' values", function() {

        return MediaMarket.deployed().then(function(instance) {
            MediaInstance = instance;
            return MediaInstance.media_store(1);

        }).then(function(media) {
            assert.equal(media[0], 1, "contains the correct id");
            assert.equal(media[1], "If I lose myself", "contains the correct name");
            return MediaInstance.media_store(2);

        }).then(function(media) {
            assert.equal(media[0], 2, "contains the correct id");
            assert.equal(media[1], "Avengers: Infinity War", "contains the correct name");
        });
    });

    // TODO: More tests here

});

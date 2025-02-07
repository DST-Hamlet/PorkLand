local preparedfoods = require("preparedfoods")

preparedfoods.vegstinger.test = function(cooker, names, tags) return (names.asparagus or names.asparagus_cooked or names.radish or names.radish_cooked) and tags.veggie and tags.veggie > 2 and tags.frozen and not tags.meat end

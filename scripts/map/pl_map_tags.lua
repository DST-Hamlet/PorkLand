local AddMapTag = require("map/addmaptags")

local map_tags = {
    Tag = {
        ["City_Foundation"] = function(tagdata)
            return "GLOBALTAG", "City_Foundation"
        end,
        ["Suburb"] = function(tagdata)
            return "GLOBALTAG", "Suburb"
        end,
        ["City1"] = function(tagdata)
            return "GLOBALTAG", "City1"
        end,
        ["City2"] = function(tagdata)
            return "GLOBALTAG", "City2"
        end,
        ["Bramble"] = function(tagdata)
            return "GLOBALTAG", "Bramble"
        end,
        ["Cultivated"] = function(tagdata)
            return "GLOBALTAG", "Cultivated"
        end,
        ["Canopy"] = function(tagdata)
            return "TAG", "Canopy"
        end,
        ["Gas_Jungle"] = function(tagdata)
            return "TAG", "Gas_Jungle"
        end
    },
    TagData = {}
}

AddMapTag(nil, map_tags)

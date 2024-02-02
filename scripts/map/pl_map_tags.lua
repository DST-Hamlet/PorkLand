
local pl_maptags = {
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

local function AddPlMaptags(map_tags)
    for tag, fn in pairs(pl_maptags.Tag) do
        map_tags.Tag[tag] = fn
    end

    for tag, data in pairs(pl_maptags.TagData) do
        map_tags.TagData[tag] = data
    end
end

return AddPlMaptags

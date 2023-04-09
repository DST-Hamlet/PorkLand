local function AddMapTags(map_tags)
    local pl_map_datda = {}

    local pl_map_tags = {
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
    }

    for tag, fn in pairs(pl_map_tags) do
        map_tags.Tag[tag] = fn
    end

    for tag, data in pairs(pl_map_datda) do
        map_tags.TagData[tag] = data
    end
end

return AddMapTags

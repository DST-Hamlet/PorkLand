GLOBAL.setfenv(1, GLOBAL)
require("map/storygen")

local add_map_tags = {}

local Story_ctor = Story._ctor
Story._ctor = function(self, ...)
    Story_ctor(self, ...)

    for tag, fn in pairs(add_map_tags) do
        self.map_tags.Tag[tag] = fn
    end
end

local AddMapTag = function(tag, fn)
    add_map_tags[tag] = fn
end

AddMapTag("City_Foundation", function(tagdata)
    return "GLOBALTAG", "City_Foundation"
end)

AddMapTag("Suburb", function(tagdata)
    return "GLOBALTAG", "Suburb"
end)

AddMapTag("City1", function(tagdata)
    return "GLOBALTAG", "City1"
end)

AddMapTag("City2", function(tagdata)
    return "GLOBALTAG", "City2"
end)

AddMapTag("Bramble", function(tagdata)
    return "GLOBALTAG", "Bramble"
end)

AddMapTag("Canopy", function(tagdata)
    return "GLOBALTAG", "Canopy"
end)

AddMapTag("Cultivated", function(tagdata)
    return "GLOBALTAG", "Cultivated"
end)

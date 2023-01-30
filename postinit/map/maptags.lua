local MapTagger = gemrun("map/maptagger")

MapTagger.AddMapTag("City_Foundation", function(tagdata)
    return "GLOBALTAG", "City_Foundation"
end)

MapTagger.AddMapTag("Suburb", function(tagdata)
    return "GLOBALTAG", "Suburb"
end)

MapTagger.AddMapTag("City1", function(tagdata)
    return "GLOBALTAG", "City1"
end)

MapTagger.AddMapTag("City2", function(tagdata)
    return "GLOBALTAG", "City2"
end)

MapTagger.AddMapTag("Bramble", function(tagdata)
    return "GLOBALTAG", "Bramble"
end)

MapTagger.AddMapTag("Canopy", function(tagdata)
    return "GLOBALTAG", "Canopy"
end)

MapTagger.AddMapTag("Cultivated", function(tagdata)
    return "GLOBALTAG", "Cultivated"
end)

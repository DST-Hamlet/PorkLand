local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("shard_seasons", function(self)
    self:MakeShardSeasons("plateau")
end)

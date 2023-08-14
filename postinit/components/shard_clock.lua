local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("shard_clock", function(self, inst)
    self:MakeShardClock("plateau")
end)

local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("shard_network", function(inst)
    inst:AddComponent("shard_aporkalypse")
end)

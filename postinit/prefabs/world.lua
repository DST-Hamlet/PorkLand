local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("world", function(inst)
    if not TheWorld.components.interiorspawner then
        inst:AddComponent("interiorspawner")
    end
    if not TheWorld.components.economy then
        inst:AddComponent("economy")
    end
end)

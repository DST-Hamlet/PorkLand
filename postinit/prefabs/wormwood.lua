local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("wormwood", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("hayfever")
    inst.components.hayfever.imune = true
end)

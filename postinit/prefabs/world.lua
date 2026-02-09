local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("world", function(inst)
    if not TheWorld.components.interiorspawner then
        inst:AddComponent("interiorspawner")
    end

    if not TheWorld.components.worldwavemanager then
        inst:AddComponent("worldwavemanager")
    end
    
    if not TheNet:IsDedicated() then
        inst:AddComponent("interiorhudindicatablemanager")
    end

    if not TheWorld.ismastersim then
        return
    end

    if not TheWorld.components.economy then -- 世界穿越兼容
        inst:AddComponent("economy")
        inst.components.economy:AddCity(1)
    end

    if not TheWorld.components.uptile then
        inst:AddComponent("uptile")
    end

    if not TheWorld.components.periodicpoopmanager then -- 世界穿越兼容
        inst:AddComponent("periodicpoopmanager")
    end

    if not TheWorld.components.globalidentity then
        inst:AddComponent("globalidentity")
    end

    if not TheWorld.components.globalentityregistry then
        inst:AddComponent("globalentityregistry")
    end

    if not TheWorld.components.worldtimetracker then
        inst:AddComponent("worldtimetracker")
    end

    if not TheWorld.components.teammanager then
        inst:AddComponent("teammanager")
    end

    inst:ListenForEvent("onterraform", function(src, data)
        SendModRPCToClient(GetClientModRPC("PorkLand", "tile_changed"), nil, ZipAndEncodeString(data))
    end, TheWorld)
end)

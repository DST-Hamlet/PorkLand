local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("world", function(inst)
    if not TheWorld.components.interiorspawner then
        inst:AddComponent("interiorspawner")

    end

    if not TheWorld.ismastersim then
        return
    end

    if not TheWorld.components.economy then
        inst:AddComponent("economy")
        inst.components.economy:AddCity(1)
    end

    if not TheWorld.components.uptile then
        inst:AddComponent("uptile")
    end

    if not TheWorld.components.scenariorunner then
        inst:AddComponent("scenariorunner")
        inst.components.scenariorunner:SetScript("set_uptiles")
    end

    if not TheWorld.components.periodicpoopmanager then
        inst:AddComponent("periodicpoopmanager")
    end
end)

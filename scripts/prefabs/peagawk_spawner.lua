local prefabs =
{
    "peagawk",
}

local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.PEAGAWK_RELEASE_TIME, TUNING.PEAGAWK_REGEN_TIME)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    --[[Non-networked entity]]

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.PEAGAWK_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.PEAGAWK_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.PEAGAWK_MAX)
    inst.components.childspawner.childname = "peagawk"
    inst.components.childspawner.spawnoffscreen = true
    inst.components.childspawner:StartSpawning()
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.PEAGAWK_RELEASE_TIME, TUNING.PEAGAWK_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.PEAGAWK_REGEN_TIME, TUNING.PEAGAWK_ENABLED)
    if not TUNING.PEAGAWK_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst.OnPreLoad = OnPreLoad

    return inst
end

return Prefab("peagawk_spawner", fn, nil, prefabs)

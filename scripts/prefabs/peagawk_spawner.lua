local prefabs =
{
    "peagawk",
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.PEAGAWK_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.PEAGAWK_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.PEAGAWK_MAX)
    inst.components.childspawner.childname = "peagawk"
    inst.components.childspawner.spawnoffscreen = TUNING.PEAGAWK_ENABLE
    inst.components.childspawner:StartSpawning()

    return inst
end

return Prefab("peagawk_spawner", fn, nil, prefabs)

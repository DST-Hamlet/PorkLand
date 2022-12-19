local prefabs =
{
    "pog",
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    --[[Non-networked entity]]

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.POG_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.PEAGAWK_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.POG_MAX)
    inst.components.childspawner.childname = "pog"
    inst.components.childspawner.spawnoffscreen = TUNING.PEAGAWK_ENABLED
    inst.components.childspawner:StartSpawning()

    return inst
end

return Prefab("pog_spawner", fn, nil, prefabs)

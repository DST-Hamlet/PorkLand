local function GrowCrop(inst)
    for crop in pairs(inst.components.grower.crops) do
        if crop.components.crop then
            for i = 1, 10 do
                crop.components.crop:DoGrow(9999)
            end
        end
    end
end

local function OnCityPossession(inst)
    if inst.components.grower then
        local seed = SpawnPrefab("seeds")
        inst.components.grower:PlantItem(seed)
        inst:DoTaskInTime(0, GrowCrop)
    end
end

local function fn()
    local inst = Prefabs["fast_farmplot"].fn()

    inst:SetPrefabName("fast_farmplot")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnCityPossession = OnCityPossession

    return inst
end

return Prefab("fast_farmplot_planted",  fn, Prefabs["fast_farmplot"].assets, Prefabs["fast_farmplot"].deps)

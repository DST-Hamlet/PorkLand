local function GrowCrop(inst)
    for ent, _ in ipairs(inst.components.grower.crops) do
        if ent.components.crop then
            for i = 1, 10 do
                ent.components.crop:DoGrow(9999)
            end
        end
    end
end

local function OnLoad(inst, data)
    if not (data and data.no_nudge) then
        if inst.components.grower then
            local seed = SpawnPrefab("seeds")
            inst.components.grower:PlantItem(seed)
            inst:DoTaskInTime(0, GrowCrop)
        end
    end
end

local function OnSave(inst, data)
    data.no_nudge = true
end

local function fn()
    local inst = Prefabs["fast_farmplot"].fn()

    inst:SetPrefabName("fast_farmplot")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    return inst
end

return Prefab("fast_farmplot_planted",  fn, Prefabs["fast_farmplot"].assets, Prefabs["fast_farmplot"].deps)

local prefabs = {
    "hanging_vine",
    "grabbing_vine"
}

local function round(x)
    x = x * 10
    local num = x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
    return num / 10
end

local function PlaceOffGrids(inst, radiusMax, prefab, tags)
    radiusMax = radiusMax or 12
    local x, y, z = inst.Transform:GetWorldPosition()
    local off_grid = false
    local inc = 1
    while off_grid == false do
        local rad = math.random() * radiusMax
        local x_diff = math.random() * rad
        local y_diff = math.sqrt((rad * rad) - (x_diff * x_diff))

        if math.random() > 0.5 then
            x_diff = -x_diff
        end

        if math.random() > 0.5 then
            y_diff = -y_diff
        end

        x = x + x_diff
        z = z + y_diff

        local ents = TheSim:FindEntities(x, y, z, 1, tags)
        local test = true
        for i, ent in ipairs(ents) do
            local ent_x , _, ent_z = ent.Transform:GetWorldPosition()
            if round(x) == round(ent_x) or round(z) == round(ent_z) or (math.abs(round(ent_x - x)) == math.abs(round(ent_z - z))) then
                test = false
                break
            end
        end

        off_grid = test
        inc = inc + 1
    end

    if CheckTileAtPoint(x, y, z, WORLD_TILES.DEEPRAINFOREST) then
        local plant = SpawnPrefab(prefab)
        plant.Transform:SetPosition(x, y, z)
        plant.spawn_patch = inst
        return true
    end
        return false
end

local function SpawnVine(inst, prefab)
    -- if TheWorld:IsWorldGenOptionNever(prefab) then  -- 世界设置相关，该部分未完成
    --     return
    -- end

    local rad = prefab == "grabbing_vine" and 12 or 14
    PlaceOffGrids(inst, rad, prefab, {"hangingvine"})
end

local function SpawnVines(inst)
    for i = 1, math.random(TUNING.HANGING_VINE_SPAWN_MIN, TUNING.HANGING_VINE_SPAWN_MAX) do
        SpawnVine(inst, "hanging_vine")
    end

    for i = 1, math.random(TUNING.GRABBING_VINE_SPAWN_MIN, TUNING.GRABBING_VINE_SPAWN_MAX) do
        SpawnVine(inst, "grabbing_vine")
    end
end

local function SpawnNewVine(inst, prefab, guid)
    guid = tostring(guid)
    if inst.spawn_tasks[guid] ~= nil then
        return
    end

    inst.spawn_tasks[guid] = prefab
    local spawn_time = TUNING.VINE_REGEN_TIME_MIN + (TUNING.VINE_REGEN_TIME_MAX - TUNING.VINE_REGEN_TIME_MIN) * math.random()
    inst.components.timer:StartTimer(guid, spawn_time)
end

local function OnTimeDone(inst, data)
    if data and data.name then
        local guid = data.name
        local prefab = inst.spawn_tasks[guid]
        inst.spawn_tasks[guid] = nil
        SpawnVine(inst, prefab)
    end
end

local function OnSave(inst, data)
    if inst.spawn_tasks then
        data.spawn_tasks = {}
        for guid, prefab in pairs(inst.spawn_tasks)do
            data.spawn_tasks[guid] = prefab
        end
    end
end

local function OnLoad(inst, data)
    if data and data.spawn_tasks then
        for guid, prefab in pairs(data.spawn_tasks)do
            inst.spawn_tasks[guid] = prefab
        end
    end
end

local function Init(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local spawner = SpawnPrefab("hanging_vine_spawner")
    spawner.Transform:SetPosition(x, y, z)
    SpawnVines(spawner)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    --[[Non-networked entity]]
    inst.spawn_tasks = {}

    inst:AddComponent("timer")

    inst:ListenForEvent("timerdone", OnTimeDone)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.SpawnNewVine = SpawnNewVine

    return inst
end

local function patch_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    inst:DoTaskInTime(0, Init)

    --[[Non-networked entity]]
    return inst
end

return Prefab("hanging_vine_spawner", fn, nil, prefabs),
    Prefab("hanging_vine_patch", patch_fn, nil, prefabs)

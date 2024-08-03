local assets =
{
    Asset("ANIM", "anim/sprinkler.zip"),
    Asset("ANIM", "anim/sprinkler_placement.zip"),
    Asset("ANIM", "anim/sprinkler_meter.zip"),
}

local prefabs =
{
    "water_spray",
    "water_pipe",
    "alloy",
}

local function GetStatus(inst, viewer)
    if inst.components.machine.ison then
        return "ON"
    else
        return "OFF"
    end
end

local RANGE = 8
local UPDATE_TIME = 0.2

local function SpawnDrop(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i = 1, 2 do
        local drop = SpawnPrefab("raindrop")
        local angle = math.random() * 2 * PI
        local dist = math.random() * RANGE
        local offset = Vector3(math.cos(angle), 0, math.sin(-angle)) * dist
        drop.Transform:SetPosition(x + offset.x, 0, z + offset.z)
    end
end

local function TurnOn(inst)
    inst.components.fueled:StartConsuming()

    if not inst.water_spray then
        inst.water_spray = SpawnPrefab("water_spray")
        local follower = inst.water_spray.entity:AddFollower()
        follower:FollowSymbol(inst.GUID, "top", 0, -100, 0)
    end
    inst.drop_task = inst:DoPeriodicTask(UPDATE_TIME, SpawnDrop)

    inst.spray_task = inst:DoPeriodicTask(UPDATE_TIME, function()
        if inst.components.machine:IsOn() then
            inst:UpdateSpray()
        end
    end)

    inst.sg:GoToState("turn_on")
end

local function TurnOff(inst)
    inst.components.fueled:StopConsuming()

    if inst.water_spray then
        inst.water_spray:Remove()
        inst.water_spray = nil
    end

    if inst.drop_task then
        inst.drop_task:Cancel()
        inst.drop_task = nil
    end

    if inst.spray_task then
        inst.spray_task:Cancel()
        inst.spray_task = nil
    end

    for GUID, ent in pairs(inst.moisture_targets) do
        if ent.components.moistureoverride then -- just in case
            ent.components.moistureoverride:RemoveAddMoisture(inst)
        end
    end

    inst.sg:GoToState("turn_off")
end

local function OnFuelEmpty(inst)
    inst.components.machine:TurnOff()
end

local function OnFuelSectionChange(newsection, oldsection, inst)
    local fuel_anim = inst.components.fueled:GetCurrentSection()
    inst.AnimState:OverrideSymbol("swap_meter", "sprinkler_meter", tostring(fuel_anim))
end

local function CanInteract(inst)
    local nopipes = not inst.pipes or #inst.pipes <= 0
    return not inst.components.fueled:IsEmpty() and not nopipes
end

local function UpdateSpray(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, RANGE, nil, {"INLIMBO", "FX", "NOBLOCK", "NOCLICK"})

    local moisture_targets_old = {}
    for GUID,v in pairs(inst.moisture_targets) do
        moisture_targets_old[GUID] = v
    end
    inst.moisture_targets = {}

    for k, v in pairs(ents) do
        inst.moisture_targets[v.GUID] = v

        local use_override = true

        if v.components.moisture then
            v.components.moisture:DoDelta(TUNING.MOISTURE_SPRINKLER_PERCENT_INCREASE_PER_SPRAY)
            use_override = false
        end

        if v.components.inventoryitemmoisture then
            v.components.inventoryitemmoisture:DoDelta(TUNING.MOISTURE_SPRINKLER_PERCENT_INCREASE_PER_SPRAY)
            use_override = false
        end

        if not v.components.moistureoverride and use_override then
            v:AddComponent("moistureoverride")
            v:StartUpdatingComponent(v.components.moistureoverride)
        end
        if v.components.moistureoverride and use_override then
            v.components.moistureoverride:SetAddMoisture(inst, TUNING.MOISTURE_SPRINKLER_PERCENT_INCREASE_PER_SPRAY / UPDATE_TIME) -- +2.5 per sec
        end

        if v.components.crop and v.components.crop.task then
            v.components.crop.growthpercent = v.components.crop.growthpercent + (0.001)
        end

        if v.components.burnable then
            v.components.burnable:Extinguish()
        end
    end

    for old_GUID, old_ent in pairs(moisture_targets_old) do
        local still_affected = inst.moisture_targets[old_GUID] ~= nil

        if not still_affected then
            if old_ent.components.moistureoverride then
                old_ent.components.moistureoverride:RemoveAddMoisture(inst)
            end
        end
    end
end

local function IsValidSprinklerTile(tile)
    return not TileGroupManager:IsOceanTile(tile) and (tile ~= WORLD_TILES.INVALID) and (tile ~= WORLD_TILES.IMPASSABLE)
end

local function GetValidWaterPointNearby(pt)
    local range = 20

    local cx, cy = TheWorld.Map:GetTileCoordsAtPoint(pt.x, 0, pt.z)
    local center_tile = TheWorld.Map:GetTile(cx, cy)

    local min_sq_dist = 999999999999
    local best_point = nil

    for x = pt.x - range, pt.x + range, 1 do
        for z = pt.z - range, pt.z + range, 1 do
            local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
            local tile = TheWorld.Map:GetTile(tx, ty)

            if IsValidSprinklerTile(center_tile) and TileGroupManager:IsOceanTile(tile) then
                local cur_point = Vector3(x, 0, z)
                local cur_sq_dist = cur_point:DistSq(pt)

                if cur_sq_dist < min_sq_dist then
                    min_sq_dist = cur_sq_dist
                    best_point = cur_point
                end
            end
        end
    end

    return best_point
end

local function PlaceTestFn(inst, pt)
    return GetValidWaterPointNearby(pt) ~= nil
end

local function RotateToTarget(inst, dest)
    local px, py, pz = inst.Transform:GetWorldPosition()
    local dz = pz - dest.z
    local dx = dest.x - px
    local angle = math.atan2(dz, dx) / DEGREES

    -- Offset angle to account for pipe orientation in file.sa
    local OFFSET_ANGLE = 90
    inst.Transform:SetRotation(angle - OFFSET_ANGLE)
end

local function CreatePipes(inst)
    local my_pos = Vector3(inst.Transform:GetWorldPosition())
    local target_pos = GetValidWaterPointNearby(my_pos)

    inst.pipes = {}

    if not target_pos then
        return
    end

    local total_dist = target_pos:Dist(my_pos)
    local pipe_length = 2
    local metric_pipe_length = pipe_length / total_dist

    for t = 0.0, 1.0, metric_pipe_length do -- lerping
        local spawn_point = (target_pos - my_pos) * t + my_pos

        local pipe = SpawnPrefab("water_pipe")
        pipe.Transform:SetPosition(spawn_point.x, 0.0, spawn_point.z)
        pipe.pipe_owner = inst

        RotateToTarget(pipe, target_pos)

        table.insert(inst.pipes, pipe)
    end

    for i, pipe in ipairs(inst.pipes) do
        if i > 1 then
            pipe._prev = inst.pipes[i - 1]
        end
        if i < #inst.pipes then
            pipe._next = inst.pipes[i + 1]
        end
    end
end

local function ExtendPipes(inst)
    if inst.loaded_pipes_from_file then
        for _, pipe in pairs(inst.pipes) do
            pipe.sg:GoToState("idle")
        end
    else

        inst.pipes[1].sg:GoToState("extend", 1)
    end
end

local function RetractPipes(inst)
    inst.pipes[#inst.pipes].sg:GoToState("retract", #inst.pipes)
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("firesuppressor_idle")
end

local function OnSave(inst, data)
    data.pipes = {}
    data.pipe_angles = {}

    local refs = {}

    for _, pipe in pairs(inst.pipes) do
        table.insert(refs, pipe.GUID)
        table.insert(data.pipes, pipe.GUID)
        table.insert(data.pipe_angles, pipe.Transform:GetRotation())
    end
    return refs
end

local function OnLoadPostPass(inst, newents, data)
    inst.pipes = {}
    inst.loaded_pipes_from_file = false

    if not data or not data.pipes then
        return
    end

    for i, pipe in ipairs(data.pipes) do
        local new_pipe = newents[pipe].entity

        if new_pipe then
            new_pipe.pipe_owner = inst
            new_pipe.Transform:SetRotation(data.pipe_angles[i])

            inst.pipes[i] = new_pipe

            inst.loaded_pipes_from_file = true
        end
    end

    for i, pipe in ipairs(inst.pipes) do
        if i > 1 then
            pipe._prev = inst.pipes[i - 1]
        end
        if i < #inst.pipes then
            pipe._next = inst.pipes[i + 1]
        end
    end
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_off")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/sprinkler/place")
end

local function OnHit(inst, worker)
    if inst:HasTag("burnt") then
        return
    end

    if inst.sg:HasStateTag("busy") then
        return
    end

    inst.sg:GoToState("hit")
end

local function OnHammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    inst.SoundEmitter:KillSound("idleloop")
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")

    TurnOff(inst)
    RetractPipes(inst)

    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("sprinkler")
    inst.AnimState:SetBuild("sprinkler")
    inst.AnimState:PlayAnimation("idle_off")
    inst.AnimState:OverrideSymbol("swap_meter", "sprinkler_meter", "10")

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("sprinkler.tex")

    inst:AddTag("sprinkler")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = TurnOn
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine.caninteractfn = CanInteract
    inst.components.machine.cooldowntime = 0.5

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled.accepting = true
    inst.components.fueled:SetSections(10)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled:InitializeFuelLevel(TUNING.SPRINKLER_MAX_FUEL_TIME)
    inst.components.fueled.bonusmult = 5
    inst.components.fueled.secondaryfueltype = FUELTYPE.CHEMICAL

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:SetStateGraph("SGsprinkler")

    MakeSnowCovered(inst, 0.01)
    MakeHauntable(inst)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntitySleep = OnEntitySleep
    inst.UpdateSpray = UpdateSpray

    inst.moisturizing = 2
    inst.water_spray = nil
    inst.moisture_targets = {}

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:DoTaskInTime(0.1, function()
        if not inst.pipes or #inst.pipes < 1 then
            CreatePipes(inst)
        end
        ExtendPipes(inst)
    end)

    return inst
end

return  Prefab("sprinkler", fn, assets, prefabs),
        MakePlacer("sprinkler_placer", "sprinkler_placement", "sprinkler_placement", "idle", true, nil, nil, 1.4)
local assets =
{
    Asset("ANIM", "anim/gold_puddle.zip"),
    Asset("ANIM", "anim/water_ring_fx.zip"),
}

local prefabs =
{
    "gold_dust",
}

local function IsLowPriorityAction(act)
    return act == nil or (act and act.action ~= ACTIONS.LOOKAT and act.action ~= ACTIONS.PAN)
end

--Runs on clients
local function CanMouseThrough(inst)
    if ThePlayer ~= nil and ThePlayer.components.playeractionpicker ~= nil then
        local lmb, rmb = ThePlayer.components.playeractionpicker:DoGetMouseActions(inst:GetPosition(), inst)
        return IsLowPriorityAction(rmb) and IsLowPriorityAction(lmb), true
    end
end

local STAGES = {
    {
        name = "empty",
        shrink_anim = "disappear",
        workleft = 0,
        range = 0,
    },
    {
        name = "small",
        anim = "small_idle",
        grow_anim = "appear",
        shrink_anim = "med_to_small",
        workleft = 1,
        range = 1.6,
    },
    {
        name = "med",
        anim = "med_idle",
        grow_anim = "small_to_med",
        shrink_anim = "big_to_med",
        workleft = 2,
        range = 2.6,
    },
    {
        name = "big",
        anim = "big_idle",
        grow_anim = "med_to_big",
        workleft = 3,
        range = 3.5,
    },
}

local function SetStage(inst, stage, init)
    inst.stage = stage

    local STAGE = STAGES[inst.stage]
    inst.components.workable:SetWorkLeft(STAGE.workleft)
    inst.components.ripplespawner:SetRange(STAGE.range)

    if inst.stage > 1 then
        inst:Show()
        inst:RemoveTag("NOCLICK")
        inst.MiniMapEntity:SetEnabled(true)
        inst.components.workable:SetWorkable(true)
    else
        if init then
            inst:Hide()
        end
        inst:AddTag("NOCLICK")
        inst.MiniMapEntity:SetEnabled(false)
        inst.components.workable:SetWorkable(false)
    end

    if init then
        if STAGE.anim then
            inst.AnimState:PlayAnimation(STAGE.anim, true)
        else
            inst.AnimState:PlayAnimation(STAGE.shrink_anim)
        end
    end

    return STAGE
end

local function GetNewWaterLimit(inst)
    return 36 + (math.random() * 8)
end

local function StopGrow(inst)
    if inst.grow_task then
        inst.grow_task:Cancel()
        inst.grow_task = nil
    end
end

local function Grow(inst)
    local stage = SetStage(inst, inst.stage + 1)

    inst.AnimState:PlayAnimation(stage.grow_anim)
    if stage.anim then
        inst.AnimState:PushAnimation(stage.anim, true)
    end

    if inst.stage == #STAGES then
        StopGrow(inst)
    end
end

local function CollectRain(inst)
    inst.water_collected = inst.water_collected + 1
    if inst.water_collected > inst.water_limit then
        inst.water_collected = 0
        inst.water_limit = GetNewWaterLimit(inst)
        Grow(inst)
    end
end

local function StartGrow(inst)
    if inst.grow_task == nil then
        inst.grow_task = inst:DoPeriodicTask(5, CollectRain)
    end
end

local function OnWorkCallback(inst, worker, workleft)
    inst.components.lootdropper:SpawnLootPrefab("gold_dust")
    inst:Shrink()
end

local function OnIsRaining(inst, is_raining)
    if is_raining then
        if (inst.stage < #STAGES) and (inst.stage > 1 or math.random() < 0.2) then
            StartGrow(inst)
        end
    else
        StopGrow(inst)
    end
end

local function Shrink(inst)
    local stage = SetStage(inst, inst.stage - 1)

    inst.water_collected = 0

    inst.AnimState:PlayAnimation(stage.shrink_anim)
    if stage.anim then
        inst.AnimState:PushAnimation(stage.anim, true)
    end

    OnIsRaining(inst, TheWorld.state.raining)
end


local function OnAnimover(inst, data)
    if inst.AnimState:IsCurrentAnimation("disappear") then
        inst:Hide()
    end
end

local SAFE_EDGE_RANGE = 7
local SAFE_PUDDLE_RANGE = 7
local function Reposition(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local  angle, opposite_angle, tile_x, tile_z

    local offsets = {}
    for i = 1, 8 do
        angle = (i - 1) * PI / 4
        tile_x, tile_z = SAFE_EDGE_RANGE * math.cos(angle), -SAFE_EDGE_RANGE * math.sin(angle)
        if TheWorld.Map:GetTileAtPoint(x + tile_x, 0, z + tile_z) ~= WORLD_TILES.PAINTED then
            opposite_angle = angle - PI
            table.insert(offsets, {x = SAFE_EDGE_RANGE * math.cos(opposite_angle), z = -SAFE_EDGE_RANGE * math.sin(opposite_angle)})
        end
    end

    if #offsets > 0 then
        local total_offset_x, total_offset_z = 0, 0
        for _, offset in pairs(offsets) do -- combine all offsets, then divide by number of offsets
            total_offset_x = total_offset_x + offset.x
            total_offset_z = total_offset_z + offset.z
        end

        x = x + total_offset_x / #offsets
        z = z + total_offset_z / #offsets

        inst.Transform:SetPosition(x, 0, z)
    end

    local ents = TheSim:FindEntities(x, 0, z, SAFE_PUDDLE_RANGE, {"sedimentpuddle"})
    if #ents > 1 then
        -- Overlapping other puddles!
        inst:Remove()
    end

    inst.spawned = true
end

local function Init(inst)
    if not inst.stage then
        SetStage(inst, math.random(1, 4), true)
    end

    if not inst.spawned then
        Reposition(inst)
    end

    OnIsRaining(inst, TheWorld.state.raining)
end

local function OnSave(inst, data)
    data.water_collected = inst.water_collected
    data.water_limit = inst.water_limit
    data.stage = inst.stage
    data.spawned = inst.spawned
    data.rotation = inst.Transform:GetRotation()
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.water_collected = data.water_collected
    inst.water_limit = data.water_limit

    inst.stage = data.stage
    if inst.stage then
        SetStage(inst, inst.stage, true)
    end

    if data.spawned then
        inst.spawned = true
    end

    if data.rotation then
        inst.Transform:SetRotation(data.rotation)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("gold_puddle.tex")

    inst.AnimState:SetBuild("gold_puddle")
    inst.AnimState:SetBank("gold_puddle")
    inst.AnimState:PlayAnimation("big_idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.Transform:SetRotation(math.random() * 360)

    inst:AddTag("sedimentpuddle")
    inst:AddTag("NOBLOCK")
    inst:AddTag("OnFloor")

    inst.no_wet_prefix = true
    inst.CanMouseThrough = CanMouseThrough

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.water_collected = 0
    inst.water_limit = GetNewWaterLimit(inst)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("ripplespawner")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.PAN)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.Shrink = Shrink
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:WatchWorldState("israining", OnIsRaining)
    inst:ListenForEvent("animover", OnAnimover)

    inst:DoTaskInTime(0, Init)

    return inst
end

local function MakeRipple(speed)
    local function ripplefn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild("water_ring_fx")
        inst.AnimState:SetBank("water_ring_fx")
        inst.AnimState:PlayAnimation(speed)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetMultColour(1, 1, 1, 1)

        inst:AddTag("NOBLOCK")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst:ListenForEvent("animover", inst.Remove)
        inst:ListenForEvent("entitysleep", inst.Remove)

        return inst
    end

    return Prefab(string.format("puddle_ripple_%s_fx", speed), ripplefn, assets, prefabs)
end

return Prefab("sedimentpuddle", fn, assets, prefabs),
    MakeRipple("fast"),
    MakeRipple("slow")

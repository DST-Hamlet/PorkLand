local assets =
{
    Asset("ANIM", "anim/gold_puddle.zip"),
    Asset("MINIMAP_IMAGE", "gold_puddle"),
    Asset("ANIM", "anim/water_ring_fx.zip"),

}

local prefabs =
{
    "gold_dust",
}

local SAFE_EDGE_RANGE = 7
local SAFE_PUDDLE_RANGE = 7

local function getanim(inst, state)
    local size = "big"

    if inst.stage == 1 then
        size = "small"
    elseif inst.stage == 2 then
        size = "med"
    end

    return size .."_" .. state
end

local grow_anim_lookup_table = {"appear", "small_to_med", "med_to_big"}
local shrink_anim_lookup_table = {"disappear", "med_to_small", "big_to_med"}
local range_lookup_table = {0, 1.6, 2.6, 3.5}

local function SetStage(inst, stage, preanim)

    inst.stage = stage
    inst.components.workable:SetWorkLeft(stage)
    inst.components.ripplespawner:SetRange(range_lookup_table[stage + 1]) -- lua index starts at 1

    if stage > 0 then
        inst:Show()
        inst:RemoveTag("NOCLICK")
        inst.MiniMapEntity:SetEnabled(true)

        if preanim then
            inst.AnimState:PlayAnimation( preanim )
            inst.AnimState:PushAnimation( getanim(inst, "idle"), true )
        else
            inst.AnimState:PlayAnimation( getanim(inst, "idle"), true )
        end
    else
        inst.components.workable:SetWorkable(false)

        inst:AddTag("NOCLICK")
        inst.MiniMapEntity:SetEnabled(false)

        if preanim then
            inst.AnimState:PlayAnimation( preanim )
        else
            inst.AnimState:PlayAnimation( getanim(inst, "idle"), true )
            inst:Hide()
        end
    end
end

local function Grow(inst)
    if inst.pause then
        return
    end

    if inst.stage == 0 then
        inst.water_collected = 0
    end

    inst:SetStage(inst.stage + 1, grow_anim_lookup_table[inst.stage +1])
end

local function Shrink(inst)
    if inst.stage == 1 then
        inst.water_collected = 0
    end

    inst:SetStage(inst.stage - 1, shrink_anim_lookup_table[inst.stage])
end

local function get_new_water_limit(inst)
    return 36 + (math.random() * 8)
end

local function CollectRain(inst)
    if inst.pause then
        return
    end

    inst.water_collected = inst.water_collected + 1
    if inst.water_collected > inst.waterlimit then
        inst.water_collected = 0
        inst:Grow()
        inst.water_limit = get_new_water_limit(inst)
    end
end

local function generate_task(inst)
    inst.grow_task = inst:DoPeriodicTask(5, CollectRain)
end

local function OnSave(inst, data)
    data.stage = inst.stage
    data.growing = inst.growing
    data.water_collected = inst.water_collected
    data.water_limit = inst.water_limit

    data.spawned = inst.spawned
    data.rotation = inst.Transform:GetRotation()
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.stage = data.stage
    inst:SetStage(inst.stage)

    inst.water_collected = data.water_collected
    inst.water_limit = data.water_limit

    inst.growing = data.growing
    if inst.growing then
        generate_task(inst)
    end

    if data.spawned then
        inst.spawned = true
    end

    if data.rotation then
        inst.Transform:SetRotation(data.rotation)
    end
end

local function OnWorkCallback(inst, worker, workleft)
    inst.components.lootdropper:SpawnLootPrefab("gold_dust")
    inst:Shrink()
end

local function start_grow(inst, data)
    if (inst.stage and inst.stage > 0) or math.random() < 0.2 then
        inst.growing = true
        generate_task(inst)
    end
end

local function stop_grow(inst, data)
    inst.growing = false
    if inst.grow_task then
        inst.grow_task:Cancel()
        inst.grow_task = nil
    end
end

local function onanimover(inst, data)
    if inst.AnimState:IsCurrentAnimation("disappear") then
        inst:Hide()
    end
end

local function reposition(inst)
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

    inst.spawned = true

    local ents = TheSim:FindEntities(x, 0, z, SAFE_PUDDLE_RANGE, {"sedimentpuddle"})
    if #ents > 1 then
        -- Overlapping other puddles!
        inst:Remove()
    end
end

local function initialsetup(inst)
    if not inst.stage then
        inst:SetStage(math.random(0, 3))
    end

    if not inst.spawned then
        reposition(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("gold_puddle.png")

    inst.AnimState:SetBuild("gold_puddle")
    inst.AnimState:SetBank("gold_puddle")
    inst.AnimState:PlayAnimation("big_idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.Transform:SetRotation(math.random()*360)

    inst:AddTag("sedimentpuddle")
    inst:AddTag("NOBLOCK")
    inst:AddTag("OnFloor")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.water_collected = 0
    inst.water_limit = get_new_water_limit(inst)

    inst.Shrink = Shrink
    inst.Grow = Grow
    inst.SetStage = SetStage

    inst:AddComponent("lootdropper")

    inst:AddComponent("ripplespawner")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.PAN)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:AddComponent("inspectable")
    inst.no_wet_prefix = true

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, initialsetup)

    inst:ListenForEvent("rainstart", function() start_grow(inst) end, TheWorld)
    inst:ListenForEvent("rainstop", function() stop_grow(inst) end, TheWorld)
    inst:ListenForEvent("animover", onanimover)

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

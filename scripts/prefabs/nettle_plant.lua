local assets =
{
    Asset("ANIM", "anim/nettle.zip"),
    Asset("ANIM", "anim/nettle_bulb_build.zip"),
    Asset("ANIM", "anim/nettle_budding_build.zip"),
}

local prefabs =
{
    "cutnettle",
    "hacking_tall_grass_fx",
}

local BULB_HALF_OPEN_BUILD = "nettle_budding_build"
local BULB_CLOSED_BUILD = "nettle_bulb_build"

local valid_tiles = {
    [WORLD_TILES.DEEPRAINFOREST] = true,
    [WORLD_TILES.DEEPRAINFOREST_NOCANOPY] = true,
}

local function is_on_valid_tile(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)

    return valid_tiles[tile]
end

local function GetStatus(inst)
    if not is_on_valid_tile(inst) then
        return "WITHERED"
    elseif inst.wet and not inst.components.pickable:CanBePicked() then
        return "MOIST"
    else
        return "DEFAULT"
    end
end

local function OnPicked(inst)
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked", false)
end

local function OnRegen(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function MakeEmpty(inst)
    inst.AnimState:PlayAnimation("picked", true)
end

local function MakeBarren(inst)
    if inst.AnimState:IsCurrentAnimation("idle_dead") then
        return
    end

    if inst.components.pickable and inst.components.pickable.withered then
        if not inst.components.pickable.hasbeenpicked then
            inst.AnimState:PlayAnimation("full_to_dead")
        else
            inst.AnimState:PlayAnimation("empty_to_dead")
        end
        inst.AnimState:PushAnimation("idle_dead")
    else
        inst.AnimState:PlayAnimation("idle_dead")
    end
end

local function UpdateGrowthStatus(inst)
    if not is_on_valid_tile(inst) or TheWorld.state.iswinter then
        if not inst.components.pickable.paused then
            inst.components.pickable:MakeBarren()
            inst.components.pickable:Pause()
        end
    end
end

local function OnTransplanted(inst)
    if not is_on_valid_tile(inst) then
        inst.components.pickable:MakeBarren()
    else
        inst.components.pickable:MakeEmpty()
    end
    inst.components.pickable:Pause()
    UpdateGrowthStatus(inst)
end

local function OnFinishCallback(inst, digger)
    if inst.components.pickable and inst.components.pickable:CanBePicked() then
        inst.components.lootdropper:SpawnLootPrefab("cutnettle")
    end
    inst.components.lootdropper:SpawnLootPrefab("dug_nettle")
    inst:Remove()
end

local function UpdateMoisture(inst)
    local moisture = inst.components.moistureoverride and inst.components.moistureoverride.wetness or TheWorld.state.wetness

    if moisture > TUNING.NETTLE_MOISTURE_WET_THRESHOLD then -- ready to grow
        inst.AnimState:ClearOverrideBuild(BULB_HALF_OPEN_BUILD)
        inst.AnimState:ClearOverrideBuild(BULB_CLOSED_BUILD)
        inst.wet = true
        inst.components.pickable:MakeUnsuited(false)
        UpdateGrowthStatus(inst) -- start growing
    elseif moisture > TUNING.NETTLE_MOISTURE_DRY_THRESHOLD and inst.wet == true then
        -- if wet, keep wet
    elseif moisture > 0 then -- still a bit dry
        inst.AnimState:AddOverrideBuild(BULB_HALF_OPEN_BUILD)
        inst.wet = false
        inst.components.pickable:MakeUnsuited(true)
        -- don't pause growth just yet, give players some time
    else -- too dry
        inst.AnimState:AddOverrideBuild(BULB_CLOSED_BUILD)
        inst.wet = false
        inst.components.pickable:MakeUnsuited(true)
        UpdateGrowthStatus(inst) -- stop growing
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("nettle")
    inst.AnimState:SetBuild("nettle")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetTime(math.random() * 2)
    inst.AnimState:AddOverrideBuild("nettle_bulb_build")
    inst.AnimState:Hide("Layer 3")

    inst.MiniMapEntity:SetIcon("nettle.tex")

    inst:AddTag("gustable")
    inst:AddTag("nettle_plant")
    inst:AddTag("plant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable:SetUp("cutnettle", TUNING.NETTLE_REGROW_TIME)
    inst.components.pickable:SetOnRegenFn(OnRegen)
    inst.components.pickable:SetOnPickedFn(OnPicked)
    inst.components.pickable:SetMakeEmptyFn(MakeEmpty)
    inst.components.pickable:SetMakeBarrenFn(MakeBarren)
    inst.components.pickable.ontransplantfn = OnTransplanted
    inst.components.pickable.dontunpauseafterwinter = true
    inst.components.pickable.pickydirt = valid_tiles
    inst.components.pickable:MakeUnsuited(true) -- 这里的true会给荨麻加上unsuited标签，代表不适合采摘，也就是产物已经生长完毕，但是没法进行采摘交互

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(OnFinishCallback)
    inst.components.workable:SetWorkLeft(1)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeNoGrowInWinter(inst)
    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)

    inst.wet = false
    inst:DoPeriodicTask(1, UpdateMoisture)
    inst:DoTaskInTime(0, UpdateGrowthStatus)
    --UpdateGrowthStatus(inst)

    return inst
end

return Prefab("nettle", fn, assets, prefabs)

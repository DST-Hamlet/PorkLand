GLOBAL.setfenv(1, GLOBAL)
require("stategraphs/commonstates")

local function on_exit_water(inst)
    local noanim = inst:GetTimeAlive() < 1
    inst.sg:GoToState("emerge", noanim)
end

CommonHandlers.OnExitWater = function()
    return EventHandler("switch_to_land", on_exit_water)
end

local function on_enter_water(inst)
    local noanim = inst:GetTimeAlive() < 1
    inst.sg:GoToState("submerge", noanim)
end

CommonHandlers.OnEnterWater = function()
    return EventHandler("switch_to_water", on_enter_water)
end

local function onattackwithtarget(inst, data)
    if inst.components.health ~= nil and not inst.components.health:IsDead()
        and not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) then
        inst.sg:GoToState("attack", data.target)
    end
end

-- 这个对 doattack 的事件侦听相比 CommonHandlers.OnAttack() 可以额外传入一个 data 参数
CommonHandlers.OnAttackWithTarget = function()
    return EventHandler("doattack", onattackwithtarget)
end

local _PlayFootstep = PlayFootstep
function PlayFootstep(inst, volume, ispredicted, ...)
    local room = TheWorld.components.interiorspawner:GetInteriorCenter(inst:GetPosition())
    if room and inst.SoundEmitter then
        local footstep_tile = room.footstep_tile or room._footstep_tile:value()

        local tile_info = GetTileInfo(footstep_tile) or GetTileInfo(WORLD_TILES.DIRT)
        local runsound = tile_info.runsound or "dontstarve/movement/run_woods"
        local walksound = tile_info.walksound or "dontstarve/movement/walk_woods"
        local suffix = (inst:HasTag("smallcreature") and "_small") or (inst:HasTag("largecreature") and "_large" or "")
        local sound = (inst.sg ~= nil and inst.sg:HasStateTag("running") and runsound or walksound) .. suffix

        inst.SoundEmitter:PlaySound(sound, nil, volume or 1, ispredicted)
    else
        _PlayFootstep(inst, volume, ispredicted, ...)
    end
end

local _PlayMiningFX = PlayMiningFX
function PlayMiningFX(inst, target, nosound, ...)
    if target and target:IsValid() and target:HasTag("mech") and not nosound then
        inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_med_sharp")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/green")
    else
       _PlayMiningFX(inst, target, nosound, ...)
    end
end

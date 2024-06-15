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

local _PlayFootstep = PlayFootstep
function PlayFootstep(inst, volume, ispredicted, ...)
    if inst and inst:HasTag("inside_interior") and inst.SoundEmitter then
        inst.SoundEmitter:PlaySound(
            inst.sg ~= nil and inst.sg:HasStateTag("running") and "dontstarve/movement/run_woods" or "dontstarve/movement/walk_woods"
            ..
            (   (inst:HasTag("smallcreature") and "_small") or
                (inst:HasTag("largecreature") and "_large" or "")
            ),
            nil,
            volume or 1,
            ispredicted
        )
    else
        _PlayFootstep(inst, volume, ispredicted, ...)
    end
end

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

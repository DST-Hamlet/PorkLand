local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

local tasksets = require("map/tasksets")
local MULTIPLY = require("map/forest_map").MULTIPLY

IAENV.AddLevelPreInit("SURVIVAL_SHIPWRECKED_CLASSIC", function(level)
    TUNING.BERMUDA_AMOUNT = TUNING.BERMUDA_AMOUNT * MULTIPLY[level.overrides.bermudatriangle or "default"]

    local task_set = "shipwrecked"
    local overrides = level.overrides

    if overrides.task_set ~= task_set then  -- When changing the world option, the taskset will be changed
        local shipwrecked_set_data = tasksets.GetGenTasks(task_set)
        for k, v in pairs(shipwrecked_set_data) do
            level[k] = v
        end
    end

    if overrides.beequeen ~= "never" then
        print("add beequeen island")
        table.insert(level.tasks, "MeadowBeeQueenIsland")
        table.insert(level.required_prefabs, "beequeenhive")
    end

    -- if overrides.dragonfly ~= "never" then
    --     table.insert(level.tasks, "")
    -- end
end)
local AddLevelPreInit = AddLevelPreInit
GLOBAL.setfenv(1, GLOBAL)

local tasksets = require("map/tasksets")

AddLevelPreInit("PORKLAND_DEFAULT", function(level)

    local task_set = "porkland"
    local overrides = level.overrides

    if overrides.task_set ~= task_set then  -- When changing the world option, the taskset will be changed
        local porkland_set_data = tasksets.GetGenTasks(task_set)
        for k, v in pairs(porkland_set_data) do
            level[k] = v
        end
    end
end)
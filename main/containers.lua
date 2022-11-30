local Vector3 = GLOBAL.Vector3
GLOBAL.setfenv(1, GLOBAL)
local containers = require("containers")
local params = containers.params

--------------------------------------------------------------------------
--[[ ant_chest]]
--------------------------------------------------------------------------

local antchest =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = function(container, item, slot)
        return (item:HasTag("honeyed") or item:HasTag("nectar"))
    end,
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(antchest.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

params["ant_chest"] = antchest

--------------------------------------------------------------------------
--[[ corkchest]]
--------------------------------------------------------------------------

local corkchest =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_thatchpack_1x4",
        animbuild = "ui_thatchpack_1x4",
        pos = Vector3(75, 200, 0),
        side_align_tip = 160,
    },
    type = "cookpot",
    itemtestfn =  function(container, item, slot)
        return not (item:HasTag("irreplaceable"))
    end,
}

for y = 0, 3 do
	table.insert(corkchest.widget.slotpos, Vector3(-162 +(75/2), -y*75 + 114, 0))
end

params["cork_chest"] = corkchest

--------------------------------------------------------------------------
--[[ root_chest]]
--------------------------------------------------------------------------

local rootchest =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chester_shadow_3x4",
        animbuild = "ui_chester_shadow_3x4",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = function()
        return false
    end
}

for y = 2.5, -0.5, -1 do
    for x = 0, 2 do
        table.insert(rootchest.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
    end
end

params["root_chest"] = rootchest
params["root_chest_child"] = params.shadowchester

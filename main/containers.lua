GLOBAL.setfenv(1, GLOBAL)

local params = require("containers").params

local widget_smelter =
{
    widget = {
        slotpos = {
            Vector3(0, 64 + 32 + 8 + 4, 0),
            Vector3(0, 32 + 4, 0),
            Vector3(0, -(32 + 4), 0),
            Vector3(0, -(64 + 32 + 8 + 4), 0),
        },
        animbank = "ui_cookpot_1x4",
        animbuild = "ui_cookpot_1x4",
        pos = Vector3(200, 0, 0),
        side_align_tip = 100,
        buttoninfo = {
            text = STRINGS.ACTIONS.SMELT,
            position = Vector3(0, -165, 0),
        }
    },
    acceptsstacks = false,
    type = "cooker",
}

function widget_smelter.itemtestfn(container, item, slot)
    return item:HasTag("smeltable") and not container.inst:HasTag("burnt")
end

function widget_smelter.widget.buttoninfo.fn(inst, doer)
    if inst.components.container ~= nil then
        BufferedAction(doer, inst, ACTIONS.COOK):Do()
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.COOK.code, inst, ACTIONS.COOK.mod_name)
    end
end

function widget_smelter.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and inst.replica.container:IsFull()
end

params["smelter"] = widget_smelter

local boat_lograft = {
    widget = {
        slotpos = {},
        animbank = "boat_hud_raft",
        animbuild = "boat_hud_raft",
        pos = Vector3(750, 75, 0),
        badgepos = Vector3(0, 40, 0),
        equipslotroot = Vector3(-80, 40, 0),
        --side_align_tip = -500,
    },
    inspectwidget = {
        slotpos = {},
        animbank = "boat_inspect_raft",
        animbuild = "boat_inspect_raft",
        pos = Vector3(200, 0, 0),
        badgepos = Vector3(0, 5, 0),
        equipslotroot = {},
    },
    type = "boat",
    side_align_tip = -500,
    canbeopened = false,
    hasboatequipslots = false,
    enableboatequipslots = true,
}

local boat_row = {
    widget = {
        slotpos = {},
        animbank = "boat_hud_row",
        animbuild = "boat_hud_row",
        pos = Vector3(750, 75, 0),
        badgepos = Vector3(0, 40, 0),
        equipslotroot = Vector3(-80, 40, 0),
        --side_align_tip = -500,
    },
    inspectwidget = {
        slotpos = {},
        animbank = "boat_inspect_row",
        animbuild = "boat_inspect_row",
        pos = Vector3(200, 0, 0),
        badgepos = Vector3(0, 40, 0),
        equipslotroot = Vector3(40, -45, 0),
    },
    type = "boat",
    side_align_tip = -500,
    canbeopened = false,
    hasboatequipslots = true,
    enableboatequipslots = true,
}

local boat_cork = {
    widget = {
        slotpos = {},
        animbank = "boat_hud_row",
        animbuild = "boat_hud_row",
        pos = Vector3(750, 75, 0),
        badgepos = Vector3(0, 40, 0),
        equipslotroot = Vector3(-80, 40, 0),
        -- side_align_tip = -500,
    },
    inspectwidget = {
        slotpos = {},
        animbank = "boat_inspect_row",
        animbuild = "boat_inspect_row",
        pos = Vector3(200, 0, 0),
        badgepos = Vector3(0, 40, 0),
        equipslotroot = Vector3(40, -45, 0),
    },
    type = "boat",
    side_align_tip = -500,
    canbeopened = false,
    hasboatequipslots = true,
    enableboatequipslots = true,
}

local boat_cargo = {
    widget = {
        slotpos = {},
        animbank = "boat_hud_cargo",
        animbuild = "boat_hud_cargo",
        pos = Vector3(750, 75, 0),
        badgepos = Vector3(0, 40, 0),
        equipslotroot = Vector3(-80, 40, 0),
        -- side_align_tip = -500,
    },
    inspectwidget = {
        slotpos = {},
        animbank = "boat_inspect_cargo",
        animbuild = "boat_inspect_cargo",
        pos = Vector3(200, 0, 0),
        badgepos = Vector3(0, 155, 0),
        equipslotroot = Vector3(40, 70, 0),
    },
    type = "boat",
    side_align_tip = -500,
    canbeopened = false,
    hasboatequipslots = true,
    enableboatequipslots = true,
}

for i = 6, 1,-1 do
    table.insert(boat_cargo.widget.slotpos, Vector3(-13 - (80 * (i + 2)), 40 ,0))
end

for y = 1, 3 do
    for x = 0, 1 do
        table.insert(boat_cargo.inspectwidget.slotpos, Vector3(-40 + (x * 80), 70 + (y * -75), 0))
    end
end

params["boat_lograft"] = boat_lograft
params["boat_row"] = boat_row
params["boat_cork"] = boat_cork
params["boat_cargo"] = boat_cargo

local shelf1 =
{
    widget = {
        slotpos = { Vector3(0, 0, 0) }
    },
    acceptsstacks = false,
}


local shelf1x3 = {
    widget = {
        slotpos = {
            Vector3(-85 + 20, 0,   0),
            Vector3(-85 + 20, -80, 0),
            Vector3(-85 + 20, 80,  0)
        },
    },
    acceptsstacks = false,
}

local shelf2x3 =
{
    widget = {
        slotpos = {
            Vector3(-165, -80, 0),
            Vector3(-85,  -80, 0),
            Vector3(-165, 0,   0),
            Vector3(-85,  0,   0),
            Vector3(-165, 80,  0),
            Vector3(-85,  80,  0)
        },
    },
    acceptsstacks = false,
}

params["shelf_ruins"] = shelf1
params["shelf_displayshelf_wood"] = shelf1x3
params["shelf_wood"] = shelf2x3

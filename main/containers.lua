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

for i = 6, 1, -1 do
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

params["shelf_displaycase_wood"] = shelf1x3
params["shelf_displaycase_metal"] = shelf1x3

params["shelf_wood"] = shelf2x3
params["shelf_basic"] = shelf2x3
params["shelf_metal"] = shelf2x3
params["shelf_marble"] = shelf2x3
params["shelf_glass"] = shelf2x3
params["shelf_ladder"] = shelf2x3
params["shelf_hutch"] = shelf2x3
params["shelf_industrial"] = shelf2x3
params["shelf_adjustable"] = shelf2x3
params["shelf_fridge"] = shelf2x3
params["shelf_cinderblocks"] = shelf2x3
params["shelf_midcentury"] = shelf2x3
params["shelf_wallmount"] = shelf2x3
params["shelf_aframe"] = shelf2x3
params["shelf_crates"] = shelf2x3
params["shelf_hooks"] = shelf2x3
params["shelf_pipe"] = shelf2x3
params["shelf_hattree"] = shelf2x3
params["shelf_pallet"] = shelf2x3
params["shelf_floating"] = shelf2x3

params["shelf_ruins"] = shelf1
params["shelf_queen_display_1"] = shelf1
params["shelf_queen_display_2"] = shelf1
params["shelf_queen_display_3"] = shelf1
params["shelf_queen_display_4"] = shelf1

params["shop_buyer"] = shelf1


local widget_antchest = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(widget_antchest.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

function widget_antchest.itemtestfn(contanier, item, slot)
    return item.prefab == "honey" or item.prefab == "nectar_pod"
end

params["antchest"] = widget_antchest

local widget_corkchest = {
    widget = {
        slotpos = {
            Vector3(-162 + 75 / 2, -75 * 0 + 114, 0),
            Vector3(-162 + 75 / 2, -75 * 1 + 114, 0),
            Vector3(-162 + 75 / 2, -75 * 2 + 114, 0),
            Vector3(-162 + 75 / 2, -75 * 3 + 114, 0),
        },
        animbank = "ui_thatchpack_1x4",
        animbuild = "ui_thatchpack_1x4",
        pos = Vector3(75, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

params["corkchest"] = widget_corkchest

params["roottrunk_container"] = deepcopy(params["shadowchester"])
function params.roottrunk_container.itemtestfn(container, item, slot)
    return not item:HasTag("irreplaceable")
end

local widget_armor_vortex_cloak = {
    widget = {
        slotpos = {},
        animbank = "ui_krampusbag_2x5",
        animbuild = "ui_krampusbag_2x5",
        pos = Vector3(-5, -70, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
}

for y = 0, 4 do
    table.insert(widget_armor_vortex_cloak.widget.slotpos, Vector3(-162, -y * 75 + 114, 0))
    table.insert(widget_armor_vortex_cloak.widget.slotpos, Vector3(-162 +75, -y * 75 + 114, 0))
end

params["armorvortexcloak"] = widget_armor_vortex_cloak

params["ro_bin"] = deepcopy(params["chester"])

params["trawlnetdropped"] = deepcopy(params["treasurechest"])
params["sunkenprefab"] = deepcopy(params["treasurechest"])

params["trusty_shooter"] = deepcopy(params["slingshot"])
function params.trusty_shooter.itemtestfn(container, item, slot)
    return container.inst:CanTakeAmmo(item)
end
params["wheeler_tracker"] = deepcopy(params["slingshot"])
function params.wheeler_tracker.itemtestfn(container, item, slot)
    return true
end
params["wheeler_tracker"].widget.slotbg = nil

GLOBAL.setfenv(1, GLOBAL)

local EquipSlot = require("equipslotutil")

local _ESInitialize = EquipSlot.Initialize
local BOATEQUIPSLOT_NAMES, BOATEQUIPSLOT_IDS
function EquipSlot.Initialize()
    _ESInitialize()
    assert(BOATEQUIPSLOT_NAMES == nil and BOATEQUIPSLOT_IDS == nil, "Equip slots already initialized")

    BOATEQUIPSLOT_NAMES = {}
    for k, v in pairs(BOATEQUIPSLOTS) do
        table.insert(BOATEQUIPSLOT_NAMES, v)
    end

    assert(#BOATEQUIPSLOT_NAMES <= 63, "Too many equip slots!")

    BOATEQUIPSLOT_IDS = table.invert(BOATEQUIPSLOT_NAMES)
end

-- These are meant for networking, and can be used in prefab or
-- component logic. They are not valid when modmain is loading.
function EquipSlot.BoatToID(eslot)
    return BOATEQUIPSLOT_IDS[eslot] or 0
end

function EquipSlot.BoatFromID(eslotid)
    return BOATEQUIPSLOT_NAMES[eslotid] or "INVALID"
end
local _ESToID = EquipSlot.ToID
function EquipSlot.ToID(eslot)
    return _ESToID(eslot) or 0
end

local _ESFromID = EquipSlot.FromID
function EquipSlot.FromID(eslotid)
    return _ESFromID(eslotid) or "INVALID"
end

function EquipSlot.BoatCount()
    return #BOATEQUIPSLOT_NAMES
end

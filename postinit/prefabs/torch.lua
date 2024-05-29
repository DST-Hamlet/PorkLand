local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function startrowing(inst, data)
    inst.components.equippable.onunequipfn(inst, data and data.owner or nil)
    if inst.components.inventoryitem.onputininventoryfn then -- this should be "turnoff"
        inst.components.inventoryitem.onputininventoryfn(inst, data and data.owner or nil)
    end
end
local function stoprowing(inst, data)
    inst.components.equippable.onequipfn(inst, data and data.owner or nil)
end

local function PostInit(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("startrowing", startrowing)
    inst:ListenForEvent("stoprowing", stoprowing)
end

AddPrefabPostInit("torch", PostInit)
AddPrefabPostInit("redlantern", PostInit)

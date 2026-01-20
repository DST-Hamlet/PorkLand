local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function GetItemInBoatSlot(inst, eslot)
    local container = inst._parent.replica.container
    if container ~= nil and container.hasboatequipslots then
        local slot = container.boatcontainerequips[eslot]
        if slot == nil then
            return
        end

        return inst:GetItemInSlot(slot)
    end
    return nil
end

AddPrefabPostInit("container_classified", function(inst)
    inst.GetItemInBoatSlot = GetItemInBoatSlot
end)

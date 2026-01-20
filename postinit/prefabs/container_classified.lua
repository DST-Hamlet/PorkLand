local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local IsFull = function(inst)
    local container = inst._parent.replica.container
    if container ~= nil and container.hasboatequipslots then
        if inst._itemspreview ~= nil then
            for i = 1, #inst._items do
                local isequipslot = false
                for eslot, index in pairs(container.boatcontainerequips) do
                    if i == index then
                        isequipslot = true
                    end
                end
                if not isequipslot and inst._itemspreview[i] == nil then
                    return false
                end
            end
        else
            for i, v in ipairs(inst._items) do
                local isequipslot = false
                for eslot, index in pairs(container.boatcontainerequips) do
                    if i == index then
                        isequipslot = true
                    end
                end
                if not isequipslot and v:value() == nil then
                    return false
                end
            end
        end
        return true
    end
    return inst:_IsFull()
end

AddPrefabPostInit("container_classified", function(inst)
    if inst._IsFull == nil then
        inst._IsFull = inst.IsFull
    end
    inst.IsFull = IsFull
end)

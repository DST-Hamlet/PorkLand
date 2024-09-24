local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local InventoryItem = require("components/inventoryitem_replica")
local _SetOwner = InventoryItem.SetOwner
function InventoryItem:SetOwner(owner, ...)
    local boat_owner = owner ~= nil and owner:HasTag("boatcontainer") and owner.components.container ~= nil and owner.components.container.opener
    if boat_owner then
        if self.inst.Network ~= nil then
            self.inst.Network:SetClassifiedTarget(boat_owner)
        end
        if self.classified ~= nil then
            self.classified.Network:SetClassifiedTarget(boat_owner or self.inst)
        end
        return
    end
    return _SetOwner(self, owner, ...)
end

local _SerializeUsage = InventoryItem.SerializeUsage
function InventoryItem:SerializeUsage(...)
    _SerializeUsage(self, ...)
    if self.inst.components.fuse then
        self.classified:SerializeFuse(self.inst.components.fuse.consuming and self.inst.components.fuse.fusetime or 0)
    else
        self.classified:SerializeFuse(nil)
    end
end

local _DeserializeUsage = InventoryItem.DeserializeUsage
function InventoryItem:DeserializeUsage(...)
    _DeserializeUsage(self, ...)
    if self.classified ~= nil then
        self.classified:DeserializeFuse()
    end
end

AddClassPostConstruct("components/inventoryitem_replica", function(self, inst)
    if TheWorld.ismastersim then
        inst:ListenForEvent("fusechange", function(inst, data)
            self.classified:SerializeFuse(data.time)
        end)
    end
end)

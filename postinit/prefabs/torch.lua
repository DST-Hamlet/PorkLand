local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function startrowing(self,data)
    self.components.equippable.onunequipfn(self, data and data.owner or nil)
    if self.components.inventoryitem.onputininventoryfn then --this should be "turnoff"
        self.components.inventoryitem.onputininventoryfn(self, data and data.owner or nil)
    end
end
local function stoprowing(self,data)
    self.components.equippable.onequipfn(self, data and data.owner or nil)
end

AddPrefabPostInit("torch", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _onequipfn = inst.components.equippable.onequipfn
    inst.components.equippable.onequipfn = function(self, owner)
        if owner and owner.sg and owner.sg:HasStateTag("rowing") then return end
        return _onequipfn(self, owner)
    end

    inst:ListenForEvent("startrowing", startrowing)
    inst:ListenForEvent("stoprowing", stoprowing)
end)

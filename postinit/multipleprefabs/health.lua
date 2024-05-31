local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function Init(inst)
    if inst.components.inventoryitem then
        return
    end

    inst:AddComponent("keeponpassable")
end

AddComponentPostInit("health", function(self)
    self.inst:DoTaskInTime(0, Init)
end)

local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("health", function(self)
    self.inst:AddComponent("keeponpassable")
end)

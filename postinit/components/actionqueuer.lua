local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- for client mod ActionQueue
AddComponentPostInit("actionqueuer", function(self)
    self.AddActionList("allclick", "SHEAR", "HACK", "PAN")
    self.AddActionList("leftclick", "SHEAR", "HACK", "PAN")
    self.AddActionList("autocollect", "SHEAR", "HACK", "PAN")
    self.AddActionList("noworkdelay", "SHEAR", "HACK", "PAN")
end)

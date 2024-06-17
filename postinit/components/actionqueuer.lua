local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- for client mod ActionQueue
AddComponentPostInit("actionqueuer", function(self)
    self.AddActionList("allclick", "SHEAR", "HACK", "PAN", "DISLODGE")
    self.AddActionList("leftclick", "SHEAR", "HACK", "PAN", "REPAIRBOAT", "RETRIEVE", "DISLODGE")
    self.AddActionList("autocollect", "SHEAR", "HACK", "PAN", "DISLODGE")
    self.AddActionList("noworkdelay", "SHEAR", "HACK", "PAN", "DISLODGE")
end)

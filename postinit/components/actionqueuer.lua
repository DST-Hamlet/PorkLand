local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- for client mod ActionQueue
AddComponentPostInit("actionqueuer", function(self)
    self.AddActionList("allclick", "SHEAR", "HACK", "DISLODGE")
    self.AddActionList("leftclick", "SHEAR", "HACK", "DISLODGE")
    self.AddActionList("autocollect", "SHEAR", "HACK", "DISLODGE")
    self.AddActionList("noworkdelay", "SHEAR", "HACK", "DISLODGE")
end)

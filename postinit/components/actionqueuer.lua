local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- for client mod ActionQueue
AddComponentPostInit("actionqueuer", function(self)
    self.AddActionList("allclick", "SHEAR", "HACK")
    self.AddActionList("leftclick", "SHEAR", "HACK")
    self.AddActionList("autocollect", "SHEAR", "HACK")
    self.AddActionList("noworkdelay", "SHEAR", "HACK")
end)

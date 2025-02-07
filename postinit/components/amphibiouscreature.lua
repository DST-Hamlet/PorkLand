local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- for client mod ActionQueue
AddComponentPostInit("amphibiouscreature", function(self)
    self.inst:DoTaskInTime(0, function()
        if self.inst:IsAsleep() then
            self:OnUpdate(0)
        end
    end)
end)

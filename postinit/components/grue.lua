local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("grue", function(self)
    self.interior_task = self.inst:DoPeriodicTask(2 * FRAMES, function()
        if self.inst:HasTag("inside_interior") then
            if self.inst:IsInLight() then
                self:AddImmunity("light")
                self:Stop()
            else
                self:Start()
            end
        end
    end)
end)

local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("playervision", function(self)
    local NIGHTVISION_COLOURCUBES = ToolUtil.GetUpvalue(self.UpdateCCTable, "NIGHTVISION_COLOURCUBES")
    local NIGHTVISION_PHASEFN = ToolUtil.GetUpvalue(self.UpdateCCTable, "NIGHTVISION_PHASEFN")
    local NIGHTVISION_COLOURCUBES_INTERIOR = shallowcopy(NIGHTVISION_COLOURCUBES)
    NIGHTVISION_COLOURCUBES_INTERIOR.day = NIGHTVISION_COLOURCUBES_INTERIOR.night

    self.inst:ListenForEvent("enterinterior", function() self:UpdateCCTable() end)
    self.inst:ListenForEvent("leaveinterior", function() self:UpdateCCTable() end)

    local _UpdateCCTable = self.UpdateCCTable
    function self:UpdateCCTable()
        _UpdateCCTable(self)
        if not self.currentcctable then
            if self.inst:HasTag("inside_interior") then
                local cc = self.inst.replica.interiorvisitor:GetCCTable()
                self.currentcctable = cc
                self.inst:PushEvent("ccoverrides", cc)
                self.inst:PushEvent("ccphasefn", nil)
            end
        elseif self.currentcctable == NIGHTVISION_COLOURCUBES then
            if self.inst:HasTag("inside_interior") then
                local cc = NIGHTVISION_COLOURCUBES_INTERIOR
                self.currentcctable = cc
                self.inst:PushEvent("ccoverrides", cc)
                self.inst:PushEvent("ccphasefn", NIGHTVISION_PHASEFN)
            end
        end
    end
end)

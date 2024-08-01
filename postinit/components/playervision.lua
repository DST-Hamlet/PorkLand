local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local BATVISION_COLOUR_CUBE = {
    day = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex"),
    dusk = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex"),
    night = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex"),
    full_moon = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex"),
}

local BATVISION_PHASEFN =
{
    blendtime = 0.5,
    events = {},
    fn = nil,
}

AddComponentPostInit("playervision", function(self)
    local NIGHTVISION_COLOURCUBES = ToolUtil.GetUpvalue(self.UpdateCCTable, "NIGHTVISION_COLOURCUBES")
    local NIGHTVISION_PHASEFN = ToolUtil.GetUpvalue(self.UpdateCCTable, "NIGHTVISION_PHASEFN")
    local NIGHTVISION_COLOURCUBES_INTERIOR = shallowcopy(NIGHTVISION_COLOURCUBES)
    NIGHTVISION_COLOURCUBES_INTERIOR.day = NIGHTVISION_COLOURCUBES_INTERIOR.night
    NIGHTVISION_COLOURCUBES_INTERIOR.dusk = NIGHTVISION_COLOURCUBES_INTERIOR.night
    NIGHTVISION_COLOURCUBES_INTERIOR.full_moon = NIGHTVISION_COLOURCUBES_INTERIOR.night

    local NIGHTVISION_COLOURCUBES_APORKLYPSE = shallowcopy(NIGHTVISION_COLOURCUBES)
    NIGHTVISION_COLOURCUBES_APORKLYPSE.full_moon = NIGHTVISION_COLOURCUBES.dusk

    self.inst:ListenForEvent("enterinterior", function() self:UpdateCCTable() end)
    self.inst:ListenForEvent("leaveinterior", function() self:UpdateCCTable() end)

    self.inst:WatchWorldState("isaporkalypse", function() self:UpdateCCTable() end)

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
            elseif TheWorld.state.isaporkalypse then
                local cc = NIGHTVISION_COLOURCUBES_APORKLYPSE
                self.currentcctable = cc
                self.inst:PushEvent("ccoverrides", cc)
                self.inst:PushEvent("ccphasefn", NIGHTVISION_PHASEFN)
            end
        end

        if self.inst.replica.inventory:EquipHasTag("bat_hat") then
            local cc = BATVISION_COLOUR_CUBE
            self.currentcctable = cc
            self.inst:PushEvent("ccoverrides", cc)
            self.inst:PushEvent("ccphasefn", BATVISION_PHASEFN)
        end
    end
end)

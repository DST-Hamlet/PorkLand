local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local PL_NO_LIGHT_INTERIOR_COLOURS =
{
    PHASE_COLOURS =
    {
        default =
        {
            day = {colour = Point(0, 0, 0), time = 4},
            dusk = {colour = Point(0, 0, 0), time = 6},
            night = {colour = Point(0, 0, 0), time = 8},
        },
    },

    FULL_MOON_COLOUR = {colour = Point(0, 0, 0), time = 8},
    CAVE_COLOUR = {colour = Point(0, 0, 0), time = 2},
}

AddComponentPostInit("ambientlighting", function(self, inst)
    local _realcolour = ToolUtil.GetUpvalue(self.LongUpdate, "_realcolour")

    function self:GetRealColour()
        return _realcolour.currentcolour.x, _realcolour.currentcolour.y, _realcolour.currentcolour.z
    end

    local DoUpdateFlash = ToolUtil.GetUpvalue(self.OnUpdate, "DoUpdateFlash")
    local _overridecolour = ToolUtil.GetUpvalue(DoUpdateFlash, "_overridecolour")
    local ComputeTargetColour = ToolUtil.GetUpvalue(DoUpdateFlash, "ComputeTargetColour")

    local function Pl_ComputeTargetColour(targetsettings, timeoverride, ...)
        if targetsettings == _overridecolour and ThePlayer and ThePlayer:HasTag("inside_interior") then
            if _overridecolour.currentcolourset.PHASE_COLOURS.spring then
                -- when player have no nightvision, change to no light mode
                local temp = _overridecolour.currentcolourset
                _overridecolour.currentcolourset = PL_NO_LIGHT_INTERIOR_COLOURS
                ComputeTargetColour(targetsettings, timeoverride, ...)
                _overridecolour.currentcolourset = temp
                return
            end
        end
        ComputeTargetColour(targetsettings, timeoverride, ...)
    end

    ToolUtil.SetUpvalue(DoUpdateFlash, Pl_ComputeTargetColour, "ComputeTargetColour")

    function self:Pl_Refresh()
        Pl_ComputeTargetColour(_overridecolour, 0.1)
    end
end)

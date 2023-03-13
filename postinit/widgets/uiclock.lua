local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local function OnStopAporkalypse(self)
    if TheWorld:HasTag("porkland") then
        local moon_syms =
        {
            full = "moon_full",
            quarter = self._mooniswaxing and "moon_quarter_wax" or "moon_quarter",
            new = "moon_new",
            threequarter = self._mooniswaxing and "moon_three_quarter_wax" or "moon_three_quarter",
            half = self._mooniswaxing and "moon_half_wax" or "moon_half",
        }

        self._moon_builds.blood = self._moon_builds.default
        self:OnMoonPhaseStyleChanged({style = "default"})
        self._moonanim:GetAnimState():OverrideSymbol("swap_moon", self._moonphasebuild, moon_syms[self._moonphase] or "moon_full")
    end
end

AddClassPostConstruct("widgets/uiclock", function(self)
    self._moon_builds.blood = "moon_aporkalypse_phases"

    self.OnStopAporkalypse = OnStopAporkalypse
    self.inst:WatchWorldState("stopaporkalypse", function() self:OnStopAporkalypse() end)  -- fix something stop aporkalypse moon anim error
end)

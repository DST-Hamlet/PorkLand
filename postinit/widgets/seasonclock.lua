local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

-- compatible Combined Status mod
if not softresolvefilepath("scripts/widgets/seasonclock.lua") then
    return
end

local function season_transition_fn()
    return {"temperate", "humid", "lush", "aporkalypse"}
end

AddClassPostConstruct("widgets/seasonclock", function(self)
    if not TheWorld:HasTag("porkland") then
        return
    end

    self._season_transition_fn = season_transition_fn

    if self.OnSeasonLengthsChanged then
        self:OnSeasonLengthsChanged()
    end

    if self.OnCyclesChanged then
        self:OnCyclesChanged()
    end
end)

local SeasonClock = require("widgets/seasonclock")

if type(SeasonClock) ~= "table" then
    return
end

local _OnSeasonLengthsChanged = SeasonClock.OnSeasonLengthsChanged
function SeasonClock:OnSeasonLengthsChanged(data, ...)
    if not data then
        data = self.GetSeasonLengths and self:GetSeasonLengths() or {}
    end

    data.aporkalypse = 0  -- aporkalypse don't show in clock

    if _OnSeasonLengthsChanged then
        return _OnSeasonLengthsChanged(self, data, ...)
    end
end
ToolUtil.HideHackFn(SeasonClock.OnSeasonLengthsChanged, _OnSeasonLengthsChanged)

local _OnCyclesChanged = SeasonClock.OnCyclesChanged
function SeasonClock:OnCyclesChanged(...)
    if not TheWorld.state.isaporkalypse then
        return _OnCyclesChanged and _OnCyclesChanged(self, ...) or nil
    end

    local NUM_SEGS = 32
    local progress = 0
    local i = 1
    local season = TheWorld.state.preaporkalypseseason or SEASONS.TEMPERATE
    local percent = TheWorld.state.preaporkalypseseasonprogress or 0

    while season ~= self.seasons[i] and self.seasons[i] do
        progress = progress + self.seasonsegments[self.seasons[i]]
        i = i + 1
    end

    if season ~= self.seasons[i] then  -- The current season wasn't in our list of current seasons
        self._text:SetString("FAILED")  -- Let the user know something is wrong
        self.inst:DoTaskInTime(0, function() self:OnCyclesChanged() end) -- Try again next tick
        return  -- Don't continue with the bad data
    end

    local segments = self.seasonsegments[season]
    progress = progress + segments * percent
    progress = progress / NUM_SEGS
    self._hands:SetRotation(progress * 360)
    if self._have_focus then
        self:OnGainFocus()
    else
        self:OnLoseFocus()
    end
end
ToolUtil.HideHackFn(SeasonClock.OnCyclesChanged, _OnCyclesChanged)

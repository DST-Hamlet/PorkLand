GLOBAL.setfenv(1, GLOBAL)
local StatusDisplays = require("widgets/statusdisplays")

local _HealthDelta = StatusDisplays.HealthDelta
function StatusDisplays:HealthDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _HealthDelta(self, data)
    end
end

local _HungerDelta = StatusDisplays.HungerDelta
function StatusDisplays:HungerDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _HungerDelta(self, data)
    end
end

local _SanityDelta = StatusDisplays.SanityDelta
function StatusDisplays:SanityDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _SanityDelta(self, data)
    end
end

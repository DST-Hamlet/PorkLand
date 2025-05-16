GLOBAL.setfenv(1, GLOBAL)

local Wereness = require("components/wereness")

function Wereness:SetDrainRateFn(fn)
    self.drainratefn = fn
end

local _OnUpdate = Wereness.OnUpdate
function Wereness:OnUpdate(dt, ...)
    if self.drainratefn then
        self.rate = self.drainratefn(self.inst)
    end
    return _OnUpdate(self, dt, ...)
end
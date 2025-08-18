local AddGlobalClassPostConstruct = AddGlobalClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

require("behaviours/useshield")

local _OnStop = UseShield.OnStop
function UseShield:OnStop(...)
    _OnStop(self, ...)
    if self.inst.sg:HasStateTag("hiding") then
        self.inst:PushEvent("exitshield")
    end
end
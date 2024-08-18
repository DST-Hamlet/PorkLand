GLOBAL.setfenv(1, GLOBAL)

local Workable = require("components/workable")

local destroy = Workable.Destroy
function Workable:Destroy(destroyer, ...)
    local ret = { destroy(self, destroyer, ...) }

    if TheWorld.components.cityalarms
        and self.inst.components.citypossession
        and self.inst.components.citypossession.enabled
        and self.inst.components.citypossession.cityID then

        TheWorld.components.cityalarms:TriggerAlarm(self.inst.components.citypossession.cityID, destroyer)
    end

    return unpack(ret)
end

GLOBAL.setfenv(1, GLOBAL)

local Workable = require("components/workable")

local destroy = Workable.Destroy
function Workable:Destroy(destroyer, ...)
    local ret = { destroy(self, destroyer, ...) }

    if  ThWorld.components.cityalarms
        and self.inst.components.citypossession
        and self.inst.components.citypossession.enabled
        and self.inst.components.citypossession.cityID then

        ThWorld.components.cityalarms:ChangeStatus(self.inst.components.citypossession.cityID, true, destroyer)
    end

    return unpack(ret)
end

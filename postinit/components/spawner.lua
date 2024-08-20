GLOBAL.setfenv(1, GLOBAL)

local Spawner = require("components/spawner")

local take_ownership = Spawner.TakeOwnership
function Spawner:TakeOwnership(child, ...)
    local ret = { take_ownership(self, child, ...) }
    if self.inst.components.citypossession and child.components.citypossession then
        child.components.citypossession:SetCity(self.inst.components.citypossession.cityID)
    end
    return unpack(ret)
end

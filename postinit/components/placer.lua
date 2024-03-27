local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Placer = require("components/placer")

local _GetDeployAction = Placer.GetDeployAction
function Placer:GetDeployAction(...)
    local ret = {_GetDeployAction(self, ...)}
    if self.invobject.replica.inventoryitem then
        local deploydistance = self.invobject.replica.inventoryitem:GetDeployDist()
        if deploydistance ~= 0 and ret[1] ~= nil then
            ret[1].distance = deploydistance
        end
    end
    return unpack(ret)
end

GLOBAL.setfenv(1, GLOBAL)

local Deployable = require("components/deployable")

local _CanDeploy = Deployable.CanDeploy
function Deployable:CanDeploy(pt, mouseover, deployer, rot, ...)
    local ret = _CanDeploy(self, pt, mouseover, deployer, rot, ...)
    if self.inst.candeployfn then
        return ret and self.inst.candeployfn(self.inst, pt, mouseover, deployer, rot)
    end
    return ret
end

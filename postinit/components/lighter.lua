GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Lighter = require("components/lighter")

local _Light = Lighter.Light
function Lighter:Light(target, doer, ...)
    if target.components.burnable and target:HasTag("allowinventoryburning") and target:HasTag("INLIMBO") then
        if target.components.burnable ~= nil and not ((target:HasTag("fueldepleted") and not target:HasTag("burnableignorefuel"))) then -- 复制自Lighter:Light
            target.components.burnable:Ignite(nil, self.inst, doer)
            if self.onlight ~= nil then
                self.onlight(self.inst, target)
            end
        end
        target:PushEvent("onlighterlight")
    end
    return _Light(self, target, doer, ...)
end

GLOBAL.setfenv(1, GLOBAL)

local Circler = require("components/circler")

local _OnUpdate = Circler.OnUpdate
function Circler:OnUpdate(dt)
    if self.circleTarget and self.circleTarget:GetIsInInterior() and self.dontfollowinterior then
        -- TODO logic when player goes inside interior
        return
    end
    _OnUpdate(self, dt)
end

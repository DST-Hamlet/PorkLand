GLOBAL.setfenv(1, GLOBAL)

local Widget = require("widgets/widget")

function Widget:Shake(duration, speed, scale)
    if not self.inst.components.uianim then
        self.inst:AddComponent("uianim")
    end
    self.inst.components.uianim:Shake(duration, speed, scale)
end

function Widget:FindChild(fn)
    for child in pairs(self:GetChildren()) do
        if fn(child) then
            return child
        end
    end
end

local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Grue = require("components/grue")

local _AddImmunity = Grue.AddImmunity
function Grue:AddImmunity(source, ...)
    if source == "light" then -- 替换原本的light来源
        return
    end
    return _AddImmunity(self, source, ...)
end

local _OnUpdate = Grue.OnUpdate
function Grue:OnUpdate(...)
    if self.inst:IsInLight() then
        self:AddImmunity("real_light")
    else
        self:RemoveImmunity("real_light")
    end
    return _OnUpdate(self, ...)
end

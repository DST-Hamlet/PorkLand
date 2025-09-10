GLOBAL.setfenv(1, GLOBAL)
local OceanColor = require("components/oceancolor")

--这个组件用于决定背景颜色
local _OnWallUpdate = OceanColor.OnWallUpdate
function OceanColor:OnWallUpdate(dt, ...)
    if TheWorld.has_pl_ocean then
        TheWorld.Map:SetClearColor(0, 0, 0, 1)
        TheWorld.Map:SetOceanTextureBlendAmount(1)
    else
        return _OnWallUpdate(self, dt, ...)
    end
end

local _Initialize = OceanColor.Initialize
function OceanColor:Initialize(has_ocean, ...)
    if TheWorld.has_pl_ocean then
        TheWorld.Map:SetClearColor(0, 0, 0, 1)
    else
        _Initialize(self, has_ocean, ...)
    end
end

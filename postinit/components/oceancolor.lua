GLOBAL.setfenv(1, GLOBAL)
local OceanColor = require("components/oceancolor")

--这个组件用于决定背景颜色
function OceanColor:OnWallUpdate(dt)
    TheWorld.Map:SetClearColor(0, 0, 0, 1)
    TheWorld.Map:SetOceanTextureBlendAmount(1)
end

function OceanColor:Initialize(has_ocean)
    TheWorld.Map:SetClearColor(0, 0, 0, 1)
end

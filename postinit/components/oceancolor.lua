GLOBAL.setfenv(1, GLOBAL)
local OceanColor = require("components/oceancolor")

--这个组件用于决定背景颜色
local _OnWallUpdate = OceanColor.OnWallUpdate
function OceanColor:OnWallUpdate(dt, ...)
    if TheWorld:HasTag("porkland") then
        TheWorld.Map:SetClearColor(0, 0, 0, 1)
        TheWorld.Map:SetOceanTextureBlendAmount(1)
    else
        return _OnWallUpdate(self, dt, ...)
    end
end

local _Initialize = OceanColor.Initialize
function OceanColor:Initialize(has_ocean, ...)
    if TheWorld:HasTag("porkland") then
        TheWorld.Map:SetClearColor(0, 0, 0, 1)

        --修改原版数值，不知道是否应该放这里
        --用于去除小地图陆地边缘的海洋渐变
        TUNING.OCEAN_MINIMAP_SHADER.EDGE_COLOR0 = { 0, 0, 0 }
        TUNING.OCEAN_MINIMAP_SHADER.EDGE_PARAMS0 =
        {
            THRESHOLD = 0,
            HALF_THRESHOLD_RANGE = 0,
        }

        TUNING.OCEAN_MINIMAP_SHADER.EDGE_COLOR1 = { 0, 0, 0 }
        TUNING.OCEAN_MINIMAP_SHADER.EDGE_PARAMS1 =
        {
            THRESHOLD = 0,
            HALF_THRESHOLD_RANGE = 0,
        }

        TUNING.OCEAN_MINIMAP_SHADER.EDGE_SHADOW_COLOR = { 0, 0, 0 }
        TUNING.OCEAN_MINIMAP_SHADER.EDGE_SHADOW_PARAMS =
        {
            THRESHOLD = 0,
            HALF_THRESHOLD_RANGE = 0,
            UV_OFFSET_X = 0,
            UV_OFFSET_Y = 0,
        }

        TUNING.OCEAN_MINIMAP_SHADER.EDGE_FADE_PARAMS =
        {
            THRESHOLD = 0,
            HALF_THRESHOLD_RANGE = 0,
            MASK_INSET = 0,
        }

        TUNING.OCEAN_MINIMAP_SHADER.EDGE_NOISE_PARAMS =
        {
            UV_SCALE = 0,
        }
    else
        _Initialize(self, has_ocean, ...)
    end
end

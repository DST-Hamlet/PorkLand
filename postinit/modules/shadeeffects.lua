GLOBAL.setfenv(1, GLOBAL)

if TheNet:IsDedicated() then
    local nullfunc = function() end
    SpawnRainforestCanopy = nullfunc
    DespawnRainforestCanopy = nullfunc
    ShadeRendererEnabled = nil
    return
end

ShadeTypes.RainforestCanopy = ShadeRenderer:CreateShadeType()

ShadeRenderer:SetShadeMaxRotation(ShadeTypes.RainforestCanopy, TUNING.RAINFOREST_CANOPY_MAX_ROTATION)
ShadeRenderer:SetShadeRotationSpeed(ShadeTypes.RainforestCanopy, TUNING.RAINFOREST_CANOPY_ROTATION_SPEED)

ShadeRenderer:SetShadeMaxTranslation(ShadeTypes.RainforestCanopy, TUNING.RAINFOREST_CANOPY_MAX_TRANSLATION)
ShadeRenderer:SetShadeTranslationSpeed(ShadeTypes.RainforestCanopy, TUNING.RAINFOREST_CANOPY_TRANSLATION_SPEED)

ShadeRenderer:SetShadeTexture(ShadeTypes.RainforestCanopy, "images/tree.tex")

function SpawnRainforestCanopy(x, z)
    return ShadeRenderer:SpawnShade(ShadeTypes.RainforestCanopy, x, z, math.random() * 360, TUNING.RAINFOREST_CANOPY_SCALE)
end

function DespawnRainforestCanopy(id)
    ShadeRenderer:RemoveShade(ShadeTypes.RainforestCanopy, id)
end

local _ShadeEffectUpdate = ShadeEffectUpdate
function ShadeEffectUpdate(dt, ...)
    local r, g, b = TheSim:GetAmbientColour()

    ShadeRenderer:SetShadeStrength(ShadeTypes.RainforestCanopy, Lerp(TUNING.RAINFOREST_CANOPY_MIN_STRENGTH, TUNING.RAINFOREST_CANOPY_MAX_STRENGTH, ((r + g + b) / 3) / 255))
    return _ShadeEffectUpdate(dt, ...)
end

ShadeRendererEnabled = false
local _EnableShadeRenderer = EnableShadeRenderer
function EnableShadeRenderer(enable, ...)

    ShadeRendererEnabled = enable
    local _world = TheWorld
    if _world ~= nil and _world.components.canopymanager ~= nil then
        _world.components.canopymanager:SetEnabled(enable)
    end

    return _EnableShadeRenderer(enable, ...)
end

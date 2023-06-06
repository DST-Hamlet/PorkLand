local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

if TheNet:IsDedicated() then
    local nullfunc = function() end
    SpawnRainforestCanopy = nullfunc
    DespawnRainforestCanopy = nullfunc
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

-- Ugh, unlike literally EVERY other shader, shadereffects runs AFTER all other shaders including modshader postinits -Half
IAENV.AddSimPostInit(function()
    local _ShadeEffectUpdate = ShadeEffectUpdate
    function ShadeEffectUpdate(dt, ...)
        local r, g, b = TheSim:GetAmbientColour()
    
        ShadeRenderer:SetShadeStrength(ShadeTypes.RainforestCanopy, Lerp(TUNING.RAINFOREST_CANOPY_MIN_STRENGTH, TUNING.RAINFOREST_CANOPY_MAX_STRENGTH, ((r + g + b) / 3) / 255))
        return _ShadeEffectUpdate(dt, ...)
    end

    -- Nope doesnt work, ugh what a pain im going to bully zark into allowing modshader postinits for this!!!
    -- local _EnableShadeRenderer = EnableShadeRenderer
    -- function EnableShadeRenderer(enable, ...)

    --     local _world = TheWorld
    --     if _world ~= nil and _world.components.canopymanager ~= nil then
    --         _world.components.canopymanager:SetEnabled(enable)
    --     end

    --     return _EnableShadeRenderer(enable, ...)
    -- end
end)

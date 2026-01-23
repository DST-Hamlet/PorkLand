GLOBAL.setfenv(1, GLOBAL)

------------AnimShades------------

AnimShadeRenderers = {}

function AddAnimShadeRenderer(name, tex, length)
    AnimShadeRenderers[name] = {
        length = length,
        datas = {},
    }
    for i = 0, length do
        AnimShadeRenderers[name]["datas"][i] = {}

        local typeid = ShadeRenderer:CreateShadeType()
        AnimShadeRenderers[name]["datas"][i].typeid = typeid

        local realframe = i + 1
        local path = tex..tostring(realframe)..".tex"
        AnimShadeRenderers[name]["datas"][i].texpath = path
    end
end

function SpawnAnimShadeRenderer(name, frame, pos, rotation, scale)
    if not AnimShadeRenderers[name]["datas"][frame].settexture then
        ShadeRenderer:SetShadeTexture(AnimShadeRenderers[name]["datas"][frame].typeid, resolvefilepath(AnimShadeRenderers[name]["datas"][frame].texpath))
        AnimShadeRenderers[name]["datas"][frame].settexture = true
    end
    local x, _, z = pos:Get()
    return ShadeRenderer:SpawnShade(AnimShadeRenderers[name]["datas"][frame].typeid, x, z, rotation, scale or 1)
end

function RemoveAnimShadeRenderer(name, frame, id)
    ShadeRenderer:RemoveShade(AnimShadeRenderers[name]["datas"][frame].typeid, id)
end

AddAnimShadeRenderer("roc_shadow_shadow", "images/shade_anim/roc_shadow/shadow/shadow-", 0)
AddAnimShadeRenderer("roc_shadow_ground_pre", "images/shade_anim/roc_shadow/ground_pre/ground_pre-", 42)
AddAnimShadeRenderer("roc_shadow_ground_loop", "images/shade_anim/roc_shadow/ground_loop/ground_loop-", 0)
AddAnimShadeRenderer("roc_shadow_ground_pst", "images/shade_anim/roc_shadow/ground_pst/ground_pst-", 54)
AddAnimShadeRenderer("roc_shadow_shadow_flap_loop", "images/shade_anim/roc_shadow/shadow_flap_loop/shadow_flap_loop-", 37)

local current_mult = 1
local target_mult = 1

function SetShadeStrengthMult(val)
    target_mult = val
end

local _ShadeEffectUpdate = ShadeEffectUpdate
function ShadeEffectUpdate(dt, ...)
    local r, g, b = TheSim:GetAmbientColour()

    current_mult = Lerp(current_mult, target_mult, dt)
    ShadeRenderer:SetShadeStrength(ShadeTypes.RainforestCanopy, current_mult * Lerp(TUNING.RAINFOREST_CANOPY_MIN_STRENGTH, TUNING.RAINFOREST_CANOPY_MAX_STRENGTH, ((r + g + b) / 3) / 255))

    for name, shadeanim in pairs(AnimShadeRenderers) do
        for _, framedata in pairs(shadeanim["datas"]) do
            ShadeRenderer:SetShadeStrength(framedata.typeid, current_mult * Lerp(TUNING.ANIMSHADE_MIN_STRENGTH, TUNING.ANIMSHADE_MAX_STRENGTH, ((r + g + b) / 3) / 255))
        end
    end
    return _ShadeEffectUpdate(dt, ...)
end


------------CanopyShades------------

ShadeTypes.RainforestCanopy = ShadeRenderer:CreateShadeType() -- 越晚创建的ShadeType在光照贴图计算中的覆盖优先级越高

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

ShadeRendererEnabled = false
local _EnableShadeRenderer = EnableShadeRenderer
function EnableShadeRenderer(enable, ...)

    ShadeRendererEnabled = enable
    local _world = TheWorld
    if _world ~= nil and _world.components.canopymanager ~= nil then
        _world.components.canopymanager:SetEnabled(enable)
    end

    -- return _EnableShadeRenderer(enable, ...)
end

if TheNet:IsDedicated() then
    local nullfunc = function() end
    SpawnAnimShadeRenderer = nullfunc
    RemoveAnimShadeRenderer = nullfunc

    SpawnRainforestCanopy = nullfunc
    DespawnRainforestCanopy = nullfunc
    ShadeRendererEnabled = nil
    return
end

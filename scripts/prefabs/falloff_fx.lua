local TEXTURE = "levels/tiles/falloff.tex"
local SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME = "pl_falloffcolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_falloffscaleenvelope"

local MAX_LIFETIME = 1e10

local assets =
{
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER),
}

--------------------------------------------------------------------------

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    { 1, 1, 1, 1 } },
            { 1,    { 1, 1, 1, 1 } },
        }
    )

    local width, height = 1.171875 * 4 * 1.0025 * 1.0666667, 1.171875 * 4 * 2 * 1.0666667
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { width, height } },
            { 1,    { width, height } },
        }
    )

    InitEnvelope = nil
end

--------------------------------------------------------------------------

local function fn_fx()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    if InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetMaxNumParticles(0, 10000)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetUVFrameSize(0, 0.234375, 0.46875)
    effect:SetLayer(0, LAYER_BELOW_GROUND)
    effect:SetSortOrder(0, 1)
    effect:EnableDepthTest(0, true)
    effect:EnableDepthWrite(0, true)
    effect:SetKillOnEntityDeath(0, true)
    effect:SetSpawnVectors(0,
        1, 0, 0,
        0, 1, 0)

    return inst
end

local function ClearVFX(inst)
    for k, v in pairs(inst.child_effects) do
        v.VFXEffect:ClearAllParticles(0)
    end
end

local TYPE_UV = {
    [1] = {0.0078125, 0.515625},
    [2] = {0.2578125, 0.515625},
    [3] = {0.5078125, 0.515625},
    [4] = {0.7578125, 0.515625},
    [5] = {0.0078125, 0.015625},
    [6] = {0.2421875, 0.015625},
}

local function SpawnFalloff(inst, pos, angle, type)
    inst.child_effects[angle].Transform:SetPosition(pos.x, pos.y, pos.z)

    inst.child_effects[angle].VFXEffect:AddParticleUV(
        0,
        MAX_LIFETIME,           -- lifetime
        0, -4, 0,         -- position
        0, 0, 0,          -- velocity
        TYPE_UV[type][1], TYPE_UV[type][2]        -- uvoffset_x, uvoffset_y        -- uv offset
    )
end

local ANGLE_TO_VECTOR = {
    [0] = {0, 0, 1},
    [90] = {1, 0, 0},
    [180] = {0, 0, -1},
    [270] = {-1, 0, 0},
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.child_effects = {}
    for k, data in pairs(ANGLE_TO_VECTOR) do
        inst.child_effects[k] = SpawnPrefab("falloff_fx_child")
        inst.child_effects[k].VFXEffect:SetSpawnVectors(0,
        data[1], data[2], data[3],
        0, 1, 0)
    end

    inst:ListenForEvent("onremove", function()    
        for k, v in pairs(inst.child_effects) do
            v:Remove()
            inst.child_effects[k] = nil
        end
    end)

    inst.SpawnFalloff = SpawnFalloff
    inst.ClearVFX = ClearVFX

    return inst
end

return Prefab("falloff_fx_child", fn_fx, assets),
    Prefab("falloff_fx", fn, assets)
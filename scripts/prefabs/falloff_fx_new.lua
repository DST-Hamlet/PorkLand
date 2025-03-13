local TEXTURE = "levels/tiles/falloff.tex"
local SHADER = "shaders/falloff_particle.ksh"

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

    local width, height = 1.171875 * 4 * 1.0025, 1.171875 * 4 * 2
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

local function fn()
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
    effect:SetUVFrameSize(0, 0.25, 0.5)
    effect:SetLayer(0, LAYER_BELOW_GROUND)
    effect:SetSortOrder(0, -1)
    effect:EnableDepthTest(0, true)
    effect:EnableDepthWrite(0, true)
    effect:SetSpawnVectors(0,
        1, 0, 0,
        0, 1, 0)

    return inst
end

local function ClearVFX(inst)
    for k, v in pairs(inst.effects) do
        v.VFXEffect:ClearAllParticles(0)
    end
end

local function SpawnFalloff(inst, pos, angle)
    inst.effects[angle].Transform:SetPosition(pos.x, pos.y, pos.z)

    inst.effects[angle].VFXEffect:AddParticleUV(
        0,
        MAX_LIFETIME,           -- lifetime
        0, -4, 0,         -- position
        0, 0, 0,          -- velocity
        0, 0        -- uvoffset_x, uvoffset_y        -- uv offset
    )
end

local ANGLE_TO_VECTOR = {
    [0] = {0, 0, 1},
    [90] = {1, 0, 0},
    [180] = {0, 0, -1},
    [270] = {-1, 0, 0},
}

local function fn_parent()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.effects = {}
    for k, data in pairs(ANGLE_TO_VECTOR) do
        inst.effects[k] = SpawnPrefab("falloff_fx_child")
        inst.effects[k].VFXEffect:SetSpawnVectors(0,
        data[1], data[2], data[3],
        0, 1, 0)
    end

    inst.SpawnFalloff = SpawnFalloff
    inst.ClearVFX = ClearVFX

    return inst
end

return Prefab("falloff_fx_child", fn, assets),
    Prefab("falloff_fx_parent", fn_parent, assets)
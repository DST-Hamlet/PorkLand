local TEXTURE = "images/cloud/fog_cloud_long.tex"
local SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME = "pl_cloudcolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_cloudscaleenvelope"

local MAX_LIFETIME = 1e10

local assets =
{
    Asset("IMAGE", "images/cloud/fog_cloud_long.tex"),
}

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    { 1, 1, 1, 1 } },
            { 1,    { 1, 1, 1, 1 } },
        }
    )

    local width, height = 1.171875 * 1.8, 1.171875 * 1.8
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { width, height } },
            { 1,    { width, height } },
        }
    )

    InitEnvelope = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:SetCanSleep(false)
    --[[Non-networked entity]]

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

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
    effect:SetLayer(0, LAYER_BELOW_GROUND)
    effect:SetSortOrder(0, -2)
    effect:EnableDepthTest(0, true)
    effect:SetKillOnEntityDeath(0, true)

    return inst
end

return Prefab("cloud_fx", fn, assets)

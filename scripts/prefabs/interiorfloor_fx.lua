local TEXTURE = "levels/textures/interiors/shop_floor_woodmetal.tex"
local SHADER = "shaders/interior_wall_particle.ksh"

local COLOUR_ENVELOPE_NAME = "pl_floorcolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_floorscaleenvelope" -- for 512x512
local SCALE_ENVELOPE_NAME2 = "pl_floorcolourenvelope2" -- for 1024x1024
local SCALE_ENVELOPE_NAME3 = "pl_floorcolourenvelope3" -- for 512x512/bigger

local assets =
{
    Asset("SHADER", SHADER),
}

local function InitEnvelopes()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    { 1, 1, 1, 1 } },
            { 1,    { 1, 1, 1, 1 } },
        }
    )

    local SCALE = 2.9296875 -- 3000/1024
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { SCALE, SCALE } },
            { 1,    { SCALE, SCALE } },
        }
    )

    local SCALE2 = 2.05078125
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME2,
        {
            { 0,    { SCALE2, SCALE2 } },
            { 1,    { SCALE2, SCALE2 } },
        }
    )

    local SCALE3 = 5.859375
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME3,
        {
            { 0,    { SCALE3, SCALE3 } },
            { 1,    { SCALE3, SCALE3 } },
        }
    )

    InitEnvelopes = nil
end

local MAX_LIFETIME = 1e10
local function emit_fn(inst, effect)
    local w = inst.w_percent or 1
    local h = inst.h_percent or 1
    if w < .01 or h < .01 then
        return
    end
    effect:SetUVFrameSize(0, w, h)
    effect:AddParticleUV(
        0,
        MAX_LIFETIME,   -- lifetime
        0, 0, 0, -- position
        0, 0, 0, -- velocity
        0, 1-h   -- uv offset
    )
end

local function GetTexture(inst)
    return inst.texture
end

local function SetTexture(inst, texture)
    inst.texture = texture
    if not TheNet:IsDedicated() then
        inst.VFXEffect:SetRenderResources(0, resolvefilepath(texture), resolvefilepath(SHADER))
    end
    if texture:find("noise_woodfloor") then -- 特殊情况
        inst.VFXEffect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME2)
    elseif texture:find("batcave_floor") then
        inst.VFXEffect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME3)
    elseif texture:find("floor") then
        inst.VFXEffect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()


    --[[Non-networked entity]]

    inst.persists = false

    inst:AddTag("FX")
    inst:AddTag("pl_interiorwall_fx")

    if InitEnvelopes ~= nil then
        InitEnvelopes()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)

    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetMaxNumParticles(0, 1)
    effect:SetSortOrder(0, -1)
    effect:SetSortOffset(0, -1)
    effect:SetLayer(0, LAYER_GROUND)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetSpawnVectors(0,
        0, 0, 1,
        -1, 0, 0
    )
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME3)
    effect:SetUVFrameSize(0, 1, 1)
    effect:SetKillOnEntityDeath(0, true)
    effect:EnableDepthTest(0, true)

    inst.SetTexture = SetTexture
    inst.GetTexture = GetTexture
    inst.SetTexturePath = inst.SetTexture

    local updateFunc = function()
        if inst.texture ~= nil then
            emit_fn(inst, effect)
        end
    end

    EmitterManager:AddEmitter(inst, nil, updateFunc)

    return inst
end

return Prefab("interiorfloor_fx", fn, assets)

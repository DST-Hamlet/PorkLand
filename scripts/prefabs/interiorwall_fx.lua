local TEXTURE = "levels/textures/interiors/antcave_wall_rock.tex"
local SHADER = "shaders/interior_wall_particle.ksh"

local COLOUR_ENVELOPE_NAME = "pl_wallcolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_wallscaleenvelope"
local SCALE_ENVELOPE_NAME2 = "pl_wallscaleenvelope2"
local SCALE_ENVELOPE_NAME3 = "pl_wallscaleenvelope3"
local SCALE_ENVELOPE_NAME4 = "pl_wallscaleenvelope4"

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

    local width, height = 1.46484375, 1.46484375 * 1.08
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { width, height } },
            { 1,    { width, height } },
        }
    )

    local width2, height2 = 2.9296875, 2.9296875 * 1.08 -- 3000/1024
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME2,
        {
            { 0,    { width2, height2 } },
            { 1,    { width2, height2 } },
        }
    )

    local width3, height3 = 2.9296875, 1.611328125 * 1.08 -- 2, 1.1
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME3,
        {
            { 0,    { width3, height3 } },
            { 1,    { width3, height3 } },
        }
    )

    local width4, height4 = 2.197265625, 1.8310546875 * 1.08 -- 1.5, 1
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME4,
        {
            { 0,    { width4, height4 } },
            { 1,    { width4, height4 } },
        }
    )


    InitEnvelopes = nil
end

local MAX_LIFETIME = 1e10
local function emit_fn(inst, effect)
    if not inst.is_x then
        effect:SetSpawnVectors(0,
            0, 0, 1,
            -.5, 1, 0)
    elseif inst.is_left then
        effect:SetSpawnVectors(0,
            1, 0, 0,
            -.5, 1, 0)
    else
        effect:SetSpawnVectors(0,
            1, 0, 0,
            -.5, 1, 0)
    end
    if inst.w_percent ~= 1 then
        effect:SetUVFrameSize(0, inst.w_percent, 1)
    end

    effect:AddParticleUV(
        0,
        MAX_LIFETIME,   -- lifetime
        0, 0, 0,
        0, 0, 0,            -- velocity
        -- uvoffset_x, uvoffset_y        -- uv offset
        0, 0
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
    if texture:find("wall_royal_high") then -- 特殊情况
        inst.VFXEffect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME3)
    elseif texture:find("batcave_wall_rock") then
        inst.VFXEffect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME2)
    elseif texture:find("antcave_wall_rock") then
        inst.VFXEffect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME4)
    else
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
    inst:AddTag("NOBLOCK")

    if InitEnvelopes ~= nil then
        InitEnvelopes()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)

    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetMaxNumParticles(0, 1)
    effect:SetSortOffset(0, 0)
    effect:SetLayer(0, LAYER_GROUND)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetSpawnVectors(0,
        0, 0, 1,
        0, 1, 0
    )
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetUVFrameSize(0, 1, 1)
    effect:SetKillOnEntityDeath(0, true)
    effect:EnableDepthTest(0, true)

    inst.SetTexture = SetTexture
    inst.GetTexture = GetTexture
    inst.w_percent = 1

    inst:SetTexture(TEXTURE)

    local updateFunc = function()
        if inst.texture ~= nil then
            emit_fn(inst, effect)
        end
    end

    EmitterManager:AddEmitter(inst, nil, updateFunc)

    return inst
end

return Prefab("interiorwall_fx", fn, assets)

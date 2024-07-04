local TEXTURE = "levels/textures/interiors/antcave_wall_rock.tex"
local SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME = "pl_wallcolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_wallscaleenvelope"
local SCALE_ENVELOPE_NAME2 = "pl_wallscaleenvelope2"

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

    local width, height = 1.475, 1.475
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { width, height } },
            { 1,    { width, height } },
        }
    )

    local width2, height2 = 2.7, 2.7
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME2,
        {
            { 0,    { width2, height2 } },
            { 1,    { width2, height2 } },
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
    -- local uvoffset_x, uvoffset_y = Lerp(0.5,0, inst.uv_x or 0), Lerp(0.5,0, inst.uv_y or 1)   --Asura: here you can change position of cutting point use 1 or 0
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
    if texture:find("batcave_wall_rock") then
        inst.VFXEffect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME2)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    if TheNet:GetIsClient() then
        inst.entity:AddClientSleepable()
    end

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

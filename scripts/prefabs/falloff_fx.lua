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

    local width, height = 1.171875 * 4 * 1.0666667, 1.171875 * 4 * 2 * 1.0666667
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

local spawn_vector = {1, 0, 0}
local falloff_fx_datas = {}

local function fn_fx()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("FX")
    inst:AddTag("CLASSIFIED")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    if InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(GetTableSize(falloff_fx_datas))
    for name, data in pairs(falloff_fx_datas) do
        local i = data.id
        effect:SetRenderResources(i, resolvefilepath(data.texture), resolvefilepath(SHADER))
        effect:SetMaxNumParticles(i, 10000)
        effect:SetMaxLifetime(i, MAX_LIFETIME)
        effect:SetColourEnvelope(i, COLOUR_ENVELOPE_NAME)
        effect:SetScaleEnvelope(i, SCALE_ENVELOPE_NAME)
        effect:SetUVFrameSize(i, 0.234375, 0.46875)
        effect:SetLayer(i, LAYER_BELOW_OCEAN)
        effect:SetSortOrder(i, -3)
        effect:EnableDepthTest(i, true)
        effect:EnableDepthWrite(i, true)
        effect:SetKillOnEntityDeath(i, true)
        effect:SetSpawnVectors(i,
            spawn_vector[1], spawn_vector[2], spawn_vector[3],
            0, 1, 0)
    end

    return inst
end

local ANGLE_TO_VECTOR = {
    [0] = {0, 0, 1},
    [90] = {1, 0, 0},
    [180] = {0, 0, -1},
    [270] = {-1, 0, 0},
}

local function InitVFX(inst, faloff_datas)
    falloff_fx_datas = faloff_datas
    for k, data in pairs(ANGLE_TO_VECTOR) do
        spawn_vector = data
        inst.child_effects[k] = SpawnPrefab("falloff_fx_child")
        spawn_vector = {1, 0, 0}
    end
    falloff_fx_datas = {}
end

local function ClearFalloff(inst, index)
    for k, v in pairs(inst.child_effects) do
        v.VFXEffect:ClearAllParticles(index)
    end
end

local VARIANT_UV = {
    [1] = {0.0078125, 0.515625},
    [2] = {0.2578125, 0.515625},
    [3] = {0.5078125, 0.515625},
    [4] = {0.7578125, 0.515625},
    [5] = {0.0078125, 0.015625},
    [6] = {0.2421875, 0.015625},
}

local function SpawnFalloff(inst, index, pos, angle, variant)
    inst.child_effects[angle].VFXEffect:AddParticleUV(
        index,
        MAX_LIFETIME,           -- lifetime
        pos.x, pos.y -4, pos.z,         -- position
        0, 0, 0,          -- velocity
        VARIANT_UV[variant][1], VARIANT_UV[variant][2]        -- uvoffset_x, uvoffset_y        -- uv offset
    )
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("FX")
    inst:AddTag("CLASSIFIED")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.child_effects = {}

    inst:ListenForEvent("onremove", function()
        for k, v in pairs(inst.child_effects) do
            v:Remove()
            inst.child_effects[k] = nil
        end
    end)

    inst.InitVFX = InitVFX
    inst.SpawnFalloff = SpawnFalloff
    inst.ClearFalloff = ClearFalloff

    return inst
end

return Prefab("falloff_fx_child", fn_fx, assets),
    Prefab("falloff_fx", fn, assets)

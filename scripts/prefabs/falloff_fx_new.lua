local TEXTURE = "levels/textures/interiors/antcave_wall_rock.tex"
local SHADER = "shaders/interior_wall_particle.ksh"

local COLOUR_ENVELOPE_NAME = "pl_falloffcolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_falloffscaleenvelope"

local assets =
{
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER),
}

--------------------------------------------------------------------------

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()
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

    InitEnvelope = nil
    IntColour = nil
end



--------------------------------------------------------------------------

local MAX_LIFETIME = 60
local MIN_LIFETIME = 30

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

    if InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetMaxNumParticles(0, 1000)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    --effect:SetLayer(0, LAYER_BACKGROUND)
    effect:EnableDepthTest(0, true)
    effect:EnableDepthWrite(0, true)
    effect:SetSpawnVectors(0,
        1, 0, 0,
        0, 1, 0)

    -----------------------------------------------------

    local rng = math.random
    local tick_time = TheSim:GetTickTime()

    local desired_particles_per_second = 0--300
    inst.particles_per_tick = desired_particles_per_second * tick_time

    inst.num_particles_to_emit = inst.particles_per_tick

    local function emit_fn(inst, pos)
        inst.Transform:SetPosition(pos.x, pos.y, pos.z)
        local lifetime = MIN_LIFETIME + (MAX_LIFETIME - MIN_LIFETIME) * UnitRand()

        effect:AddParticle(
            0,
            lifetime,           -- lifetime
            0, 2, 0,         -- position
            0, 0, 0          -- velocity
       )
    end

    inst.emit_fn = emit_fn

    local function updateFunc()
        -- emit_fn()
    end

    inst.time = 0
    inst.interval = 0

    EmitterManager:AddEmitter(inst, nil, updateFunc)

    function inst:PostInit()
        local dt = 1 / 30
        local t = MAX_LIFETIME
        while t > 0 do
            t = t - dt
            updateFunc()
            effect:FastForward(0, dt)
        end
    end

    return inst
end

return Prefab("falloff_fx_new", fn, assets)

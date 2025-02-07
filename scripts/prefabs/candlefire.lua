local TEXTURE = "fx/torchfire.tex"
local SHADER = "shaders/particle.ksh"
local COLOUR_ENVELOPE_NAME = "firecolourenvelope"
local SCALE_ENVELOPE_NAME = "firescaleenvelope"

local assets =
{
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER),
}

local max_scale = 3

local function IntColour(r, g, b, a)
    return {r / 255, g / 255, b / 255, a / 255}
end

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME, {
        {0,     IntColour( 187, 111, 60, 128)},
        {0.49,  IntColour( 187, 111, 60, 128)},
        {0.5,   IntColour( 255, 255, 0,  128)},
        {0.51,  IntColour( 255, 30,  56, 128)},
        {0.75,  IntColour( 255, 30,  56, 128)},
        {1,     IntColour( 255, 7,   28, 0)},
    })

    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME, {
        {0,     {max_scale * 0.5, max_scale}},
        {1,     {max_scale * 0.5 * 0.5, max_scale * 0.5}},
    })

    InitEnvelope = nil
    IntColour = nil
end

local MAX_LIFETIME = 0.3

local emit_fn = function(effect, emitter_fn)
    local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
    local lifetime = MAX_LIFETIME * (0.9 + UnitRand() * 0.1)

    local px, py, pz = emitter_fn()
    px = px - 0.1
    py = py + 0.25 -- the 0.2 is to offset the flame particles upwards a bit so they can be used on a torch

    local uv_offset = math.random(0, 3) * 0.25

    effect:AddParticleUV(
        0,
        lifetime,           -- lifetime
        px, py, pz,         -- position
        vx, vy, vz,         -- velocity
        uv_offset, 0        -- uv offset
    )
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetIntensity(0.75)
    inst.Light:SetColour(197 / 255, 197 / 255, 50 / 255)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(1.5)
    inst.Light:Enable(true)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    inst.persists = false

    --Dedicated server does not need to spawn local particle fx
    if TheNet:IsDedicated() then
        return inst
    elseif InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)

    effect:SetRenderResources(0, TEXTURE, SHADER)
    effect:SetMaxNumParticles(0, 64)
    effect:SetUVFrameSize(0, 0.25, 1)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.Additive)
    effect:EnableBloomPass(0, true)
    effect:SetDragCoefficient(0, 0.4)

    local tick_time = TheSim:GetTickTime()
    local desired_particles_per_second = 64
    local particles_per_tick = desired_particles_per_second * tick_time
    local num_particles_to_emit = 1

    local sphere_emitter = CreateSphereEmitter(0.05)

    EmitterManager:AddEmitter(inst, nil, function()
        num_particles_to_emit = num_particles_to_emit + particles_per_tick
        while num_particles_to_emit > 1 do
            emit_fn(effect, sphere_emitter)
            num_particles_to_emit = num_particles_to_emit - 1
        end
    end )

    inst:DoPeriodicTask(FRAMES, function()
        if TheWorld.net ~= nil and TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetIsWindy() then
            local windangle = TheWorld.net.components.plateauwind:GetWindAngle() * DEGREES
            local windspeed = TheWorld.net.components.plateauwind:GetWindSpeed() * 6
            inst.VFXEffect:SetAcceleration(0, math.cos(windangle) * windspeed, 0, -math.sin(windangle) * windspeed)
        end
    end)

    return inst
end

return Prefab("candlefire", fn, assets)

local waveassets =
{
    Asset("ANIM", "anim/wave_ripple.zip"),
}

local rogueassets =
{
    Asset("ANIM", "anim/wave_rogue.zip"),
}

local function wetanddamage(inst, other)
    -- Get wet and take damage
    if other and other.components.driver and other.components.driver.vehicle then
        local vehicle = other.components.driver.vehicle
        if vehicle.components.boathealth then
            vehicle.components.boathealth:DoDelta(inst.hitdamage, "wave")
        end
    end

    if other and other.components.moisture then
        if other.components.inventory and other.components.inventory:IsWaterproof() then
            -- We are protected!
            return
        end

        local hitmoisturerate, waterproofMultiplier = 1, 1

        if other.components.driver and other.components.driver.vehicle and other.components.driver.vehicle.components.drivable then
            hitmoisturerate = other.components.driver.vehicle.components.drivable:GetHitMoistureRate()
        end

        if other.components.inventory then
            waterproofMultiplier = 1 - math.min(other.components.inventory:GetWaterproofness(), 1)
        end

        local delta = inst.hitmoisture * hitmoisturerate * waterproofMultiplier

        if delta > 0 then
            other.components.moisture:DoDelta(delta)
        end
    end
end

local function splash(inst)
    local splash_water = SpawnPrefab("splash_water")
    local x, y, z = inst.Transform:GetWorldPosition()
    splash_water.Transform:SetPosition(x, y, z)

    inst:Remove()
end

local function OnCollideRipple(inst, other)
    if not other or not other:IsValid() then
        return
    end

    if other:HasTag("player") then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wave_break")

        local player_angle =  other.Transform:GetRotation()
        if player_angle < 0 then player_angle = player_angle + 360 end

        local wave_angle = inst.Transform:GetRotation()
        if wave_angle < 0 then wave_angle = wave_angle + 360 end

        local angle_difference = math.abs(wave_angle - player_angle)

        if angle_difference > 180 then angle_difference = 360 - angle_difference end

        local is_moving = other.sg:HasStateTag("moving")
        if angle_difference < TUNING.WAVE_BOOST_ANGLE_THRESHOLD and is_moving then
            --Do boost
            other:PushEvent("boostbywave", {position = inst.Transform:GetWorldPosition(), velocity = inst.Physics:GetVelocity(), boost = nil}) -- boost param is for walani
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wave_boost")
        else
            wetanddamage(inst, other)
        end

        splash(inst)
    elseif other:HasTag("waveobstacle") then
        -- other.components.waveobstacle:OnCollide(inst) This is only used for mangroves
        wetanddamage(inst, other)
        splash(inst)
    end
end

local function OnCollideRogue(inst, other)
    if not other or not other:IsValid() then
        return
    end

    if other:HasTag("player") then
        wetanddamage(inst, other)
        splash(inst)
    elseif other:HasTag("waveobstacle") then
        -- other.components.waveobstacle:OnCollide(inst)
        wetanddamage(inst, other)
        splash(inst)
    end
end

-- Check if I'm about to hit land
local function CheckGround(inst, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    local vx, vy, vz = inst.Physics:GetVelocity()

    local checkx = x + vx
    local checky = y
    local checkz = z + vz

    if not TheWorld.Map:IsOceanTileAtPoint(checkx, checky, checkz) then
        splash(inst)
    end
end

local function OnSave(inst, data)
    if inst and data then
        data.speed = inst.Physics:GetMotorSpeed()
        data.angle = inst.Transform:GetRotation()
        if inst.sg and inst.sg.currentstate and inst.sg.currentstate.name then
            data.state = inst.sg.currentstate.name
        end
    end
end

local function OnLoad(inst, data)
    if inst and data then
        inst.Transform:SetRotation(data.angle or 0)
        inst.Physics:SetMotorVel(data.speed or 0, 0, 0)
        if inst.sg and data.state then
            inst.sg:GoToState(data.state)
        end
    end
end

local function activate_collision(inst)
    inst.Physics:SetCollides(false) --Still will get collision callback, just not dynamic collisions.
    inst.Physics:SetCollisionGroup(COLLISION.WAVES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
end

local function OnRemove(inst)
    if inst and inst.soundloop then
        inst.SoundEmitter:KillSound(inst.soundloop)
    end
end

local function RipplePostinit(inst)
    inst.hitdamage = -TUNING.WAVE_HIT_DAMAGE
    inst.hitmoisture = TUNING.WAVE_HIT_MOISTURE

    inst.soundrise = "small"
end

local function RoguePostinit(inst)
    inst.hitdamage = -TUNING.ROGUEWAVE_HIT_DAMAGE
    inst.hitmoisture = TUNING.ROGUEWAVE_HIT_MOISTURE

    inst.idle_time = 1

    inst.soundrise = "large"
    inst.soundloop = "large_LP"
    inst.soundtidal = "tidal_wave"

    inst:ListenForEvent("onremove", OnRemove)
end

local function MakeWave(build, collision_callback, master_postinit)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddAnimState()

        inst.AnimState:SetBuild(build)
        inst.AnimState:SetBank(build)
        inst.Transform:SetFourFaced()

        inst.entity:AddPhysics()
        inst.Physics:SetSphere(1)
        inst.Physics:ClearCollisionMask()

        inst:AddTag("FX")
        inst:AddTag("wave")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        if master_postinit then
            master_postinit(inst)
        end

        inst.Physics:SetCollisionCallback(collision_callback)

        inst:SetStateGraph("SGpl_wave")
        inst.checkgroundtask = inst:DoPeriodicTask(0.5, CheckGround)

        inst.activate_collision = activate_collision

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnEntitySleep = inst.Remove
        inst.done = false

        return inst
    end

    return fn
end


return Prefab("wave_ripple", MakeWave("wave_Ripple", OnCollideRipple, RipplePostinit), waveassets),
       Prefab("rogue_wave", MakeWave("wave_rogue", OnCollideRogue, RoguePostinit), rogueassets)

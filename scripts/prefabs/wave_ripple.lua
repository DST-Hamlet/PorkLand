local wave_assets =
{
    Asset("ANIM", "anim/pl_wave_ripple.zip"),
}

local rogue_assets =
{
    Asset("ANIM", "anim/wave_rogue.zip"),
}

local SPLASH_WETNESS = 9
local function WetAndDamage(inst, other)
    -- Get wet and take damage
    if other and other.components.sailor then
        local boat = other.components.sailor:GetBoat()
        if boat and boat.components.boathealth then
            boat.components.boathealth:DoDelta(inst.hitdamage or -TUNING.ROGUEWAVE_HIT_DAMAGE, "wave")
        end
    end

    local pos = inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 4)
    for _, v in pairs(ents) do
        local moisture = v.components.moisture
        if moisture ~= nil then
            local waterproofness = moisture:GetWaterproofness()
            moisture:DoDelta((inst.hitmoisture or SPLASH_WETNESS) * (1 - waterproofness))
        end
    end
end

local function Splash(inst, isboost)
    local fxname = "splash_water"
    if isboost then
        fxname = "splash_water_boost"
    end
    local splash_water = SpawnPrefab(fxname)
    local x, y, z = inst.Transform:GetWorldPosition()
    splash_water.Transform:SetPosition(x, y, z)

    inst:Remove()
end

local function OnCollideRipple(inst, other)
    if not other or not other:IsValid() then
        return
    end

    if other:HasTag("player") then
        local player_angle =  other.Transform:GetRotation()
        if player_angle < 0 then player_angle = player_angle + 360 end

        local wave_angle = inst.Transform:GetRotation()
        if wave_angle < 0 then wave_angle = wave_angle + 360 end

        local angle_difference = math.abs(wave_angle - player_angle)

        if angle_difference > 180 then angle_difference = 360 - angle_difference end

        local is_moving = other.sg:HasStateTag("moving")
        if angle_difference < TUNING.WAVE_BOOST_ANGLE_THRESHOLD and is_moving then
            -- Do boost
            other:PushEvent("boostbywave", {position = inst.Transform:GetWorldPosition(), boost = nil}) -- boost param is for walani
            Splash(inst, true)
        else
            WetAndDamage(inst, other)
            Splash(inst)
        end
    elseif other:HasTag("waveobstacle") then
        -- other.components.waveobstacle:OnCollide(inst) This is only used for mangroves
        WetAndDamage(inst, other)
        Splash(inst)
    end
end

local function OnCollideRogue(inst, other)
    if not other or not other:IsValid() then
        return
    end

    if other:HasTag("player") then
        WetAndDamage(inst, other)
        Splash(inst)
    elseif other:HasTag("waveobstacle") then
        -- other.components.waveobstacle:OnCollide(inst)
        WetAndDamage(inst, other)
        Splash(inst)
    end
end

-- Check if I'm about to hit land
local function CheckGround(inst, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    local vx, _, vz = inst.Physics:GetVelocity()

    local checkx = x + vx
    local checky = y
    local checkz = z + vz

    if not TheWorld.Map:IsOceanTileAtPoint(checkx, checky, checkz) then
        Splash(inst)
    end
end

local function OnSave(inst, data)
    if data then
        data.speed = inst.Physics:GetMotorSpeed()
        data.angle = inst.Transform:GetRotation()
        if inst.sg and inst.sg.currentstate and inst.sg.currentstate.name then
            data.state = inst.sg.currentstate.name
        end
    end
end

local function OnLoad(inst, data)
    if data then
        inst.Transform:SetRotation(data.angle or 0)
        inst.Physics:SetMotorVel(data.speed or 0, 0, 0)
        if inst.sg and data.state then
            inst.sg:GoToState(data.state)
        end
    end
end

local function ActivateCollision(inst)
    local phys = inst.Physics
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:SetCollisionMask(
        COLLISION.WORLD,
        COLLISION.OBSTACLES,
        COLLISION.SMALLOBSTACLES,
        COLLISION.CHARACTERS,
        COLLISION.GIANTS
    )
    phys:SetCollides(false)  -- Still will get collision callback, just not dynamic collisions.
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

        inst.ActivateCollision = ActivateCollision

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnEntitySleep = inst.Remove
        inst.done = false

        return inst
    end

    return fn
end


return Prefab("wave_ripple", MakeWave("pl_wave_ripple", OnCollideRipple, RipplePostinit), wave_assets),
    Prefab("wave_rogue", MakeWave("wave_rogue", OnCollideRogue, RoguePostinit), rogue_assets)

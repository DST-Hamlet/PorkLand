local waveassets =
{
	Asset( "ANIM", "anim/wave_ripple_ia.zip" ),
}

local rogueassets =
{
    Asset( "ANIM", "anim/wave_rogue.zip" ),
}

local function CheckGround(inst, dt)
    --Check if I'm about to hit land
    local x, y, z = inst.Transform:GetWorldPosition()
    local vx, vy, vz = inst.Physics:GetVelocity()

    local tile = WORLD_TILES.DIRT
    if TheWorld.Map then
        tile = TheWorld.Map:GetTileAtPoint(x + vx, y, z + vz)
    end

    if not IsOceanTile(tile) then
        inst:DoSplash()
    end
end

local function onsave(inst, data)
    if inst and data then
        data.speed = inst.Physics:GetMotorSpeed()
        data.angle = inst.Transform:GetRotation()
        if inst.sg and inst.sg.currentstate and inst.sg.currentstate.name then
            data.state = inst.sg.currentstate.name
        end
    end
end

local function onload(inst, data)
    if inst and data then
        inst.Transform:SetRotation(data.angle or 0)
        inst.Physics:SetMotorVel(data.speed or 0, 0, 0)
        if inst.sg and data.state then
            inst.sg:GoToState(data.state)
        end
    end
end

local function OnRemoveEntity(inst)
    if inst and inst.soundloop then
        inst.SoundEmitter:KillSound(inst.soundloop)
    end
end

local function fn_common()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.entity:AddPhysics()
    inst.Physics:SetSphere(1)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    --Zarklord: if this is inside activate_collision, the wave doesnt move until activate_collision gets called, moving it here causes it to behave like SW(move immediatly).
    inst.Physics:SetCollides(false) --Still will get collision callback, just not dynamic collisions.

    inst.dontcollideall = true
    inst.splash = "splash_water_wave"
    inst.damagesplash = ""

    TintByOceanTile(inst)

    -- inst:AddTag("scarytoprey") --Would be annoying in sw
    inst:AddTag("wave")
    inst:AddTag("FX")

	return inst
end

local function fn_master(inst)
	inst.groundtask = inst:DoPeriodicTask(0.5, CheckGround)

	inst.OnEntitySleep = inst.Remove
	-- inst.done = false --What does this do?
    inst.waveactive = false

    inst:SetStateGraph("SGwave_ia")

    inst.Physics:SetCollisionCallback(CollideWithWave)
    inst.DoSplash = DoWaveSplash

	return inst
end

local function ripple()
	local inst = fn_common()

    inst.entity:AddAnimState()
    inst.AnimState:SetBuild("wave_ripple_ia")
	inst.AnimState:SetBank("wave_ripple_ia")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	fn_master(inst)

    inst.persists = false

    inst.small = true
	inst.hitdamage = -TUNING.WAVE_HIT_DAMAGE
	inst.hitmoisture = TUNING.WAVE_HIT_MOISTURE
    inst.forcemult = 0.2

	inst.soundrise = "ia/common/waves/small"

	return inst
end

local function rogue()
	local inst = fn_common()

    inst.entity:AddAnimState()
    inst.AnimState:SetBuild("wave_rogue")
	inst.AnimState:SetBank("wave_rogue")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	fn_master(inst)

    inst.hitdamage = -TUNING.ROGUEWAVE_HIT_DAMAGE
    inst.hitmoisture = TUNING.ROGUEWAVE_HIT_MOISTURE
    inst.forcemult = 0.2

    inst.idle_time = 1

    inst.soundrise = "ia/common/waves/large"
    inst.soundloop = "ia/common/waves/large_LP"
    inst.soundtidal = "ia/common/waves/tidal"

    inst.OnRemoveEntity = OnRemoveEntity

	inst.OnSave = onsave
	inst.OnLoad = onload

	return inst
end


return Prefab("wave_ripple", ripple, waveassets),
       Prefab("wave_rogue", rogue, rogueassets)

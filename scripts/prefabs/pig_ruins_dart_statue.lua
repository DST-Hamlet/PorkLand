local assets =
{
    Asset("ANIM", "anim/pig_ruins_dart_statue.zip"),
    Asset("ANIM", "anim/pig_ruins_dart_statue_stage2.zip"),
    Asset("ANIM", "anim/pig_ruins_dart_statue_stage3.zip"),
}

local prefabs =
{
    "pig_ruins_dart",
}

SetSharedLootTable("dart_thrower",
{
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 0.4},
})

local function UpdateArt(inst)
    if not inst.components.disarmable.armed then
        inst.components.autodartthrower:TurnOff()
        inst.AnimState:PlayAnimation("disarmed")
    end

    if inst.components.workable.workleft == TUNING.ROCKS_MINE_GIANT then
        inst.AnimState:SetBuild("pig_ruins_dart_statue")
    elseif inst.components.workable.workleft > TUNING.ROCKS_MINE_GIANT * (2 / 3) then
        inst.AnimState:SetBuild("pig_ruins_dart_statue_stage2")
    elseif inst.components.workable.workleft > TUNING.ROCKS_MINE_GIANT * (1 / 3) then
        inst.AnimState:SetBuild("pig_ruins_dart_statue_stage3")
    end
end

local function LaunchdArt(inst, angle)
    inst:DoTaskInTime(2 * FRAMES - 0.001, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local theta = angle * DEGREES
        local pt = Vector3(math.cos(theta), 0, math.sin(-theta))

        local projectile = SpawnPrefab("pig_ruins_dart")
        projectile.Transform:SetPosition(x + pt.x, y, z + pt.z)
        projectile.Transform:SetRotation(angle)
        projectile.Physics:SetMotorVel(30, 0, 0)
        projectile.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/blowdart_fire")

        local fx = SpawnPrefab("circle_puff_fx")
        fx.Transform:SetPosition(x + pt.x, y + 2.5, z + pt.z)
    end)
end

local function Shoot(inst)
    if inst.components.disarmable.armed then
        local angle = inst.Transform:GetRotation()
        LaunchdArt(inst, angle)
    end
end

local function Disarm(inst, doer)
    local pt = inst:GetPosition()
    inst.components.lootdropper:SpawnLootPrefab("blowdart_pipe", pt)
    inst.components.autodartthrower:TurnOff()
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_wall")

    UpdateArt(inst)
end

local function TurnOn(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/dart_statue_LP", "rotate")
end

local function TurnOff(inst)
   inst.SoundEmitter:KillSound("rotate")
   inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/dart_statue_stop")
end

local function SetRotation(inst, rotation)
    if rotation < 0 then
        rotation = rotation + 360
    end
    if rotation > 360 then
        rotation = rotation - 360
    end
    inst.Transform:SetRotation(rotation)
    rotation = Remap(rotation, 0, 360, 1, 0)

    inst.AnimState:SetPercent("CCW", rotation)
end

local function UpdateRotation(inst, dt)
    local inc = 360 / 10 * dt
    if not inst.ccw then
        inc = -inc
    end
    SetRotation(inst, inst.Transform:GetRotation() + inc)
    inst.darttimer = inst.darttimer + dt
    if inst.darttimer >= inst.shoottime then
        inst:ShootDart()
        inst.darttimer = 0
    end
end

local function OnWorkCallback(inst, worker, work_left)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.components.autodartthrower:TurnOn()

    local hit_fx = SpawnPrefab("rock_hit_debris")
    hit_fx.Transform:SetPosition(x, y, z)

    if work_left <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot()

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(x, y, z)
        fx:SetMaterial("stone")

        inst:Remove()
    end

    UpdateArt(inst)
end

local function OnSave(inst, data)
    data.rotation = inst.Transform:GetRotation()
    data.ccw = inst.ccw
end

local function OnLoad(inst, data)
    if data.rotation then
        inst.setrotation(inst,data.rotation)
    end
    inst.ccw = data.ccw
    UpdateArt(inst)
end

local function OnHaunt(inst, haunter)
    if inst.components.disarmable.armed and math.random() < TUNING.HAUNT_CHANCE_HALF then
        if inst.components.autodartthrower.on then
            inst.components.autodartthrower:TurnOff()
        else
            inst.components.autodartthrower:TurnOn()
        end
        return true
    end
    return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.25)

    inst.AnimState:SetBank("pig_ruins_dart_statue")
    inst.AnimState:SetBuild("pig_ruins_dart_statue")
    inst.AnimState:SetPercent("CCW", 0)

    inst.Transform:SetRotation(0)

    inst:AddTag("dartthrower")

    inst.name = STRINGS.NAMES.PIG_RUINS_DART_STATUE

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("autodartthrower")
    inst.components.autodartthrower.updatefn = UpdateRotation
    inst.components.autodartthrower.turnonfn = TurnOn
    inst.components.autodartthrower.turnofffn = TurnOff

    inst:AddComponent("inspectable")

    inst:AddComponent("disarmable")
    inst.components.disarmable.disarmfn = Disarm

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("dart_thrower")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_GIANT)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.ShootDart = Shoot
    inst.updaterotation = UpdateRotation
    inst.setrotation = SetRotation

    if math.random() < 0.5 then
        inst.ccw = true
    end
    inst.darttimer = 0
    inst.shoottime = 15 * FRAMES - 0.001

    UpdateArt(inst)
    SetRotation(inst, math.random() * 360)

    return inst
end

return Prefab("pig_ruins_dart_statue", fn, assets, prefabs)

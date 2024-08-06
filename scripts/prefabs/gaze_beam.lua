local assets =
{
    Asset("ANIM", "anim/gaze_beam.zip"),
}

local prefabs =
{

}

local function OnUpdate(inst, dt)
    if dt then
        inst.time_remaining = inst.time_remaining - dt
        local dist = Remap(inst.time_remaining, inst.time_remaining_max, 0, 2, 6)
        inst.components.creatureprox:SetDist(dist, dist + 1)
    end
end

local function OnCollide(inst, other)
    if other.components.freezable and not other.components.freezable:IsFrozen() and other ~= inst.host then
        if inst.host:HasTag("player") and other:HasTag("player") and not inst.canhitplayers then
            return
        end
        if inst.host and other.components.combat then
            other:PushEvent("attacked", {attacker = inst.host, damage = 0, weapon = inst})
        end
        if not other.components.freezable:IsFrozen() then
            other.components.freezable:SpawnShatterFX()
        end
        other.components.freezable:AddColdness(5)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)
    RemovePhysicsColliders(inst)
    inst.Physics:SetMotorVel(10, 0, 0)

    inst.AnimState:SetBank("gaze_beam")
    inst.AnimState:SetBuild("gaze_beam")
    inst.AnimState:PlayAnimation("loop")

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/gaze_LP", "gaze")

    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("creatureprox")
    inst.components.creatureprox:SetInProxFn(OnCollide)
    inst.components.creatureprox.period = 0.001
    inst.components.creatureprox:SetDist(3, 4)
    inst.components.creatureprox:SetOnUpdate(OnUpdate)

    inst:ListenForEvent("animover", function(inst, data)
        if inst.components.creatureprox.enabled then
            inst.components.creatureprox.enabled = false
            inst.AnimState:PlayAnimation("loop_pst")
            inst.SoundEmitter:KillSound("gaze")
        else
            inst:Remove()
        end
    end)

    inst.canhitplayers = TheNet:GetPVPEnabled()
    inst.time_remaining_max = 2
    inst.time_remaining = inst.time_remaining_max

    return inst
end

return Prefab("gaze_beam", fn, assets, prefabs)

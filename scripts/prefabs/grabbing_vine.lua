local assets =
{
    Asset("ANIM", "anim/cave_exit_rope.zip"),
    Asset("ANIM", "anim/copycreep_build.zip"),
}

local prefabs =
{
    "plantmeat",
    "rope",
}

local brain = require("brains/grabbing_vinebrain")

SetSharedLootTable("grabbing_vine",
{
    {"plantmeat",  0.4},
    {"rope",  0.4},
})

local function ShadownOn(inst)
    inst.DynamicShadow:SetSize(1.5, .75)
end

local function ShadowOff(inst)
    inst.DynamicShadow:SetSize(0, 0)
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target) and inst:IsNear(target, TUNING.GRABBING_VINE_HIT_RANGE + 2)
end

local NoTags = {"FX", "NOCLICK", "INLIMBO"}
local function RetargetFn(inst)
    if not inst.components.health:IsDead() then
        return FindEntity(inst, TUNING.GRABBING_VINE_TARGET_DIST, function(guy)
            return guy.components.inventory ~= nil and not guy:HasTag("plantkin")
        end, nil, NoTags)
    end
end

local function OnNear(inst)
    inst.near = true
end

local function OnFar(inst)
    inst.near = nil
end

local function OnSave(inst, data)
    local references = {}
    if inst.spawn_patch then
        data.spawn_patch = inst.spawn_patch.GUID
        references = {data.leader}
    end
    return references
end

local function OnHitOther(inst, other, damage)
    inst.components.thief:StealItem(other, nil, nil, true)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude) return dude:HasTag("hangingvine") end, 5)
end

local function OnTeleported(inst)
    inst.components.health:Kill()
end

local function LoadPostPass(inst,ents, data)
    if data then
        if data.spawn_patch then
            local spawn_patch = ents[data.spawn_patch]
            if spawn_patch then
                inst.spawn_patch = spawn_patch.entity
            end
        end
    end
end

local function OnRemoveEntity(inst)
    if inst.spawn_patch then
        inst.spawn_patch:SpawnNewVine(inst.prefab, inst.GUID)
    end
end

local function InIt(inst)
    inst.sg:GoToState("idle_up")
    inst.components.knownlocations:RememberLocation("home", Point(inst.Transform:GetWorldPosition()), true)
end

local function commonfn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, .75)
    -- inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("exitrope")
    inst.AnimState:SetBuild("copycreep_build")
    inst.AnimState:PlayAnimation("idle_loop")

    MakeCharacterPhysics(inst, 1, .3)
    inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
    inst.Physics:CollidesWith(COLLISION.FLYERS)

    inst:AddTag("flying")
    inst:AddTag("hangingvine")
    inst:AddTag("animal")

    if not TheNet:IsDedicated() then
        inst:AddComponent("distancefade")
        inst.components.distancefade:Setup(15, 25)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.ShadownOn = ShadownOn
    inst.ShadowOff = ShadowOff

    inst:AddComponent("thief")
    inst:AddComponent("knownlocations")
    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 8

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.GRABBING_VINE_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("grabbing_vine")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.GRABBING_VINE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.GRABBING_VINE_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.GRABBING_VINE_ATTACK_RANGE, TUNING.GRABBING_VINE_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(0.5, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.onhitotherfn = OnHitOther

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(OnNear)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetDist(10, 16)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGgrabbing_vine")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("teleported", OnTeleported)

    inst.OnSave = OnSave
    inst.LoadPostPass = LoadPostPass
    inst.OnRemoveEntity = OnRemoveEntity

    MakeHauntableIgnite(inst)

    inst:DoTaskInTime(0, InIt)

    return inst
end

return Prefab("grabbing_vine", commonfn, assets, prefabs)

local assets =
{
    Asset("ANIM", "anim/giant_grub.zip")
}

local prefabs =
{
    "monstermeat",
}


local function SetState(inst, state)
    --"under" or "above"
    inst.State = string.lower(state)
    if inst.State == "under" then
        ChangeToInventoryPhysics(inst)
    elseif inst.State == "above" then
        ChangeToCharacterPhysics(inst)
    end
end

local function IsState(inst, state)
    return inst.State == string.lower(state)
end

local function CanBeAttacked(inst, attacker)
    return inst.State == "above"
end

local function IsPreferedTarget(target)
    return (target:HasTag("has_antmask") and target:HasTag("has_antsuit")) or (target.prefab == "antman")
end

local RETARGET_DIST = 10
local RETARGET_NO_TAGS = {"giantgrub"}

local function RetargetFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, RETARGET_DIST, nil, RETARGET_NO_TAGS)

    for _, v in pairs(ents) do
        if inst.components.combat:CanTarget(v) then
            if IsPreferedTarget(v) then
                return v
            end

            if v:HasTag("player") then
                return v
            end
        end
    end

    if #ents > 0 then
        return ents[1]
    end

    return nil
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and (target:HasTag("player"))
end

local function OnSleep(inst)
    inst.SoundEmitter:KillAllSounds()
end

local function OnRemove(inst)
    inst.SoundEmitter:KillAllSounds()
end

local brain = require("brains/giantgrubbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, 0.5)

    inst.AnimState:SetBank("giant_grub")
    inst.AnimState:SetBuild("giant_grub")
    inst.AnimState:PlayAnimation("idle", true)

    inst.DynamicShadow:SetSize(1, 0.75)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(3, 3, 3)

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("giantgrub")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.GIANT_GRUB_WALK_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.GIANT_GRUB_HEALTH)

    inst:AddComponent("inspectable")

    inst:AddComponent("sleeper")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"monstermeat"})

    inst:AddComponent("knownlocations")

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 0
    inst.components.groundpounder.numRings = 2

    inst.CanGroundPound = true

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.GIANT_GRUB_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.GIANT_GRUB_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.GIANT_GRUB_ATTACK_RANGE, TUNING.GIANT_GRUB_ATTACK_RANGE)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat.canbeattackedfn = CanBeAttacked
    inst.components.combat.hiteffectsymbol = "chest"

    inst:SetBrain(brain)
    inst:SetStateGraph("SGgiantgrub")

    inst.data = {}

    inst.attackUponSurfacing = false

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst, "chest")
    MakeSmallBurnableCharacter(inst, "chest")
    MakeTinyFreezableCharacter(inst, "chest")

    SetState(inst, "under")
    inst.SetState = SetState
    inst.IsState = IsState

    inst.OnEntitySleep = OnSleep
    inst.OnRemoveEntity = OnRemove

    return inst
end

return Prefab("giantgrub", fn, assets, prefabs)

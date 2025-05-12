local assets =
{
    Asset("ANIM", "anim/antman_basic.zip"),
    Asset("ANIM", "anim/antman_attacks.zip"),
    Asset("ANIM", "anim/antman_actions.zip"),
    Asset("ANIM", "anim/antman_egghatch.zip"),
    Asset("ANIM", "anim/antman_guard_build.zip"),
    Asset("ANIM", "anim/antman_warpaint_build.zip"),
    Asset("ANIM", "anim/antman_translucent_build.zip"),
}

local prefabs =
{
    "monstermeat",
    "chitin",
    "antman_warrior_egg"
}

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude) return dude:HasTag("ant") end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, SHARE_TARGET_DIST / 2)

    if not ents or not next(ents) then
        return
    end

    local num_helpers = 0
    for _, v in pairs(ents) do
        if v ~= inst and v.components.combat and not (v.components.health and v.components.health:IsDead()) and fn(v) then
            if v:PushEvent("suggest_tree_target", {tree = attacker}) then
                num_helpers = num_helpers + 1
            end
        end
        if num_helpers >= MAX_TARGET_SHARES then
            break
        end
    end
end

local function OnAttacked(inst, data)
    local attacker = data.attacker
    inst:ClearBufferedAction()

    if attacker then
        if attacker.prefab == "deciduous_root" and attacker.owner then
            OnAttackedByDecidRoot(inst, attacker.owner)
        elseif attacker.prefab ~= "deciduous_root" then
            inst.components.combat:SetTarget(attacker)
            inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(ent)
                return ent:HasTag("ant")
            end, MAX_TARGET_SHARES)
        end
    end
end

local RETARGET_DIST = 16
local KEEP_TARGET_DIST = 40
local ATTACK_ONSIGHT_DISTSQ = 8 * 8
local RETARGET_ONE_OF_TAGS = {"monster", "player"}

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(ent)
        if not ent.components.health or ent.components.health:IsDead()
            or not inst.components.combat:CanTarget(ent) then
            return
        end

        if ent:HasTag("monster") then
            return ent
        end

        if ent.components.inventory and ent:GetDistanceSqToInst(inst) < ATTACK_ONSIGHT_DISTSQ then
            return ent
        end
    end, nil, nil, RETARGET_ONE_OF_TAGS)
end

local function KeepTargetFn(inst, target)
    if inst.components.combat:CanTarget(target) then
        local distsq = target:GetDistanceSqToInst(inst)
        return distsq < KEEP_TARGET_DIST * KEEP_TARGET_DIST
    else
        return false
    end
    return inst.components.combat:CanTarget(target)
end

local function OnSave(inst, data)
    if inst.queen then
        data.queen_guid = inst.queen.GUID
    end

    if inst:HasTag("aporkalypse_cleanup") then
        data.aporkalypse_cleanup = true
    end
end

local function OnLoadPostPass(inst, ents, data)
    if data.queen_guid and ents[data.queen_guid] then
        inst.queen = ents[data.queen_guid].entity
        inst:ListenForEvent("death", function(warrior, data)
            if inst.queen and inst.queen:IsValid() then
                inst.queen:WarriorKilled()
            end
        end)
    end

    if data.aporkalypse_cleanup then
        inst:AddTag("aporkalypse_cleanup")
    end
end

local function OnIsAporkalypse(inst, isaporkalypse)
    if (not inst:IsValid()) or inst.components.health:IsDead() then
        return
    end

    if isaporkalypse then
        inst.Light:Enable(true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetBuild("antman_warpaint_build")
    else
        if inst:HasTag("aporkalypse_cleanup") then -- this ant warrior is transformed from regular ant
            local home = inst.components.homeseeker and inst.components.homeseeker:GetHome()
            local ant = ReplacePrefab(inst, "antman")
            if home then
                home.components.childspawner:TakeOwnership(ant)
            end
            return
        end

        inst.Light:Enable(false)
        inst.AnimState:SetBloomEffectHandle("")
        inst.AnimState:SetBuild("antman_guard_build")
    end
end

local brain = require("brains/antwarriorbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, 0.5)

    inst.AnimState:SetBank("antman")
    inst.AnimState:SetBuild("antman_guard_build")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:Hide("hat")

    inst.DynamicShadow:SetSize(1.5, 0.75)

    inst.Light:SetFalloff(0.35)
    inst.Light:SetIntensity(0.25)
    inst.Light:SetRadius(1)
    inst.Light:SetColour(120 / 255, 120 / 255, 120 / 255)
    inst.Light:Enable(false)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.15, 1.15, 1.15)

    inst:AddTag("character")
    inst:AddTag("ant")
    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("knownlocations")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventory")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.ANTMAN_WARRIOR_RUN_SPEED --5
    inst.components.locomotor.walkspeed = TUNING.ANTMAN_WARRIOR_WALK_SPEED --3

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANTMAN_WARRIOR_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.ANTMAN_WARRIOR_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetTarget(nil)
    inst.components.combat.hiteffectsymbol = "antman_torso"
    inst.components.combat.debris_immune = true

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.ANTWARRIORNAMES
    inst.components.named:PickNewName()

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANTMAN_WARRIOR_HEALTH)

    inst:AddComponent("sleeper")
    inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("monstermeat", 3)
    inst.components.lootdropper:AddRandomLoot("chitin", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst:SetBrain(brain)
    inst:SetStateGraph("SGantwarrior")

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst, "antman_torso")
    MakeMediumBurnableCharacter(inst, "antman_torso")
    MakeMediumFreezableCharacter(inst, "antman_torso")

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    inst:ListenForEvent("attacked", OnAttacked)

    inst:WatchWorldState("isaporkalypse", OnIsAporkalypse)
    OnIsAporkalypse(inst, TheWorld.state.isaporkalypse)

    return inst
end

return Prefab("antman_warrior", fn, assets, prefabs)

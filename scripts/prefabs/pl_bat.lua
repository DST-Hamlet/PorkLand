-- 这个文件是原版洞穴蝙蝠的复制版，用于修复原版的一些离谱bug
-- 在这个复制版洞穴蝙蝠的代码中也使用了一些吸血蝙蝠的代码，因为比原版代码效果更好
-- 在未来的拓展版分支或许需要一个更好的解决方案

local assets =
{
    Asset("ANIM", "anim/bat_basic.zip"),
    Asset("SOUND", "sound/bat.fsb"),
}

local prefabs =
{
    "guano",
    "batwing",
    "teamleader",
}

SetSharedLootTable("bat",
{
    {"batwing",    0.25},
    {"guano",      0.15},
    {"monstermeat",0.10},
})

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

local function MakeTeam(inst, attacker)
    local leader = SpawnPrefab("teamleader")
    leader:AddTag("bat")
    leader.components.teamleader.mult = 1.5
    leader.components.teamleader:SetUp(attacker, inst)
    leader.components.teamleader:BroadcastDistress(inst)
end

local function KeepTarget(inst, target)
    if inst.components.teamattacker.teamleader == nil or
        (inst.components.teamattacker.teamleader and not inst.components.teamattacker.teamleader:CanAttack()) or
        inst.components.teamattacker.orders == "ATTACK" then
        return true
    else
        return false
    end
end

local RETARGET_DIST = 12
local RETARGET_DIST_SLEEP = 3
local RETARGET_CANT_TAGS = {"bat"}
local RETARGET_ONEOF_TAGS = {"character", "monster"}
local function Retarget(inst)
    local ta = inst.components.teamattacker

    local newtarget = nil
    if not inst.components.sleeper:IsAsleep() then
        newtarget = FindEntity(inst, RETARGET_DIST, function(ent)
            return inst.components.combat:CanTarget(ent)
        end, nil, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
    else
        newtarget = FindEntity(inst, RETARGET_DIST_SLEEP, function(ent)
            return inst.components.combat:CanTarget(ent)
        end, nil, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
    end

    if newtarget and not ta.inteam and not ta:SearchForTeam() then
        MakeTeam(inst, newtarget)
    end

    if ta.inteam and not ta.teamleader:CanAttack() then
        return newtarget
    end
end

local function OnAttacked(inst, data)
    if not inst.components.teamattacker.inteam and not inst.components.teamattacker:SearchForTeam() then
        MakeTeam(inst, data.attacker)
    elseif inst.components.teamattacker.teamleader then
        inst.components.teamattacker.teamleader:BroadcastDistress() --Ask for help!
    end

    if inst.components.teamattacker.inteam and not inst.components.teamattacker.teamleader:CanAttack() then
        local attacker = data and data.attacker
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(ent)
            return ent:HasTag("bat") and not ent.components.health:IsDead()
        end, MAX_TARGET_SHARES)
    end
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(ent)
        return ent:HasTag("bat") and not ent.components.health:IsDead()
    end, MAX_TARGET_SHARES)
end

local function OnWakeUp(inst)

end

local function OnSave(inst, data)
    if inst:HasTag("batfrenzy") then
        data.batfrenzy = true
    end
    if inst.components.sleeper.hibernate then
        data.hibernatesleep = true
    end
    if inst.sg:HasStateTag("flight") then
        data.flying = true
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.batfrenzy then
        inst:AddTag("batfrenzy")
    end

    if data.hibernatesleep then
        inst.components.sleeper.hibernate = true
        inst.components.sleeper:GoToSleep()
        inst.sg:GoToState("sleeping")
    end

    if data.flying then
        inst.sg:GoToState("glide")
    end
end

local brain = require("brains/pl_batbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(.75, .75, .75)

    inst.AnimState:SetBank("bat")
    inst.AnimState:SetBuild("bat_basic")

    inst.DynamicShadow:SetSize(1.5, 0.75)

    inst.Transform:SetFourFaced()

    MakeFlyingCharacterPhysics(inst, 10, 0.5)
    MakeInventoryFloatable(inst)

    inst:AddTag("bat")
    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("flying")

    inst.name = STRINGS.NAMES.BAT

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = {ignorewalls = true, ignorecreep = true, allowocean = true}
    inst.components.locomotor.walkspeed = TUNING.BAT_WALK_SPEED

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true) -- can eat monster meat!

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BAT_HEALTH)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.BAT_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.BAT_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.BAT_ATTACK_DIST)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("bat")

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "bat"

    inst:AddComponent("knownlocations")

    inst:AddComponent("teamattacker")
    inst.components.teamattacker.team_type = "bat"

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpl_bat")

    MakeMediumBurnableCharacter(inst, "bat_body")
    MakeMediumFreezableCharacter(inst, "bat_body")
    MakePoisonableCharacter(inst, "bat_body")
    MakeHauntablePanic(inst)

    inst.cavebat = false
    inst.MakeTeam = MakeTeam
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("onwakeup", OnWakeUp)

    return inst
end

return Prefab("pl_bat", fn, assets, prefabs)

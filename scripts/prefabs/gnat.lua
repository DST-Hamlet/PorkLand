local assets =
{
    Asset("ANIM", "anim/gnat.zip"),
}

local prefabs =
{

}

local brain = require("brains/gnatbrain")

local function KeepTargetFn(inst, target)
   return target and inst.components.combat:CanTarget(target) and target.components.health and not target.components.health:IsDead()
end

local RETARGET_DIST = 5
local RETARGET_MUST_TAGS = {"character"}
local RETARGET_NO_TAGS = {"FX", "NOCLICK", "INLIMBO", "monster"}

local function RetargetFn(inst)
    return FindEntity(inst, RETARGET_DIST, function(guy)
        return inst.components.combat:CanTarget(guy)
    end, RETARGET_MUST_TAGS, RETARGET_NO_TAGS)
end

local function PlayerSeenBugsDie(inst)
    for _, player in pairs(AllPlayers) do
        if not player:HasTag("playerghost") and inst:GetDistanceSqToInst(player) < 10 * 10 then
            player:DoTaskInTime(0.5, function()
                player.components.talker:Say(GetString(player.prefab, "ANNOUNCE_GNATS_DIED"))
            end)
        end
    end
end

local FIND_LIGHT_DIST = 15
local FIND_LIGHT_MUST_TAGS = {"lightsource"}
local FIND_LIGHT_NO_TAGS = {"INLIMBO"}
local function FindLight(inst)
    local light = FindEntity(inst, FIND_LIGHT_DIST, function(ent)
        if ent.Light and ent.Light:IsEnabled() then
            return true
        end
    end, FIND_LIGHT_MUST_TAGS, FIND_LIGHT_NO_TAGS)

    return light
end

local LOSE_LIGHT_DIST = 20
local function CanTargetLight(inst, target)
    return target and target:IsValid()
        and inst:GetDistanceSqToInst(target) < LOSE_LIGHT_DIST * LOSE_LIGHT_DIST
end

local function CanBuildMoundAtPoint(x, y, z)
    local ents = TheSim:FindEntities(x, y, z, 4, nil, {"FX", "NOCLICK", "DECOR", "INLIMBO"})
    return #ents <= 1 and TheWorld.Map:GetTileAtPoint(x, y, z) == WORLD_TILES.PAINTED and IsSurroundedByLand(x, y, z, 2)
end

local function BuildHome(inst)
    inst:PushEvent("takeoff")

    local x, y, z = inst.Transform:GetWorldPosition()

    if not inst.CanBuildMoundAtPoint(x, y, z) then
        return false
    end

    local home = SpawnPrefab("gnatmound")
    home.Transform:SetPosition(x, y, z)
    home.components.workable.workleft = 1
    home.components.childspawner:TakeOwnership(inst)
    home.components.childspawner.childreninside = home.components.childspawner.childreninside - 1
    home:UpdateAnimations()

    inst.makehome = nil
    inst.components.timer:StopTimer("build_mount_cd", TUNING.TOTAL_DAY_TIME * (0.5 + math.random() * 0.5))

    return true
end

local function TryBuildHome(inst)
    if not inst.components.timer:TimerExists("build_mount_cd") and not inst.components.homeseeker:HasHome() then
        inst:build_mound_action()
    end
end

local function gnat_redirect(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    return (cause ~= "poison" and cause ~= "gascloud")
        and not inst.components.freezable:IsFrozen()
end

local function CanBeAttack(inst, data)
    return inst.components.freezable:IsFrozen()
        or (data.weapon and (data.weapon:HasOneOfTags({"rangedweapon", "blowdart", "blowpipe", "slingshot", "thrown", "gun"})))
end

local function CanBeHit(inst, data)
    return inst.components.freezable:IsFrozen()
        or (data.weapon and (data.weapon:HasOneOfTags({"rangedweapon"})))
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, 0.25)

    inst.AnimState:SetBuild("gnat")
    inst.AnimState:SetBank("gnat")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetRayTestOnBB(true)

    inst.DynamicShadow:SetSize(2, 0.6)

    inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.VOID_LIMITS)

    inst.Transform:SetFourFaced()

    inst:AddTag("gnat")
    inst:AddTag("flying")
    inst:AddTag("insect")
    inst:AddTag("animal")
    inst:AddTag("smallcreature")
    inst:AddTag("avoidonhit")
    inst:AddTag("difficult_to_hit")
    inst:AddTag("hostile")
    inst:AddTag("burnable") -- needs this to be frozen by flingomatic
    inst:AddTag("lastresort") -- for auto attacking

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = {ignorewalls = true, ignorecreep = true, allowocean = true}
    inst.components.locomotor.walkspeed = TUNING.GNAT_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.GNAT_RUN_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)
    inst.components.health.redirect = gnat_redirect

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "fx_puff"
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetDefaultDamage(1)
    inst.components.combat:SetAttackPeriod(10)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.NEVER)

    inst:AddComponent("knownlocations")

    inst:AddComponent("timer")

    inst:AddComponent("homeseeker")
    inst.components.homeseeker.removecomponent = false
    local _onhomeremoved = inst.components.homeseeker.onhomeremoved
    inst.components.homeseeker.onhomeremoved = function(home, ...)
        inst.components.timer:StartTimer("build_mount_cd", TUNING.TOTAL_DAY_TIME * (0.5 + math.random() * 0.5))
        return _onhomeremoved(home, ...)
    end

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_TINY * 2

    inst:AddComponent("inspectable")

    inst:AddComponent("infester")

    inst:AddComponent("lootdropper")

    inst:AddComponent("entitysleeptask")
    inst.components.entitysleeptask:SetSleepPeriodFn(TryBuildHome, math.random() * 5 + 27.5)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGgnat")

    inst:ListenForEvent("teleported", function()
        inst.SoundEmitter:KillSound("move") -- stupid sound engine bug...
    end)

    inst:ListenForEvent("freeze", function() inst:RemoveTag("lastresort") end)
    inst:ListenForEvent("unfreeze", function() inst:AddTag("lastresort") end)

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeTinyFreezableCharacter(inst, "fx_puff")

    inst.FindLight = FindLight
    inst.CanTargetLight = CanTargetLight

    inst.build_mound_action = BuildHome
    inst.CanBuildMoundAtPoint = CanBuildMoundAtPoint

    inst.CanBeAttack = CanBeAttack
    inst.CanBeHit = CanBeHit

    return inst
end

return Prefab("gnat", fn, assets, prefabs)

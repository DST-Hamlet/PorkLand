local assets =
{
    Asset("ANIM", "anim/bat_vamp_basic.zip"),
    Asset("ANIM", "anim/bat_vamp_build.zip"),
    Asset("ANIM", "anim/bat_vamp_actions.zip"),
    Asset("ANIM", "anim/bat_vamp_shadow.zip"),
}

local prefabs =
{
    "guano",
    "monstermeat",
    "bat_hide",
    "vampire_bat_wing",
    "batwing",
}

SetSharedLootTable("vampirebat",
{
    {"monstermeat",      0.5},
    {"bat_hide",         0.5},
    {"vampire_bat_wing", 0.25},
    -- {"batwing", 0.1},
})

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40
local KEEP_TARGET_DIST = 40

local function OnWingDown(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/flap")
end

local function OnWingDownShadow(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_flap")
end

local function KeepTarget(inst, target)
    if inst.components.combat:CanTarget(target) then
        local distsq = target:GetDistanceSqToInst(inst)
        return distsq < KEEP_TARGET_DIST * KEEP_TARGET_DIST
    else
        return false
    end
end

local RETARGET_DIST = 16
local RETARGET_DIST_SLEEP = 3
local RETARGET_CANT_TAGS = {"vampirebat"}
local RETARGET_ONEOF_TAGS = {"character", "monster"}
local function Retarget(inst)
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

    return newtarget
end

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    if attacker == nil then
        return
    end

    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(ent)
        return ent:HasTag("vampirebat") and not ent.components.health:IsDead()
    end, MAX_TARGET_SHARES)
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(ent)
        return ent:HasTag("vampirebat") and not ent.components.health:IsDead()
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

local brain = require("brains/vampirebatbrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    local scale = 0.9
    inst.AnimState:SetBank("bat_vamp")
    inst.AnimState:SetBuild("bat_vamp_build")
    inst.AnimState:SetScale(scale, scale, scale)

    inst.DynamicShadow:SetSize(1.5, 0.75)

    inst.Transform:SetFourFaced()

    MakeFlyingCharacterPhysics(inst, 50, 0.5)
    MakeInventoryFloatable(inst)

    inst:AddTag("vampirebat")
    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("flying")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = {ignorewalls = true, ignorecreep = true, allowocean = true}
    inst.components.locomotor.walkspeed = TUNING.VAMPIREBAT_WALK_SPEED

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true) -- can eat monster meat!

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.VAMPIREBAT_HEALTH)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.VAMPIREBAT_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.VAMPIREBAT_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("vampirebat")

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("teamcombat")
    inst.components.teamcombat.teamtype = "vampirebat"

    inst:SetBrain(brain)
    inst:SetStateGraph("SGvampirebat")

    MakeMediumBurnableCharacter(inst, "bat_body")
    MakeMediumFreezableCharacter(inst, "bat_body")
    MakePoisonableCharacter(inst, "bat_body")
    MakeHauntablePanic(inst)

    inst.cavebat = false
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("wingdown", OnWingDown)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("onwakeup", OnWakeUp)

    return inst
end

-----------------------------------------------------------------------------------

local function DoDive(inst)
    local player = inst.hunttarget

    -- The player has left the game, spawn anyways
    if not player or not player:IsValid() then
        local bat = SpawnPrefab("vampirebat")
        local spawn_point = inst:GetPosition()
        if bat and spawn_point then
            bat.Transform:SetPosition(spawn_point.x, spawn_point.y + 30, spawn_point.z)
            bat.sg:GoToState("glide")
            bat:AddTag("batfrenzy")
        end
        inst.task = nil
        inst.taskinfo = nil
        inst.persists = false
        inst.components.colourtweener:StartTween({1,1,1,0}, 0.3)
        inst.components.glidemotor:EnableMove(false)
        inst:DoTaskInTime(1,inst.Remove)
        return
    end

    -- allow water but not interior
    if player and player:IsValid() and not player:GetIsInInterior() and inst:IsOnPassablePoint(true) then
        local bat = SpawnPrefab("vampirebat")
        local spawn_point = inst:GetPosition()
        if bat and spawn_point then
            bat.sg:GoToState("glide")
            bat.Transform:SetPosition(spawn_point.x, spawn_point.y + 30, spawn_point.z)
            bat:FacePoint(player.Transform:GetWorldPosition())
            bat:AddTag("batfrenzy")

            bat:DoTaskInTime(2, function()
                -- Use Combat:SuggestTarget?
                bat.components.combat:SuggestTarget(player)
            end)
        end
        inst.task = nil
        inst.taskinfo = nil
        inst.persists = false
        inst.components.colourtweener:StartTween({1,1,1,0}, 0.3)
        inst.components.glidemotor:EnableMove(false)
        inst:DoTaskInTime(1,inst.Remove)
    else
        inst.task, inst.taskinfo = inst:ResumeTask(2 + math.random() * 1, DoDive)
    end
end


local function UpdateColourTweener(inst)
    if inst.taskinfo ~= nil then
        local r, g, b = TheSim:GetAmbientColour()
        local colourstrength = ((r + g + b) / 3) / 255
        inst.components.colourtweener:StartTween({1,1,1,math.min(1, colourstrength * 1.2)}, 3)
    end
end

local function SetUp(inst, target)
    inst.hunttarget = target
    inst.components.glidemotor:SetTargetPos(target:GetPosition())
end

local function UpdateTraget(inst)
    local target = inst.hunttarget
    if target then
        if not target:IsValid() then
            inst.hunttarget = nil
        elseif inst:GetDistanceSqToInst(target) > 64 * 64 then
            inst.hunttarget = nil
        elseif IsEntityDeadOrGhost(target) then
            inst.hunttarget = nil
        elseif target.entity:IsVisible() then
            inst.hunttarget = nil
        end
    end

    if inst.hunttarget == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local newtarget = FindClosestPlayerInRange(x, y, z, 64, true)
        inst.hunttarget = newtarget
    end

    if inst.hunttarget then
        inst.components.glidemotor:SetTargetPos(inst.hunttarget:GetPosition())
    end

    if inst.scale then
        inst.scale = math.min(inst.scale + 0.02 * FRAMES, 1.2)
        inst.AnimState:SetScale(inst.scale, inst.scale, inst.scale)
    end
end

local function OnSaveShadow(inst, data)
    if inst.taskinfo then
        data.time = inst:TimeRemainingInTask(inst.taskinfo)
        if inst.hunttarget.GUID then
            data.player = inst.hunttarget.GUID
            return {player = inst.hunttarget.GUID}
        end
        return
    end

    data.scale = inst.scale
end

local function OnLoadShadow(inst, data)
    if not data then
        inst:Remove()
        return
    end

    if data.time then
        inst.task, inst.taskinfo = inst:ResumeTask(data.time, DoDive)
    end

    if data.scale then
        inst.scale = data.scale
    end
end

local function OnLoadPostPassShadow(inst, ents, data)
    if data and data.player and ents[data.player] then
        inst:SetUp(ents[data.player].entity)
    end
end

local function circlingbatfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- Custom physics settings
    local phys = inst.entity:AddPhysics()
    phys:SetMass(1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.FLYERS)
    phys:SetCollisionMask(COLLISION.GROUND)
    if TheWorld:HasTag("porkland") then
        phys:ClearCollidesWith(COLLISION.LIMITS)
        phys:ClearCollidesWith(COLLISION.VOID_LIMITS)
    end
    phys:SetCapsule(0.5, 1)

    inst.AnimState:SetBank("bat_vamp_shadow")
    inst.AnimState:SetBuild("bat_vamp_shadow")
    inst.AnimState:PlayAnimation("shadow_flap_loop", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetMultColour(1, 1, 1, 0)
    inst.AnimState:SetScale(0.8, 0.8, 0.8)

    inst:AddTag("FX")
    inst:AddTag("vampirebat_shadow")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("glidemotor")
    inst.components.glidemotor.runspeed = 8
    inst.components.glidemotor.runspeed_turnfast = 8
    inst.components.glidemotor.turnspeed = 40
    inst.components.glidemotor.turnspeed_fast = 40
    inst.components.glidemotor:EnableMove(true)
    inst.components.glidemotor.avoid = true
    inst.components.glidemotor.avoidother = true
    inst.components.glidemotor.avoid_must_tags = {"vampirebat_shadow"}
    inst.components.glidemotor.avoid_cant_tags = {"INLIMBO", "NOCLICK"}

    inst:AddComponent("colourtweener")
    UpdateColourTweener(inst)
    inst:DoPeriodicTask(3, UpdateColourTweener, math.random() * 3)

    inst:ListenForEvent("wingdown", OnWingDownShadow)
    -- flap sound
    inst:DoPeriodicTask(10/30, function() inst:PushEvent("wingdown") end)
    -- screech sound
    inst:DoPeriodicTask(1, function()
        if math.random() < 0.1 then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_taunt")
        end
    end)

    inst.scale = 0.8
    inst:DoPeriodicTask(FRAMES, UpdateTraget)

    inst.task, inst.taskinfo = inst:ResumeTask(20 + math.random() * 2, DoDive)

    inst.SetUp = SetUp

    inst.OnSave = OnSaveShadow
    inst.OnLoad = OnLoadShadow
    inst.OnLoadPostPass = OnLoadPostPassShadow

    inst.DoDive = DoDive

    return inst
end

return Prefab("vampirebat", fn, assets, prefabs),
       Prefab("circlingbat", circlingbatfn, assets, prefabs)

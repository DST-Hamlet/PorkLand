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

local function MakeTeam(inst, attacker)
    local leader = SpawnPrefab("teamleader")
    leader:AddTag("vampirebat")
    leader.components.teamleader.mult = 1.5
    leader.components.teamleader:SetUp(attacker, inst)
    leader.components.teamleader:BroadcastDistress(inst)
end

local function OnWingDown(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/flap")
end

local function OnWingDownShadow(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_flap")
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
local RETARGET_CANT_TAGS = {"vampirebat"}
local RETARGET_ONEOF_TAGS = {"character", "monster"}
local function Retarget(inst)
    local ta = inst.components.teamattacker

    local newtarget = FindEntity(inst, RETARGET_DIST, function(ent)
        return inst.components.combat:CanTarget(ent)
    end, nil, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)

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
            return ent:HasTag("vampirebat") and not ent.components.health:IsDead()
        end, MAX_TARGET_SHARES)
    end
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(ent)
        return ent:HasTag("vampirebat") and not ent.components.health:IsDead()
    end, MAX_TARGET_SHARES)
end

local function OnWakeUp(inst)
    inst.forcesleep = false
end

local function OnSave(inst, data)
    if inst:HasTag("batfrenzy") then
        data.batfrenzy = true
    end
    if inst.components.sleeper.hibernate then
        data.forcesleep = true
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

    if data.forcesleep then
        inst.forcesleep = true
        inst.sg:GoToState("forcesleep")
        inst.components.sleeper.hibernate = true
        inst.components.sleeper:GoToSleep()
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

    MakeFlyingCharacterPhysics(inst, 1, 0.5)
    PorkLandMakeInventoryFloatable(inst)

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

    inst:AddComponent("teamattacker")
    inst.components.teamattacker.team_type = "vampirebat"

    inst:SetBrain(brain)
    inst:SetStateGraph("SGvampirebat")

    MakeMediumBurnableCharacter(inst, "bat_body")
    MakeMediumFreezableCharacter(inst, "bat_body")
    MakePoisonableCharacter(inst, "bat_body")
    MakeHauntablePanic(inst)

    inst.cavebat = false
    inst.MakeTeam = MakeTeam
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
    local player = inst.components.circler.circleTarget

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
        inst.components.colourtweener:StartTween({1,1,1,0}, 0.3)
        inst.components.circler:Stop()
        inst:DoTaskInTime(1,inst.Remove)
        return
    end

    -- allow water but not interior
    if player and player:IsValid() and not player:GetIsInInterior() and inst:IsOnPassablePoint(true) then
        local bat = SpawnPrefab("vampirebat")
        local spawn_point = inst:GetPosition()
        if bat and spawn_point then
            bat.Transform:SetPosition(spawn_point.x, spawn_point.y + 30, spawn_point.z)
            bat:FacePoint(player.Transform:GetWorldPosition())
            bat.sg:GoToState("glide")
            bat:AddTag("batfrenzy")

            bat:DoTaskInTime(2, function()
                -- Use Combat:SuggestTarget?
                bat.components.combat:SuggestTarget(player)
            end)
        end
        inst.task = nil
        inst.taskinfo = nil
        inst.components.colourtweener:StartTween({1,1,1,0}, 0.3)
        inst.components.circler:Stop()
        inst:DoTaskInTime(1,inst.Remove)
    else
        inst.task, inst.taskinfo = inst:ResumeTask(5 + math.random() * 2, DoDive)
    end
end


local function CircleOnIsNight(inst)
    if inst.taskinfo ~= nil then
        if TheWorld.state.isnight then
            inst.components.colourtweener:StartTween({1,1,1,0}, 3)
        else
            inst.components.colourtweener:StartTween({1,1,1,1}, 3)
        end
    end
end

local function OnSaveShadow(inst, data)
    if inst.taskinfo then
        data.time = inst:TimeRemainingInTask(inst.taskinfo)
        data.player = inst.components.circler.circleTarget.GUID
        return {player = inst.components.circler.circleTarget.GUID}
    end
end

local function OnLoadShadow(inst, data)
    if not data then
        inst:Remove()
        return
    end

    if data.time then
        inst.task, inst.taskinfo = inst:ResumeTask(data.time, DoDive)
    end
end

local function OnLoadPostPassShadow(inst, ents, data)
    if data and data.player and ents[data.player] then
        inst.components.circler:SetCircleTarget(ents[data.player].entity)
    end

    inst.components.circler.dontfollowinterior = true
    inst.components.circler:Start()
end

local function circlingbatfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("bat_vamp_shadow")
    inst.AnimState:SetBuild("bat_vamp_shadow")
    inst.AnimState:PlayAnimation("shadow_flap_loop", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetMultColour(1, 1, 1, 0)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("circler")
    inst.components.circler.minScale = 10
    inst.components.circler.maxScale = 8

    inst:AddComponent("colourtweener")
    if not TheWorld.state.isnight then
        inst.components.colourtweener:StartTween({1,1,1,1}, 3)
    end

    inst:ListenForEvent("wingdown", OnWingDownShadow)
    -- flap sound
    inst:DoPeriodicTask(10/30, function() inst:PushEvent("wingdown") end)
    -- screech sound
    inst:DoPeriodicTask(1, function()
        if math.random() < 0.1 then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_taunt")
        end
    end)

    inst:WatchWorldState("isnight", CircleOnIsNight)
    inst:WatchWorldState("isday", CircleOnIsNight)

    inst.task, inst.taskinfo = inst:ResumeTask(20 + math.random() * 2, DoDive)

    inst.OnSave = OnSaveShadow
    inst.OnLoad = OnLoadShadow
    inst.OnLoadPostPass = OnLoadPostPassShadow

    inst.DoDive = DoDive

    inst.persists = false

    return inst
end

return Prefab("vampirebat", fn, assets, prefabs) ,
       Prefab("circlingbat", circlingbatfn, assets, prefabs)

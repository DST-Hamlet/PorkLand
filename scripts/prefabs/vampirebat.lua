require "brains/vampirebatbrain"
require "stategraphs/SGvampirebat"

local assets=
{
    Asset("ANIM", "anim/bat_basic.zip"),
    Asset("ANIM", "anim/bat_vamp_build.zip"),
    Asset("ANIM", "anim/bat_vamp_shadow.zip"),
    Asset("SOUND", "sound/bat.fsb"),
    Asset("INV_IMAGE", "bat"),
}

local prefabs =
{
    "guano",
    "vampire_bat_wing",
    "bat_hide",
}

SetSharedLootTable( 'vampirebat',
{
    {'monstermeat',0.50},
    {'bat_hide',0.50},
    {'vampire_bat_wing',0.10},
})

local SLEEP_DIST_FROMHOME = 1
local SLEEP_DIST_FROMTHREAT = 12
local MAX_CHASEAWAY_DIST = 80
local MAX_TARGET_SHARES = 100
local SHARE_TARGET_DIST = 100

local function MakeTeam(inst, attacker)
    local leader = SpawnPrefab("teamleader")
    leader:AddTag("vampirebat")
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
    if (inst.components.teamattacker.teamleader and not inst.components.teamattacker.teamleader:CanAttack()) or
        inst.components.teamattacker.orders == "ATTACK" then
        return true
    else
        return false
    end
end

local RETARGET_CANT_TAGS = {"bat"}
local RETARGET_ONEOF_TAGS = {"character", "monster"}
local function Retarget(inst)
    local ta = inst.components.teamattacker

    local newtarget = FindEntity(inst, TUNING.VAMPIREBAT_TARGET_DIST, function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        nil,
        RETARGET_CANT_TAGS,
        RETARGET_ONEOF_TAGS
    )
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
        inst.components.teamattacker.teamleader:BroadcastDistress()   --Ask for  help!
    end

    if inst.components.teamattacker.inteam and not inst.components.teamattacker.teamleader:CanAttack() then
        local attacker = data and data.attacker
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("vampirebat") end, MAX_TARGET_SHARES)
    end
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("vampirebat") and not dude.components.health:IsDead() end, 5)
end

local function OnWakeUp(inst)
    inst.forcesleep = false
end

local function onsave(inst, data)
    if inst:HasTag("batfrenzy") then
        data.batfrenzy = true
    end
    if inst.forcesleep then
        data.forcesleep = true
    end
    if inst.sg:HasStateTag("flying") then
        data.flying = true
    end
end

local function onload(inst, data)
    if data then
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
end

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    shadow:SetSize( 1.5, .75 )
    inst.Transform:SetFourFaced()

    local scaleFactor = 0.9
    inst.AnimState:SetScale(scaleFactor, scaleFactor, scaleFactor)

    --MakeGhostPhysics(inst, 1, .5)
    MakeFlyingCharacterPhysics(inst, 1, .5)
    MakePoisonableCharacter(inst, "bat_body")

    inst:AddTag("vampirebat")
    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("flying")

    anim:SetBank("bat")
    anim:SetBuild("bat_vamp_build")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true, allowocean = true }
    inst.components.locomotor.walkspeed = TUNING.VAMPIREBAT_WALK_SPEED

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
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

    inst:SetStateGraph("SGvampirebat")

    local brain = require "brains/vampirebatbrain"
    inst:SetBrain(brain)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('vampirebat')

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:DoTaskInTime(1*FRAMES, function() inst.components.knownlocations:RememberLocation("home", Vector3(inst.Transform:GetWorldPosition()), true) end)

    inst:ListenForEvent("wingdown", OnWingDown)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("onwakeup", OnWakeUp)

    inst:AddComponent("teamattacker")
    inst.components.teamattacker.team_type = "vampirebat"
    inst.MakeTeam = MakeTeam

    MakeMediumBurnableCharacter(inst, "bat_body")
    MakeMediumFreezableCharacter(inst, "bat_body")
    MakeHauntablePanic(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    inst.cavebat = false

    return inst
end

-----------------------------------------------------------------------------------

local function DoDive(inst)
    if not TheCamera.interior and inst:IsOnValidGround() then
        local bat = SpawnPrefab("vampirebat")
        local spawn_pt = Vector3(inst.Transform:GetWorldPosition())
        if bat and spawn_pt then
            local x,y,z  = spawn_pt:Get()
            bat.Transform:SetPosition(x,y+30,z)
            bat:FacePoint(GetPlayer().Transform:GetWorldPosition())
            bat.sg:GoToState("glide")
            bat:AddTag("batfrenzy")

            bat:DoTaskInTime(2,function()  bat:PushEvent("attacked", {attacker = GetPlayer(), damage = 0, weapon = nil}) end)
        end
        inst:Remove()
    else
        inst.task, inst.taskinfo = inst:ResumeTask(5+(math.random()*2), DoDive)
    end
end

local MAX_FADE_FRAME = math.floor(3 / FRAMES + .5)

local function OnUpdateFade(inst, dframes)
    local done
    if inst._isfadein:value() then
        local frame = inst._fadeframe:value() + dframes
        done = frame >= MAX_FADE_FRAME
        inst._fadeframe:set_local(done and MAX_FADE_FRAME or frame)
    else
        local frame = inst._fadeframe:value() - dframes
        done = frame <= 0
        inst._fadeframe:set_local(done and 0 or frame)
    end

    local k = inst._fadeframe:value() / MAX_FADE_FRAME
    inst.AnimState:OverrideMultColour(1, 1, 1, k)

    if done then
        inst._fadetask:Cancel()
        inst._fadetask = nil
        if inst._killed then
            --don't need to check ismastersim, _killed will never be set on clients
            inst:Remove()
            return
        end
    end

    if TheWorld.ismastersim then
        if inst._fadeframe:value() > 0 then
            inst:Show()
        else
            inst:Hide()
        end
    end
end

local function OnFadeDirty(inst)
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade, nil, 1)
    end
    OnUpdateFade(inst, 0)
end

local function CircleOnIsNight(inst, isnight)
    inst._isfadein:set(not isnight)
    inst._fadeframe:set(inst._fadeframe:value())
    OnFadeDirty(inst)
end

local function CircleOnInit(inst)
    inst:WatchWorldState("isnight", CircleOnIsNight)
    CircleOnIsWinter(inst, TheWorld.state.isnight)
end

local function OnSaveShadow(inst, data)
    if inst.taskinfo then
        data.time = inst:TimeRemainingInTask(inst.taskinfo)
    end
end

local function OnLoadShadow(inst, data)
    if data then
        if data.time then
            inst.task, inst.taskinfo = inst:ResumeTask(data.time, Dodive)
        end
    end
end

local function OnLoadPostPassShadow(inst)
    inst.components.circler:SetCircleTarget(GetPlayer())
    inst.components.circler.dontfollowinterior = true
    inst.components.circler:Start()
end

local function circlingbatfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("bat_vamp_shadow")
    inst.AnimState:SetBuild("bat_vamp_shadow")
    inst.AnimState:PlayAnimation("shadow_flap_loop", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:OverrideMultColour(1, 1, 1, 0)

    inst:AddTag("FX")

    inst._fadeframe = net_byte(inst.GUID, "circlingbuzzard._fadeframe", "fadedirty")
    inst._isfadein = net_bool(inst.GUID, "circlingbuzzard._isfadein", "fadedirty")
    inst._fadetask = nil

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("fadedirty", OnFadeDirty)

        return inst
    end

    inst:AddComponent("circler")

    inst:ListenForEvent("wingdown", OnWingDownShadow)
    -- flap sound
    inst:DoPeriodicTask(10/30, function() inst:PushEvent("wingdown") end)
    -- screech sound
    inst:DoPeriodicTask(1, function() if math.random()<0.1 then inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_taunt") end end)

    inst:DoTaskInTime(0, CircleOnInit)

    inst.task, inst.taskinfo = inst:ResumeTask(20+(math.random()*2), Dodive)

    inst.OnSave = OnSaveShadow
    inst.OnLoad = OnLoadShadow
    inst.OnLoadPostPass = OnLoadPostPassShadow

    inst.KillShadow = KillShadow
    inst.DoDive = DoDive

    inst.persists = false

    return inst
end

return Prefab("vampirebat", fn, assets, prefabs) ,
       Prefab("circlingbat", circlingbatfn, assets, prefabs)


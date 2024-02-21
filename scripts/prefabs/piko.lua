local assets =
{
    Asset("ANIM", "anim/ds_squirrel_basic.zip"),
    Asset("ANIM", "anim/squirrel_cheeks_build.zip"),
    Asset("ANIM", "anim/squirrel_build.zip"),

    Asset("ANIM", "anim/orange_squirrel_cheeks_build.zip"),
    Asset("ANIM", "anim/orange_squirrel_build.zip"),
}

local prefabs =
{
    "smallmeat",
    "cookedsmallmeat",
}

SetSharedLootTable("piko",
{
    {"smallmeat", 1},
})

local brain = require("brains/pikobrain")

local INTENSITY = .5

local function Retarget(inst)
    return FindEntity(inst, TUNING.PIKO_TARGET_DIST, function(guy)
        return not guy:HasTag("piko") and inst.components.combat:CanTarget(guy) and guy.components.inventory and (guy.components.inventory:NumItems() > 0)
    end)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and inst.is_rabid
end

-- region animation
local function UpdateBuild(inst, cheeks)
    local build = "squirrel_build"

    if cheeks then
        build = "squirrel_cheeks_build"
    end

    if inst:HasTag("orange") then
        build = "orange_" .. build
    end

    inst.AnimState:SetBuild(build)
end

local function RefreshBuild(inst)
    UpdateBuild(inst, inst.components.inventory:NumItems() > 0)
end

local function FadeIn(inst)
    inst.components.fader:StopAll()

    inst.AnimState:Show("eye_red")
    inst.AnimState:Show("eye2_red")

    inst.Light:Enable(true)
    if inst:IsAsleep() then
        inst.Light:SetIntensity(INTENSITY)
    else
        inst.Light:SetIntensity(0)
        inst.components.fader:Fade(0, INTENSITY, 3 + math.random() * 2, function(v) inst.Light:SetIntensity(v) end)
    end
end

local function FadeOut(inst)
    inst.components.fader:StopAll()

    inst.AnimState:Hide("eye_red")
    inst.AnimState:Hide("eye2_red")

    if inst:IsAsleep() then
        inst.Light:SetIntensity(0)
    else
        inst.components.fader:Fade(INTENSITY, 0, 0.75 + math.random(), function(v) inst.Light:SetIntensity(v) end)
    end
end

local function UpdateLight(inst)
    local outside = not inst.components.homeseeker or not inst.components.homeseeker.home or not inst.components.homeseeker.home.components.spawner:IsOccupied()
    outside = not inst.components.inventoryitem.owner and outside

    if inst.is_rabid and outside then
        if not inst.lighton then
            inst:DoTaskInTime(math.random() * 2, FadeIn)
        else
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end

        inst.lighton = true

        inst.AnimState:Show("eye_red")
        inst.AnimState:Show("eye2_red")
    else
        if inst.lighton then
            inst:DoTaskInTime(math.random() * 2, FadeOut)
        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end

        inst.AnimState:Hide("eye_red")
        inst.AnimState:Hide("eye2_red")

        inst.lighton = false
    end
end

local function SetAsRabid(inst, rabid)
    inst.is_rabid = rabid
    inst.components.sleeper:SetNocturnal(rabid)
    UpdateLight(inst)
end
-- endregion

-- region event handlers
local MUST_TAGS = {"piko"}
local function OnAttacked(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, MUST_TAGS)

    local max_friend_num = 5
    for i = 1, max_friend_num do
        if not ents[i] then
            break
        end
        ents[i]:PushEvent("gohome")
    end
end

local function OnCooked(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/scream")
end

local function OnDeath(inst)
    inst.Light:Enable(false)
end

local function OnDropped(inst)
    RefreshBuild(inst)
    UpdateLight(inst)
    inst.sg:GoToState("stunned")
end

local function OnPickupedorTrapped(inst)
    inst.components.inventory:DropEverything(false, false)
end

local function OnPickup(inst)
    UpdateBuild(inst, true)
end

local function OnPhaseChange(inst)
    if TheWorld.state.phase == "night" and (TheWorld.state.moonphase == "full" or TheWorld.state.moonphase == "blood") then
        if not inst.is_rabid then
            inst:DoTaskInTime(1 + math.random(), SetAsRabid, true)
        end
    else
        if inst.is_rabid then
            inst:DoTaskInTime(1 + math.random(), SetAsRabid, false)
        end
    end
end

local function OnWentHome(inst)
    local tree = inst.components.homeseeker and inst.components.homeseeker.home or nil
    if not tree then
        return
    end

    if tree.components.inventory then
        inst.components.inventory:TransferInventory(tree)
        UpdateBuild(inst, false)
    end

    UpdateLight(inst)
end

-- endregion

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("squirrel")
    inst.AnimState:SetBuild("squirrel_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst.DynamicShadow:SetSize(1, 0.75)

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetColour(150/255, 40/255, 40/255)
    inst.Light:SetFalloff(0.9)
    inst.Light:SetRadius(2)
    inst.Light:Enable(false)

    MakeCharacterPhysics(inst, 1, 0.12)

    inst:AddTag("animal")
    inst:AddTag("canbetrapped")
    inst:AddTag("cannotstealequipped")
    inst:AddTag("catfood")
    inst:AddTag("cattoy")
    inst:AddTag("piko")
    inst:AddTag("prey")
    inst:AddTag("smallcreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.is_rabid = false

    inst:AddComponent("thief")

    inst:AddComponent("fader")

    inst:AddComponent("inventory")

    -- inst:AddComponent("sanityaura")

    inst:AddComponent("homeseeker")

    inst:AddComponent("knownlocations")

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("sleeper")

    inst:AddComponent("locomotor")  -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIKO_RUN_SPEED

    -- Squirrels (ie. pikos), have the same diet as birds, mainly seeds,
    -- which is why this is being set on a non-avian creature.
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.SEEDS}, {FOODTYPE.SEEDS})

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPickupFn(OnPickupedorTrapped)
    -- inst.components.inventoryitem:SetOnDroppedFn(OnDropped)  -- Done in MakeFeedableSmallLivestock
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false

    inst:AddComponent("cookable")
    inst.components.cookable.product = "cookedsmallmeat"
    inst.components.cookable:SetOnCookedFn(OnCooked)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.PIKO_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PIKO_ATTACK_PERIOD)
    inst.components.combat:SetRange(0.7)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat.hiteffectsymbol = "chest"
    inst.components.combat.onhitotherfn = function(inst, other) inst.components.thief:StealItem(other) end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PIKO_HEALTH)
    inst.components.health.murdersound = "dontstarve_DLC003/creatures/piko/death"

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable({"piko"})

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpiko")

    inst:WatchWorldState("phase", OnPhaseChange)
    inst:WatchWorldState("moonphase", OnPhaseChange)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ondropped", UpdateLight)
    inst:ListenForEvent("trapped", OnPickupedorTrapped)
    inst:ListenForEvent("onpickupitem", OnPickup)

    inst.force_onwenthome_message = true  -- for onwenthome event
    inst:ListenForEvent("onwenthome", OnWentHome)

    inst.OnLoad = RefreshBuild
    inst.UpdateLight = UpdateLight -- called in teatrees.lua

    MakeSmallBurnableCharacter(inst, "torso")
    MakeTinyFreezableCharacter(inst, "torso")
    MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME * 2, nil, OnDropped)
    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)

    -- When a piko is first created, ensure that it isn't rabid.
    SetAsRabid(inst, false)

    OnPhaseChange(inst)

    return inst
end

local function orangefn()
    local inst = fn()

    inst:AddTag("orange")

    if not TheWorld.ismastersim then
        return inst
    end

    UpdateBuild(inst)

    return inst
end

return Prefab("piko", fn, assets, prefabs),
       Prefab("piko_orange", orangefn, assets, prefabs)

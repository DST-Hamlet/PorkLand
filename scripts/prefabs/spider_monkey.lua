local assets =
{
    Asset("ANIM", "anim/spiderape_basics.zip"),
    Asset("ANIM", "anim/spiderape_build.zip"),
}

local prefabs =
{
    "poop",
    "monkeyprojectile",
    "monstermeat",
    "spidergland",
}

local MAX_CHASEAWAY_DIST = 32
local MAX_POOP_COUNT = 3

SetSharedLootTable("spidermonkey", {
    {"monstermeat",     1.0},
    {"monstermeat",     1.0},
    {"spidergland",    0.75},
    {"beardhair",      0.75},
    {"beardhair",      0.75},
    {"beardhair",      0.75},
    {"silk",           0.25},
})

local function OnEat(inst)
    -- Monkey ate some food. Give him some poop!
    local poop_stack = inst.components.inventory:FindItem(function(item) return item.prefab == "poop" end)
    if (not poop_stack) or (poop_stack and poop_stack.components.stackable.stacksize < MAX_POOP_COUNT) then
        local new_poop = SpawnPrefab("poop")
        inst.components.inventory:GiveItem(new_poop)
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SuggestTarget(data.attacker)
end

local function FindThreatToNest(inst)
    local notags = {"FX", "NOCLICK", "INLIMBO", "spidermonkey"}
    local yestags = {"character", "animal", "monster"}
    if inst.components.homeseeker and inst.components.homeseeker:HasHome() then
        return FindEntity(inst.components.homeseeker.home, TUNING.SPIDER_MONKEY_DEFEND_DIST, function(guy)
            return guy.components.health
                and not guy.components.health:IsDead()
                and inst.components.combat:CanTarget(guy)
        end, nil, notags, yestags)
    end
end

local function RetargetFn(inst)
    local newtarget = FindThreatToNest(inst)

    if not newtarget then
        local notags = {"FX", "NOCLICK", "INLIMBO", "aquatic", "werepig"}
        local yestags = {"pig"}
        newtarget = FindEntity(inst,TUNING.SPIDER_MONKEY_TARGET_DIST, function(guy)
            return guy.components.health
                and not guy.components.health:IsDead()
                and inst.components.combat:CanTarget(guy)
        end, yestags, notags)
    end

    if not newtarget then
        local notags = {"FX", "NOCLICK", "INLIMBO", "aquatic", "spidermonkey", "aquatic"}
        local yestags = {"character", "monster"}
        newtarget = FindEntity(inst,TUNING.SPIDER_MONKEY_TARGET_DIST, function(guy)
            return  guy.components.health
            and not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy)
        end, nil, notags, yestags)
    end

    return newtarget
end

local function KeepTargetFn(inst, target)
    local home = inst.components.homeseeker and inst.components.homeseeker.home

    if home then
        return inst:GetDistanceSqToInst(home) < MAX_CHASEAWAY_DIST * MAX_CHASEAWAY_DIST
    else
        return true
    end
end

local function OnNear(inst)
    inst:AddTag("agitated")
    inst:PushEvent("agitated")
end

local function OnFar(inst)
    inst:RemoveTag("agitated")
end

local function OnPooped(inst, poop)
    local heading_angle = -(inst.Transform:GetRotation()) + 180

    local pos = inst:GetPosition()
    pos.x = pos.x + math.cos(heading_angle * DEGREES)
    pos.y = pos.y + 0.3
    pos.z = pos.z + math.sin(heading_angle * DEGREES)
    poop.Transform:SetPosition(pos.x, pos.y, pos.z)

    if poop.components.inventoryitem ~= nil and poop.components.inventoryitem.is_landed then
        poop.components.inventoryitem:SetLanded(false, true)
    end
end

local function OnSave(inst, data)
    if inst.tree and inst.tree:IsValid() then
        data.tree = inst.tree.GUID
        data.inherd = inst.inherd -- added to a herd
        return {tree = inst.tree.GUID}
    end
end

local function OnLoadPostPass(inst, newents, data)
    if not data or not data.inherd then
        TheWorld.components.spidermonkeyherd:AddToHerd(inst)
    end

    if data and data.tree then
        inst.tree = newents[data.tree].entity
    end
end

local FIND_TREE_DIST = 7
local FIND_TREE_MUST_TAGS = {"rainforesttree"}
local FIND_TREE_NO_TAGS = {"spider_monkey_tree", "has_monkey", "burnt", "stump"}

local function OnEntitySleep(inst)
    if inst.tree and inst.tree:IsValid() then
        return
    end

    local tree = FindEntity(inst, FIND_TREE_DIST, nil, FIND_TREE_MUST_TAGS, FIND_TREE_NO_TAGS)

    if tree and tree:IsValid() then
        inst.tree = ReplacePrefab(tree, "spider_monkey_tree")
        inst.tree:AddTag("has_monkey")
    end
end

local brain = require("brains/spidermonkeybrain")

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 40, 1.5)

    inst.AnimState:SetBank("spiderape")
    inst.AnimState:SetBuild("SpiderApe_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.DynamicShadow:SetSize(2, 1.25)

    inst.Transform:SetFourFaced()

    inst:AddTag("spider_monkey")
    inst:AddTag("animal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")

    inst:AddComponent("thief")

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = {ignorecreep = false}
    inst.components.locomotor.walkspeed = TUNING.SPIDER_MONKEY_SPEED_AGITATED
    inst.components.locomotor.runspeed = TUNING.SPIDER_MONKEY_SPEED_AGITATED

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_MONKEY_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.SPIDER_MONKEY_MELEE_RANGE)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_MONKEY_DAMAGE)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SPIDER_MONKEY_HEALTH)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("poop")
    inst.components.periodicspawner:SetRandomTimes(200, 400)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(15)
    inst.components.periodicspawner:SetOnSpawnFn(OnPooped)
    inst.components.periodicspawner:Start()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("spidermonkey")
    inst.components.lootdropper.droppingchanceloot = false

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.VEGGIE}, {FOODTYPE.VEGGIE})
    inst.components.eater:SetOnEatFn(OnEat)

    inst:AddComponent("sleeper")

    inst:AddComponent("knownlocations")

    -- inst:AddComponent("herdmember")
    -- inst.components.herdmember:SetHerdPrefab("spider_monkey_herd")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(20, 23)
    inst.components.playerprox:SetOnPlayerNear(OnNear)
    inst.components.playerprox:SetOnPlayerFar(OnFar)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    MakeHauntablePanic(inst)
    MakeLargeBurnableCharacter(inst, "body")
    MakeLargeFreezableCharacter(inst, "body")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGspidermonkey")

    inst:ListenForEvent("attacked", OnAttacked)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntitySleep = OnEntitySleep
    inst.tree = nil

    return inst
end

return Prefab("spider_monkey", fn, assets, prefabs)

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
    inst.components.combat:SetTarget(data.attacker)
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

local FIND_WEB_TREE_DIST = 7
local FIND_TREE_DIST = 30
local FORGET_TREE_DIST = FIND_TREE_DIST + 10
local FIND_WEB_TREE_MUST_TAGS = {"rainforesttree", "spider_monkey_tree"}
local FIND_WEB_TREE_NOT_TAGS = {"burnt", "stump", "rotten"}
local FIND_TREE_MUST_TAGS = {"rainforesttree"}
local FIND_TREE_NO_TAGS = {"has_spider", "burnt", "stump", "rotten"}

local OnTreeDestroyed

local function BindWithTree(inst, tree)
    if not tree or not tree:IsValid() then
        return
    end

    inst.tree = tree
    inst.target_tree = nil
    inst.old_tree_pos = nil

    tree.monkey = inst
    tree:AddTag("has_spider")

    -- when the tree is burnt, chopped down or deleted, unbind with monkey
    tree:ListenForEvent("burnt", OnTreeDestroyed)
    tree:ListenForEvent("workfinished", OnTreeDestroyed)
    tree:ListenForEvent("onremove", OnTreeDestroyed)
end

local function UnbindWithTree(inst, tree)
    inst.tree = nil

    if not tree or not tree:IsValid() then
        return
    end

    tree.monkey = nil
    tree:RemoveTag("has_spider")

    -- no longer binded with a monkey, remove those listeners
    tree:RemoveEventCallback("burnt", OnTreeDestroyed)
    tree:RemoveEventCallback("workfinished", OnTreeDestroyed)
    tree:RemoveEventCallback("onremove", OnTreeDestroyed)
end

OnTreeDestroyed = function(inst)
    if not inst.monkey or not inst.monkey:IsValid() then
        return
    end

    inst.monkey.old_tree_pos = inst:GetPosition()
    UnbindWithTree(inst.monkey, inst)
end

local function InfectTrees(inst, tree)
    if tree:HasTag("has_spider") then
        inst.target_tree = nil
        return false
    end

    if not tree:HasTag("spider_monkey_tree") then
        local stage = tree.stage
        tree = ReplacePrefab(tree, "spider_monkey_tree")
        tree.components.growable:SetStage(stage)
        tree:PlayWebFX()
    end

    BindWithTree(inst, tree)

    local x, y, z = tree.Transform:GetWorldPosition()
    local nearby_trees = TheSim:FindEntities(x, y, z, FIND_WEB_TREE_DIST, FIND_TREE_MUST_TAGS, FIND_TREE_NO_TAGS)

    for _, new_tree in pairs(nearby_trees) do
        if new_tree ~= tree and not new_tree:HasTag("spider_monkey_tree") then
            local stage = new_tree.stage
            new_tree = ReplacePrefab(new_tree, "spider_monkey_tree")
            new_tree.components.growable:SetStage(stage)
            new_tree:PlayWebFX()
        end
    end

    return true
end

-- not deleted, not burnt, not chopped, not rotten
local function is_valid_tree(tree)
    return tree and tree:IsValid()
        and not tree:HasTag("burnt")
        and not tree:HasTag("stump")
        and not tree:HasTag("rotten")
end

local function is_valid_target_tree(tree)
    return is_valid_tree(tree) and not tree:HasTag("has_spider")
end

local function UpdateTreeStatus(inst)
    if is_valid_tree(inst.tree) then
        if inst:GetDistanceSqToInst(inst.tree) <= FIND_TREE_DIST * FIND_TREE_DIST then -- tree is still habitable
            return
        elseif inst:GetDistanceSqToInst(inst.tree) > FORGET_TREE_DIST * FORGET_TREE_DIST then -- too far away, find new home
            UnbindWithTree(inst, inst.tree)
        end
    end

    if is_valid_target_tree(inst.target_tree) then
        if inst:GetDistanceSqToInst(inst.target_tree) <= FIND_TREE_DIST * FIND_TREE_DIST  then -- close enough for infecting
            if inst:IsAsleep() and inst.target_tree:IsAsleep() then -- only off screen
                InfectTrees(inst, inst.target_tree)
            end
            return
        elseif inst:GetDistanceSqToInst(inst.target_tree) > FORGET_TREE_DIST * FORGET_TREE_DIST then -- too far away, find new home
            inst.target_tree = nil
        end
    else
        inst.target_tree = nil -- no longer valid, forget about it
    end

    if inst.old_tree_pos then
        local x, y, z = inst.old_tree_pos:Get()
        local infected_tree = TheSim:FindEntities(x, y, z, FIND_TREE_DIST, FIND_WEB_TREE_MUST_TAGS, FIND_TREE_NO_TAGS)
        local tree
        for i, ent in ipairs(infected_tree) do
            local other_monkey_tree = FindEntity(ent, 7, function(ent)
                local other_monkey_tree = FindEntity(ent, 7, nil, {"has_spider"}, {"burnt", "stump", "rotten"})
                return other_monkey_tree == nil
            end, {"spider_monkey_tree"}, FIND_TREE_NO_TAGS)
            local x, y, z = ent.Transform:GetWorldPosition()
            local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
            if other_monkey_tree == nil
                and inst:GetDistanceSqToInst(ent) <= FIND_TREE_DIST * FIND_TREE_DIST
                and tile == WORLD_TILES.DEEPRAINFOREST then
                    tree = ent
                    break
            end
        end

        if tree then
            inst.target_tree = tree
        end
    end

    if not inst.target_tree then -- can't find a tree next to old home or this is the first tree
        local tree = FindEntity(inst, 30, function(ent)
            local other_monkey_tree = FindEntity(ent, 7, nil,
                {"has_spider", "spider_monkey_tree"}, FIND_WEB_TREE_NOT_TAGS)
            local x, y, z = ent.Transform:GetWorldPosition()
            local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
            return other_monkey_tree == nil and tile == WORLD_TILES.DEEPRAINFOREST
        end, FIND_TREE_MUST_TAGS, FIND_TREE_NO_TAGS)

        if tree then
            inst.target_tree = tree
        end
    end

    if not is_valid_target_tree(inst.target_tree) then -- failed to find suitable tree
        return
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
    if data and data.tree then
        inst.tree = newents[data.tree].entity
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

    inst:DoPeriodicTask(0 + math.random() * 0.1, UpdateTreeStatus)

    inst:DoTaskInTime(0, function() TheWorld.components.spidermonkeyherd:AddToHerd(inst) end)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass
    inst.MakeHomeAction = InfectTrees

    inst.tree = nil -- 当前的巢穴树
    inst.target_tree = nil -- 准备去作为巢穴的树

    return inst
end

return Prefab("spider_monkey", fn, assets, prefabs)

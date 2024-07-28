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

local FIND_WEB_TREE_DIST = 7
local FIND_TREE_DIST = 30
local FORGET_TREE_DIST = FIND_TREE_DIST + 10
local FIND_WEB_TREE_MUST_TAGS = {"rainforesttree", "spider_monkey_tree"}
local FIND_TREE_MUST_TAGS = {"rainforesttree"}
local FIND_TREE_NO_TAGS = {"has_monkey", "burnt", "stump", "rotten"}

local function ForgetTree(inst)
    if inst.tree and inst.tree:IsValid() and inst.tree:HasTag("has_spider") then
        inst.tree:RemoveTag("has_spider")
    end
    inst.tree = nil
end

local function UpdateTree(inst) -- 判断蜘蛛猴是否需要寻找新的巢穴树，并且寻找新的巢穴树
    local x, y, z = inst.Transform:GetWorldPosition()

    if inst.tree and inst.tree:IsValid() -- 有巢穴树
        and not inst.tree:HasTag("burnt")
        and not inst.tree:HasTag("stump")
        and not inst.tree:HasTag("rotten") then
            if inst.tree:GetDistanceSqToPoint(x, 0, z) < FIND_TREE_DIST * FIND_TREE_DIST then -- 离得足够近，就不寻找新的树
                return
            elseif inst.tree:GetDistanceSqToPoint(x, 0, z) < FIND_TREE_DIST * FIND_TREE_DIST then -- 离得足够远，就强制忘记旧的树
                inst:ForgetTree()
            end
    else
        inst:ForgetTree()
    end

    if inst.targettree and inst.targettree:IsValid() -- 有找到的可以变成巢穴树的树
        and not inst.targettree:HasTag("burnt")
        and not inst.targettree:HasTag("stump")
        and not inst.targettree:HasTag("rotten")
        and not inst.targettree:HasTag("has_spider") then
            if inst.targettree:GetDistanceSqToPoint(x, 0, z) < FIND_TREE_DIST * FIND_TREE_DIST then -- 离得足够近
                if inst:IsAsleep() and inst.targettree:IsAsleep() then
                    inst:MakeHomeAction(inst.targettree)
                end
                return
            elseif inst.targettree:GetDistanceSqToPoint(x, 0, z) < FIND_TREE_DIST * FIND_TREE_DIST then
                inst.targettree = nil
            end
    else
        inst.targettree = nil
    end

    -- 先寻找不属于其他蜘蛛猴并且离其他蜘蛛猴的巢穴树保持一定距离的蛛网树
    local tree = FindEntity(inst, FIND_WEB_TREE_DIST, function(ent)
            local other_monkey_tree = FindEntity(ent, 7, nil, {"has_spider"}, {"burnt", "stump", "rotten"})
            return other_monkey_tree == nil
        end, FIND_WEB_TREE_MUST_TAGS, FIND_TREE_NO_TAGS)

    if tree and tree:IsValid() then
        inst.targettree = tree
        return
    end

    -- 如果找不到符合条件的蛛网树，那么扩大搜索范围和目标
    tree = FindEntity(inst, FIND_TREE_DIST, function(ent)
        local other_monkey_tree = FindEntity(ent, 7, nil, {"has_spider"}, {"burnt", "stump", "rotten"})
        return other_monkey_tree == nil
    end, FIND_TREE_MUST_TAGS, FIND_TREE_NO_TAGS)

    if tree and tree:IsValid() then
        inst.targettree = tree
        return
    end
end

local function TryReplaceTree(inst, tree)
    if tree:HasTag("has_spider") then
        inst.targettree = nil
        return false
    end

    local newtree = inst.targettree
    if not tree:HasTag("spider_monkey_tree") then
        local stage = tree.stage
        newtree = ReplacePrefab(tree, "spider_monkey_tree")
        newtree.components.growable:SetStage(stage)
        newtree:PlayWebFX()
    end
    inst.tree = newtree
    inst.targettree = nil
    newtree:AddTag("has_spider")

    local x, y, z = newtree.Transform:GetWorldPosition()
    local neighbortrees = TheSim:FindEntities(x, y, z, 7, {"rainforesttree"}, {"burnt", "stump", "rotten", "spider_monkey_tree"})

    if neighbortrees then
        for i, neighbortree in ipairs(neighbortrees) do
            local newneighbortree = ReplacePrefab(neighbortree, "spider_monkey_tree")
            newneighbortree:PlayWebFX()
        end
    end

    return true
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

    inst:DoPeriodicTask(15 + math.random() * 15, UpdateTree)

    MakeHauntablePanic(inst)
    MakeLargeBurnableCharacter(inst, "body")
    MakeLargeFreezableCharacter(inst, "body")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGspidermonkey")

    inst:ListenForEvent("attacked", OnAttacked)

    inst.ForgetTree = ForgetTree
    inst.UpdateTree = UpdateTree
    inst.MakeHomeAction = TryReplaceTree

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass
    inst.tree = nil -- 当前的巢穴树
    inst.targettree = nil -- 准备去作为巢穴的树

    return inst
end

return Prefab("spider_monkey", fn, assets, prefabs)

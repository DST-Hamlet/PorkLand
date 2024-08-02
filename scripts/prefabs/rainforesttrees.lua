local assets =
{
    Asset("ANIM", "anim/tree_forest_rot_build.zip"),
    Asset("ANIM", "anim/tree_rainforest_gas_build.zip"),
    Asset("ANIM", "anim/tree_forest_bloom_build.zip"),
    Asset("ANIM", "anim/tree_rainforest_web_build.zip"),
    Asset("ANIM", "anim/tree_rainforest_build.zip"),
    Asset("ANIM", "anim/tree_rainforest_bloom_build.zip"),
    Asset("ANIM", "anim/tree_rainforest_normal.zip"),
    Asset("ANIM", "anim/tree_rainforest_short.zip"),
    Asset("ANIM", "anim/tree_rainforest_tall.zip"),
    Asset("ANIM", "anim/tree_rainforest_changetoweb.zip"),
    Asset("ANIM", "anim/dust_fx.zip"),
}

local prefabs =
{
    "log",
    "charcoal",
    "chop_mangrove_pink",
    "fall_mangrove_pink",
    "snake_amphibious",
    "bird_egg",
    "scorpion",
    "burr",
}

SetSharedLootTable("rainforesttree_short",
{
    {"log", 1.0},
})

SetSharedLootTable("rainforesttree_normal",
{
    {"log", 1.0},
    {"log", 1.0},
})

SetSharedLootTable("rainforesttree_tall",
{
    {"log", 1.0},
    {"log", 1.0},
    {"log", 1.0},
})

SetSharedLootTable("spider_monkey_tree_short",
{
    {"log", 1.0},
    {"silk", 1.0},
})

SetSharedLootTable("spider_monkey_tree_normal",
{
    {"log", 1.0},
    {"log", 1.0},
    {"silk", 1.0},
    {"silk", 1.0},
})

SetSharedLootTable("spider_monkey_tree_tall",
{
    {"log", 1.0},
    {"log", 1.0},
    {"log", 1.0},
    {"silk", 1.0},
    {"silk", 1.0},
})

local function MakeAnims(stage)
    return {
        idle = "idle_" .. stage,
        sway1 = "sway1_loop_" .. stage,
        sway2 = "sway2_loop_" .. stage,
        chop = "chop_" .. stage,
        fallleft = "fallleft_" .. stage,
        fallright = "fallright_" .. stage,
        stump = "stump_" .. stage,
        burning = "burning_loop_" .. stage,
        burnt = "burnt_" .. stage,
        chop_burnt = "chop_burnt_" .. stage,
        idle_chop_burnt = "idle_chop_burnt_" .. stage,
        blown1 = "blown_loop_" .. stage .. "1",
        blown2 = "blown_loop_" .. stage .. "2",
        blown_pre = "blown_pre_" .. stage,
        blown_pst = "blown_pst_" .. stage
    }
end

local anims = {
    MakeAnims("short"),
    MakeAnims("normal"),
    MakeAnims("tall"),
}

local function GetStatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

local function PushSway(inst)
    inst.AnimState:PushAnimation(math.random() < 0.5 and anims[inst.stage].sway1 or anims[inst.stage].sway2, true)
end

local function Sway(inst)
    inst.AnimState:PlayAnimation(math.random() < 0.5 and anims[inst.stage].sway1 or anims[inst.stage].sway2, true)
    inst.AnimState:SetTime(math.random() * 2)
end

local scales = {
    short = 0.9,
    normal = 0.8,
    tall = 0.7,
}

local STAGES = {
    [1] = "short",
    [2] = "normal",
    [3] = "tall",
}

local function GetStageFn(stage)
    return function(inst)
        inst.stage = inst.components.growable.stage
        if inst.components.workable then
            inst.components.workable:SetWorkLeft(TUNING["JUNGLETREE_CHOPS_" .. string.upper(stage)])
        end
        if inst:HasTag("spider_monkey_tree") then
            inst.components.lootdropper:SetChanceLootTable("spider_monkey_tree_" .. stage)
        else
            inst.components.lootdropper:SetChanceLootTable("rainforesttree_" .. stage)
        end

        if math.random() < 0.5 and not inst:HasTag("rotten") and not inst:HasTag("spider_monkey_tree") then
            for i = 1, TUNING["SNAKE_JUNGLETREE_AMOUNT_" .. string.upper(stage)] do
                if math.random() < 0.5 and TheWorld.state.cycles >= TUNING.SNAKE_POISON_START_DAY then
                    inst.components.lootdropper:AddChanceLoot("scorpion", TUNING.SNAKE_JUNGLETREE_POISON_CHANCE)
                else
                    inst.components.lootdropper:AddChanceLoot("snake_amphibious", TUNING.SNAKE_JUNGLETREE_CHANCE)
                end
            end
        elseif stage ~= "short" and not inst:HasTag("rotten") and not inst:HasTag("spider_monkey_tree") then
            inst.components.lootdropper:AddChanceLoot("bird_egg", 1.0)
        end

        local scale = scales[stage]
        inst.AnimState:SetScale(scale, scale, scale)

        Sway(inst)
    end
end

local function GetGrowFn(stage, grow_animation, grow_sound)
    return function(inst)
        inst.AnimState:PlayAnimation(grow_animation)
        inst.SoundEmitter:PlaySound(grow_sound)
        if inst:HasTag("spider_monkey_tree") then
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_grow")
        end
        PushSway(inst)
    end
end

local growth_stages = {
    {
        name = "short",
        time = function() return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[1].base, TUNING.JUNGLETREE_GROW_TIME[1].random) end,
        fn = GetStageFn("short"),
        growfn = GetGrowFn("short", "grow_tall_to_short", "dontstarve/forest/treeGrowFromWilt"),
    },
    {
        name = "normal",
        time = function() return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[2].base, TUNING.JUNGLETREE_GROW_TIME[2].random) end,
        fn = GetStageFn("normal"),
        growfn = GetGrowFn("normal", "grow_short_to_normal", "dontstarve/forest/treeGrow"),
    },
    {
        name = "tall",
        time = function() return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[3].base, TUNING.JUNGLETREE_GROW_TIME[3].random) end,
        fn = GetStageFn("tall"),
        growfn = GetGrowFn("tall", "grow_normal_to_tall", "dontstarve/forest/treeGrow"),
    },
}

local function OnWorkCallback(inst, chopper)
    if not (chopper and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
        if inst:HasTag("spider_monkey_tree") then
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")
        end
    end

    local fx = SpawnPrefab("chop_mangrove_pink")
    local x, y, z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + 2 + math.random() * 2, z)

    inst.AnimState:PlayAnimation(anims[inst.stage].chop)
    PushSway(inst)
end

local function OnFinishCallbackStump(inst, digger)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
    -- Wagstaff stuff
    -- if inst:HasTag("mystery") and inst.components.mystery.investigated then
    --     inst.components.lootdropper:SpawnLootPrefab(inst.components.mystery.reward)
    --     inst:RemoveTag("mystery")
    -- end
end

local function MakeStump(inst)
    inst:RemoveTag("shelter")

    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("workable")
    inst:RemoveComponent("blowinwindgust")
    inst:RemoveComponent("hauntable")

    inst:AddTag("stump")
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
    RemovePhysicsColliders(inst)

    inst.components.growable:StopGrowing()

    inst.AnimState:PushAnimation(anims[inst.stage].stump)

    inst.MiniMapEntity:SetIcon("tree_rainforest_stump.tex")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(OnFinishCallbackStump)
    inst.components.workable:SetWorkLeft(1)
end

local function drop_burr(inst,pt)
    if inst.components.bloomable.blooming then
        local num_seeds = inst.components.growable.stage == 3 and 2 or 1

        for i = 1, num_seeds do
            local burr = SpawnPrefab("burr")
            inst.components.lootdropper:DropLootPrefab(burr, pt)
        end
    end
end

-- make snakes attack
local function OnLootSpawned(inst, data)
    if not data or not data.loot or not data.loot:IsValid() then
        return
    end
    if data.loot.components.combat then
        data.loot.components.combat:SuggestTarget(inst._chopper)
    end
end

local function OnFinishCallback(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

    inst._chopper = chopper -- see function OnLootSpawned

    local pt = inst:GetPosition()
    local hispos = chopper:GetPosition()
    local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0

    local anim = anims[inst.stage]
    if he_right then
        inst.AnimState:PlayAnimation(anim.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(anim.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end
    drop_burr(inst, pt)

    MakeStump(inst)

    local fx = SpawnPrefab("fall_mangrove_pink")
    fx.Transform:SetPosition(pt.x, pt.y + 2 + math.random() * 2, pt.z)

    inst:DoTaskInTime(0.4, function()
        local scale = inst.stage > 2 and 0.5 or 0.25
        ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, scale, inst, 6)
    end)
end

local function OnFinishCallbackBurnt(inst, chopper)
    inst:RemoveComponent("workable")

    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end
    inst.AnimState:PlayAnimation(anims[inst.stage].chop_burnt)
    RemovePhysicsColliders(inst)

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    inst.components.lootdropper:SpawnLootPrefab("charcoal")
end

local function OnBurntChanges(inst)
    inst:RemoveTag("shelter")

    inst:RemoveComponent("growable")
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("hauntable")
    inst:RemoveComponent("blowinwindgust")
    MakeHauntableWork(inst)

    inst.components.lootdropper:SetLoot({})

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(OnFinishCallbackBurnt)
    end
end

local function OnBurnt(inst)
    OnBurntChanges(inst)

    inst:AddTag("burnt")

    inst.AnimState:PlayAnimation(anims[inst.stage].burnt, true)
    inst.MiniMapEntity:SetIcon("rainforesttree_burnt.tex")

    inst.AnimState:SetRayTestOnBB(true)

    inst.seed_task = inst:DoTaskInTime(10, function()
        local pt = inst:GetPosition()
        if math.random(0, 1) == 1 then -- ...why?
            pt = pt + TheCamera:GetRightVec()
        else
            pt = pt - TheCamera:GetRightVec()
        end

        inst.seed_task = nil
    end)
end

local function drop_critter(inst, prefab)
    local critter = SpawnPrefab(prefab)
    local pt = Vector3(inst.Transform:GetWorldPosition())

    if math.random(0, 1) == 1 then -- why?
        pt = pt + (TheCamera:GetRightVec() * (math.random() + 1))
    else
        pt = pt - (TheCamera:GetRightVec() * (math.random() + 1))
    end

    critter.sg:GoToState("fall")
    pt.y = pt.y + (2 * inst.stage)

    critter.Transform:SetPosition(pt:Get())
end

local function OnIgnite(inst)
    DefaultIgniteFn(inst)
    if inst:HasTag("stump") then
        return false
    end

    if inst:HasTag("burnt") then
        return
    end

    if inst:HasTag("rotten") then
        return false
    end

    if inst:HasTag("spider_monkey_tree") then
        return false
    end

    if not inst.flushed and math.random() < 0.4 then
        inst.flushed = true

        local prefab = math.random() < 0.5 and TheWorld.state.cycles >= TUNING.SNAKE_POISON_START_DAY and "scorpion" or "snake_amphibious"

        inst:DoTaskInTime(math.random() * 0.5, function() drop_critter(inst, prefab) end)
        if math.random() < 0.3 and prefab == "snake_amphibious" then
            inst:DoTaskInTime(math.random() * 0.5, function() drop_critter(inst, prefab) end)
        end
    end
end

local function GrowFromSeed(inst)
    inst.components.growable:SetStage(1)
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function DoBloom(inst)
    if inst:HasTag("burnt") then
        return
    end

    local burr = SpawnPrefab("burr")
    local pt = inst:GetPosition()

    if math.random(0, 1) == 1 then -- why?
        pt = pt + (TheCamera:GetRightVec() * (math.random() + 1))
    else
        pt = pt - (TheCamera:GetRightVec() * (math.random() + 1))
    end

    burr.AnimState:PlayAnimation("drop")
    burr.AnimState:PushAnimation("idle")

    burr.Transform:SetPosition(pt:Get())
end

local function CanBloom(inst)
    if inst:HasTag("stump") then
        return false
    end

    if inst:HasTag("burnt") then
        return
    end

    if inst:HasTag("rotten") then
        return false
    end

    if inst:HasTag("spider_monkey_tree") then
        return false
    end

    return inst.stage == 3 and inst:HasTag("blooming")
end

local function StartBloom(inst)
    if inst:HasTag("rotten") then
        return
    end
    inst.AnimState:SetBuild("tree_rainforest_bloom_build")
    inst.build = "tree_rainforest_bloom_build"
end

local function StopBloom(inst)
    if inst:HasTag("rotten") then
        return
    end
    inst.AnimState:SetBuild("tree_rainforest_build")
    inst.build = "normal"
end

local function PlayWebFX(inst)
    inst.AnimState:PlayAnimation("change_to_web_" .. STAGES[inst.stage or 1])
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_grow")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderExitLair")
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
    data.stump = inst:HasTag("stump")
    data.stage = inst.stage
    data.flushed = inst.flushed
    if inst.build ~= "normal" then
        data.build = inst.build
    end

    if inst.bloomtaskinfo then
        data.bloomtask = inst:TimeRemainingInTask(inst.bloomtaskinfo)
    end
    if inst.unbloomtaskinfo then
        data.unbloomtask = inst:TimeRemainingInTask(inst.unbloomtaskinfo)
    end

    data.spider = inst:HasTag("has_spider")
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.stage = data.stage or 1

    if data.build then
        inst.AnimState:SetBuild(data.build)
        inst.build = data.build
    end

    local is_burnt = data.burnt or inst:HasTag("burnt")
    if data.stump then
        MakeStump(inst)
        inst.AnimState:PlayAnimation(anims[inst.stage].stump)
        if is_burnt then
            DefaultBurntFn(inst)
        end
    else
        if is_burnt then
            OnBurnt(inst)
        else
            Sway(inst)
        end
    end

    if data.flushed then
        inst.flushed = data.flushed
    end

    if data.bloomtask then
        if inst.bloomtask then inst.bloomtask:Cancel() inst.bloomtask = nil end
        inst.bloomtaskinfo = nil
        inst.bloomtask, inst.bloomtaskinfo = inst:ResumeTask(data.bloomtask, function()
            if not inst:HasTag("rotten") then
                inst.build = "tree_rainforest_bloom_build"
                inst.AnimState:SetBuild(inst.build)
            end
        end)
    end
    if data.unbloomtask then
        if inst.unbloomtask then inst.unbloomtask:Cancel() inst.unbloomtask = nil end
        inst.unbloomtaskinfo = nil
        inst.unbloomtask, inst.unbloomtaskinfo = inst:ResumeTask(data.unbloomtask, function()
            if not inst:HasTag("rotten") then
                inst.build = "tree_rainforest_build"
                inst.AnimState:SetBuild(inst.build)
            end
        end)
    end

    if data.spider then
        inst:AddTag("has_spider")
    end
end

local function MakeTreeBurnable(inst)
    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
    inst.components.burnable.extinguishimmediately = false
    inst.components.burnable:SetFXLevel(5)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable:SetOnIgniteFn(OnIgnite)
end

local function OnEntitySleep(inst)
    local do_burnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning()

    if do_burnt and inst:HasTag("stump") then
        DefaultBurntFn(inst)
    else
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        if do_burnt then
            inst:RemoveComponent("growable")
            inst:AddTag("burnt")
        end
    end
end

local function OnEntityWake(inst)
    if inst:HasTag("burnt") then
        OnBurnt(inst)
    else
        local isstump = inst:HasTag("stump")

        if not (inst.components.burnable and inst.components.burnable:IsBurning()) then
            if inst.components.burnable == nil then
                if isstump then
                    MakeSmallBurnable(inst)
                else
                    MakeTreeBurnable(inst)
                end
            end

            if inst.components.propagator == nil then
                if isstump then
                    MakeSmallPropagator(inst)
                else
                    MakeLargePropagator(inst)
                end
            end
        end
    end
end

local function OnBlownByWind(inst, data)
    if inst.components.bloomable and inst.components.bloomable:CanBloom() then
        if math.random() < 0.30 then
            inst.components.bloomable:DoBloom()
        end
    end
end

local function OnseasonChange(inst, season)
    local bloomable = inst.components.bloomable
    if not bloomable then
        return
    end

    if season == SEASONS.LUSH and not bloomable:IsBlooming() then
        bloomable:StartBloomTask()
    elseif season ~= SEASONS.LUSH and bloomable:IsBlooming() then
        bloomable:StartUnbloomTask()
    end
end

local function MakeTree(name, build, stage, data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        if build == "spider" then
            inst.entity:AddGroundCreepEntity()
            inst.GroundCreepEntity:SetRadius(5)
        end
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 0.25)

        local color = 0.5 + math.random() * 0.5

        if build == "rot" then
            inst.AnimState:SetBuild("tree_rainforest_gas_build")
        elseif build == "spider" then
            inst.AnimState:SetBuild("tree_rainforest_web_build")
        else
            inst.AnimState:SetBuild("tree_rainforest_build")
        end
        inst.AnimState:SetBank("rainforesttree")
        inst.AnimState:SetTime(math.random() * 2)

        inst.AnimState:SetMultColour(color, color, color, 1)

        if build == "spider" then
            inst.MiniMapEntity:SetIcon("spiderTree.tex")
        else
            inst.MiniMapEntity:SetIcon("tree_rainforest.tex")
        end
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("rainforesttree")
        inst:AddTag("workable")
        inst:AddTag("shelter")
        inst:AddTag("gustable")
        if build == "rot" then
            inst:AddTag("rotten")
            inst.build = "tree_rainforest_gas_build"
            inst:SetPrefabName("rainforesttree_rot")
        elseif build == "spider" then
            inst:AddTag("spider_monkey_tree")
            inst.build = "tree_rainforest_web_build"
            inst:SetPrefabName("spider_monkey_tree")
        else
            inst:SetPrefabName("rainforesttree")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.stage = stage == 0 and math.random(1, 3) or stage

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(OnWorkCallback)
        inst.components.workable:SetOnFinishCallback(OnFinishCallback)

        inst:AddComponent("lootdropper")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(inst.stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        inst:AddComponent("bloomable")
        inst.components.bloomable:SetCanBloom(CanBloom)
        inst.components.bloomable:SetStartBloomFn(StartBloom)
        inst.components.bloomable:SetStopBloomFn(StopBloom)
        inst.components.bloomable:SetDoBloom(DoBloom)

        MakeTreeBurnable(inst)

        MakeLargePropagator(inst, TUNING.TREE_BURN_TIME)
        MakeSnowCovered(inst, 0.01)
        MakeHauntableWork(inst)
        MakeTreeBlowInWindGust(inst, {"short", "normal", "tall"}, TUNING.JUNGLETREE_WINDBLOWN_SPEED, TUNING.JUNGLETREE_WINDBLOWN_FALL_CHANCE)

        if data == "burnt" then
            OnBurnt(inst)
        elseif data == "stump" then
            MakeStump(inst)
        end

        inst.PlayWebFX = PlayWebFX
        inst.growfromseed = GrowFromSeed
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        inst:ListenForEvent("blownbywind", OnBlownByWind)
        inst:ListenForEvent("loot_prefab_spawned", OnLootSpawned)
        if build ~= "spider" then
            inst:WatchWorldState("season", OnseasonChange)
            OnseasonChange(inst, TheWorld.state.season)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return  MakeTree("rainforesttree", "normal", 0),
        MakeTree("rainforesttree_normal", "normal", 2),
        MakeTree("rainforesttree_tall", "normal", 3),
        MakeTree("rainforesttree_short", "normal", 1),
        MakeTree("rainforesttree_burnt", "normal", 0, "burnt"),
        MakeTree("rainforesttree_stump", "normal", 0, "stump"),

        MakeTree("rainforesttree_rot", "rot", 0),
        MakeTree("rainforesttree_rot_normal", "rot", 2),
        MakeTree("rainforesttree_rot_tall", "rot", 3),
        MakeTree("rainforesttree_rot_short", "rot", 1),
        MakeTree("rainforesttree_rot_burnt", "rot", 0, "burnt"),
        MakeTree("rainforesttree_rot_stump", "rot", 0, "stump"),

        MakeTree("spider_monkey_tree", "spider", 0),
        MakeTree("spider_monkey_tree_normal", "spider", 2),
        MakeTree("spider_monkey_tree_tall", "spider", 3),
        MakeTree("spider_monkey_tree_short", "spider", 1),
        MakeTree("spider_monkey_tree_burnt", "spider", 0, "burnt"),
        MakeTree("spider_monkey_tree_stump", "spider", 0, "stump")

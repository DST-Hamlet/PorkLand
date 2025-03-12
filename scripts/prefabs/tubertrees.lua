local assets =
{
    Asset("ANIM", "anim/tuber_tree_build.zip"),
    Asset("ANIM", "anim/tuber_bloom_build.zip"),
    Asset("ANIM", "anim/tuber_tree.zip"),
    Asset("ANIM", "anim/dust_fx.zip"),
}

local prefabs =
{
    "charcoal",
    "chop_mangrove_pink",
    "fall_mangrove_pink",
    "tuber_crop",
    "tuber_bloom_crop",
    "tuber_crop_cooked",
    "tuber_bloom_crop_cooked",
}

local HACKS_PER_TUBER = 3

local TUBER_SLOTS_SHORT = {5, 6}
local TUBER_SLOTS_TALL = {8, 5, 7}

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
    MakeAnims("tall"),
}

local function GetStatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

local function UpdateArt(inst)
    for i, slot in ipairs(inst.tuberslots) do
        inst.AnimState:Hide("tubers" .. slot)
    end

    for i = 1, inst.tubers do
        inst.AnimState:Show("tubers" .. inst.tuberslots[i])
    end
end

local function UpdateTubers(inst, tubers, skip_workleft_update)
    inst.tubers = tubers
    UpdateArt(inst)
    if not skip_workleft_update then
        inst.components.workable:SetWorkLeft((inst.tubers + 1) * HACKS_PER_TUBER)
    end
end

local function PushSway(inst)
    local anim = anims[inst.stage]
    if math.random() > 0.5 then
        inst.AnimState:PushAnimation(anim.sway1, true)
    else
        inst.AnimState:PushAnimation(anim.sway2, true)
    end
end

local function Sway(inst)
    local anim = anims[inst.stage]
    if math.random() > 0.5 then
        inst.AnimState:PlayAnimation(anim.sway1, true)
    else
        inst.AnimState:PlayAnimation(anim.sway2, true)
    end
    inst.AnimState:SetTime(math.random() * 2)
end

local function GetStageFn(stage)
    return function(inst)
        if stage == "short" then
            inst.maxtubers = 2
            inst.tuberslots = TUBER_SLOTS_SHORT
            inst.stage = 1
        elseif stage == "tall" then
            inst.maxtubers = 3
            inst.tuberslots = TUBER_SLOTS_TALL
            inst.stage = 2
        end

        Sway(inst)
    end
end

local function GetGrowFn(stage, grow_animation)
    return function(inst)
        inst.AnimState:PlayAnimation(grow_animation)
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/volcano_cactus/grow_pre")

        local tubers = inst.tubers
        if stage == "short" then
            tubers = inst.maxtubers
        elseif stage == "tall" then
            tubers = tubers + 1
        end
        UpdateTubers(inst, math.min(tubers, inst.maxtubers))
        PushSway(inst)
    end
end

local growth_stages = {
    {
        name = "short",
        time = function() return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[1].base, TUNING.CLAWPALMTREE_GROW_TIME[1].random) end,
        fn = GetStageFn("short"),
        growfn = GetGrowFn("short", "grow_tall_to_short"),
    },
    {
        name = "tall",
        time = function(inst) return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[3].base, TUNING.CLAWPALMTREE_GROW_TIME[3].random) end,
        fn = GetStageFn("tall"),
        growfn = GetGrowFn("tall", "grow_short_to_tall"),
    },
}

local function OnFinishCallbackStump(inst, chopper)
    inst.components.lootdropper:SpawnLootPrefab("tuber_crop")
    inst:Remove()
end

local function MakeStump(inst, push_anim)
    local anim = anims[inst.stage]

    inst:RemoveTag("workable")
    inst:RemoveTag("shelter")
    inst:RemoveTag("gustable")

    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("growable")
    inst:RemoveComponent("bloomable")
    inst:RemoveComponent("blowinwindgust")

    RemovePhysicsColliders(inst)

    inst:AddTag("stump")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    if push_anim then
        inst.AnimState:PushAnimation(anim.stump)
    else
        inst.AnimState:PlayAnimation(anim.stump)
    end

    inst.MiniMapEntity:SetIcon("tuber_trees_stump.tex")

    -- inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(OnFinishCallbackStump)
    inst.components.workable:SetWorkLeft(1)
end

local function OnFinishCallbackBurnt(inst, chopper)
    local anim = anims[inst.stage]

    RemovePhysicsColliders(inst)

    inst.AnimState:PlayAnimation(anim.chop_burnt)

    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bamboo_hack")

    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    if math.random() < 0.4 then
        inst.components.lootdropper:SpawnLootPrefab("charcoal")
    end
    inst.components.lootdropper:DropLoot()

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)
end

local function OnBurntChanges(inst)
    inst:RemoveTag("shelter")
    inst:AddTag("burnt")

    inst:RemoveComponent("growable")
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("hauntable")
    inst:RemoveComponent("bloomable")
    inst:RemoveComponent("blowinwindgust")
    MakeHauntableWork(inst)

    inst.components.lootdropper:SetLoot({})

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(OnFinishCallbackBurnt)
    end
end

local burnt_highlight_override = {0.5, 0.5, 0.5}
local function OnBurnt(inst)
    local anim = anims[inst.stage]

    OnBurntChanges(inst)

    inst.AnimState:PlayAnimation(anim.burnt, true)
    inst.MiniMapEntity:SetIcon("tuber_trees_burnt.tex")
    inst.highlight_override = burnt_highlight_override
end

local function OnHacked(inst, worker, workleft, numworks)
    local anim = anims[inst.stage]
    inst.AnimState:PlayAnimation(anim.chop)
    PushSway(inst)

    local tubers_left = math.max(math.ceil(workleft / HACKS_PER_TUBER) - 1, 0)
    local tubers_to_drop = inst.tubers - tubers_left
    if tubers_to_drop > 0 then
        for i = 1, tubers_to_drop do
            inst.components.lootdropper:DropLoot()
        end
        UpdateTubers(inst, tubers_left, true)
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/volcano_cactus/hit")
end

local function OnHackedFinal(inst, worker)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/volcano_cactus/tuber_fall")

    local pt = inst:GetPosition()
    local hispos = worker:GetPosition()
    local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0

    local anim = anims[inst.stage]
    if he_right then
        inst.AnimState:PlayAnimation(anim.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(anim.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    MakeStump(inst, true)

    inst:AddTag("NOCLICK")
    inst:DoTaskInTime(2, function() inst:RemoveTag("NOCLICK") end)
end

local function CanBloom(inst)
    return not inst:HasTag("stump") and not inst:HasTag("burnt")
end

local function StartBloom(inst)
    if not (inst.components.bloomable and inst.components.bloomable:CanBloom()) then
        return
    end

    inst.build = "blooming"
    inst.components.lootdropper:SetLoot({"tuber_bloom_crop"})
    inst.AnimState:SetBuild("tuber_bloom_build")
end

local function StopBloom(inst)
    if not (inst.components.bloomable and inst.components.bloomable:CanBloom()) then
        return
    end

    inst.build = "normal"
    inst.components.lootdropper:SetLoot({"tuber_crop"})
    inst.AnimState:SetBuild("tuber_tree_build")
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
    data.stump = inst:HasTag("stump")
    data.flushed = inst.flushed
    data.stage = inst.stage

    if inst.build ~= "normal" then
        data.build = inst.build
    end
    if inst.tubers then
        data.tubers  = inst.tubers
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.stage then
        inst.stage = data.stage
    end

    if not data.build then
        StopBloom(inst)
    else
        inst.build = data.build
    end

    if data.flushed then
        inst.flushed = data.flushed
    end

    if data.tubers then
        UpdateTubers(inst, math.min(data.tubers, inst.maxtubers)) -- inst.maxtubers is correctly set by growable component.
    end

    if data.burnt then
        inst:AddTag("fire") -- Add the fire tag here: OnEntityWake will handle it actually doing burnt logic
        inst.MiniMapEntity:SetIcon("tuber_trees_burnt.tex")
    elseif data.stump then
        MakeStump(inst)
    end
end

local function OnEntitySleep(inst)
    local fire = inst:HasTag("fire")

    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("inspectable")

    if fire then
        inst:AddTag("fire")
    end
end

local function OnEntityWake(inst)
    if not inst:HasTag("burnt") and not inst:HasTag("fire") then
        if not inst.components.burnable then
            if inst:HasTag("stump") then
                MakeSmallBurnable(inst)
            else
                MakeLargeBurnable(inst)
                inst.components.burnable:SetFXLevel(5)
                inst.components.burnable:SetOnBurntFn(OnBurnt)
            end
        end

        if not inst.components.propagator then
            if inst:HasTag("stump") then
                MakeSmallPropagator(inst)
            else
                MakeLargePropagator(inst)
                inst.components.burnable:SetOnIgniteFn(DefaultIgniteFn)
            end
        end
    elseif not inst:HasTag("burnt") and inst:HasTag("fire") then
        OnBurnt(inst)
    end

    if not inst.components.inspectable then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
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
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 0.25)

        local color = 0.5 + math.random() * 0.5

        inst.AnimState:SetBuild("tuber_tree_build")
        inst.AnimState:SetBank("tubertree")
        inst.AnimState:SetMultColour(color, color, color, 1)
        inst.AnimState:SetTime(math.random() * 2)

        inst.MiniMapEntity:SetIcon("tuber_trees.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("shelter")
        inst:AddTag("gustable")
        inst:AddTag("tubertree")

        inst:SetPrefabName("tubertree")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.build = build
        inst.stage = stage == 0 and math.random(1, 3) or stage

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot({"tuber_crop"})

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HACK)
        -- inst.components.workable:SetWorkLeft((inst.tubers + 1) * HACKS_PER_TUBER) -- We will call this in UpdateTubers later on
        inst.components.workable:SetOnWorkCallback(OnHacked)
        inst.components.workable:SetOnFinishCallback(OnHackedFinal)

        inst:AddComponent("hackable")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(inst.stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        inst:AddComponent("mystery")

        inst:AddComponent("bloomable")
        inst.components.bloomable:SetCanBloom(CanBloom)
        inst.components.bloomable:SetStartBloomFn(StartBloom)
        inst.components.bloomable:SetStopBloomFn(StopBloom)

        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(3)
        inst.components.burnable:SetOnBurntFn(OnBurnt)

        MakeLargePropagator(inst)
        inst.components.burnable:SetOnIgniteFn(DefaultIgniteFn)

        MakeSnowCovered(inst, 0.01)
        MakeHauntableWork(inst)
        MakeTreeBlowInWindGust(inst, {"short", "tall"}, TUNING.JUNGLETREE_WINDBLOWN_SPEED, TUNING.JUNGLETREE_WINDBLOWN_FALL_CHANCE)

        if data == "burnt" then
            OnBurnt(inst)
        end

        if data == "stump" then
            MakeStump(inst)
        end

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake

        UpdateTubers(inst, inst.maxtubers)

        inst:WatchWorldState("season", OnseasonChange)
        OnseasonChange(inst, TheWorld.state.season)

        return inst
    end
    return Prefab(name, fn, assets, prefabs)
end

return  MakeTree("tubertree", "normal", 0),
        MakeTree("tubertree_tall", "normal", 2),
        MakeTree("tubertree_short", "normal", 1),
        MakeTree("tubertree_burnt", "normal", 0, "burnt"),
        MakeTree("tubertree_stump", "normal", 0, "stump")

local assets =
{
    Asset("ANIM", "anim/claw_tree_build.zip"),
    Asset("ANIM", "anim/claw_tree_normal.zip"),
    Asset("ANIM", "anim/claw_tree_short.zip"),
    Asset("ANIM", "anim/claw_tree_tall.zip"),
    Asset("ANIM", "anim/dust_fx.zip"),
}

local prefabs =
{
    "cork",
    "charcoal",
    "chop_mangrove_blue",
    "fall_mangrove_blue",
    "snake_amphibious",
    "bird_egg",
    "scorpion",
}

SetSharedLootTable("clawpalmtree_short",
{
    {"cork", 1.0},
})

SetSharedLootTable("clawpalmtree_normal",
{
    {"cork", 1.0},
    {"cork", 1.0},
})

SetSharedLootTable("clawpalmtree_tall",
{
    {"cork", 1.0},
    {"cork", 1.0},
    {"cork", 1.0},
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

local function GetStageFn(stage)
    return function(inst)
        inst.stage = inst.components.growable.stage
        if inst.components.workable then
            inst.components.workable:SetWorkLeft(TUNING["JUNGLETREE_CHOPS_" .. string.upper(stage)])
        end

        inst.components.lootdropper:SetChanceLootTable("clawpalmtree_" .. stage)

        Sway(inst)
    end
end

local function GetGrowFn(stage, grow_animation, grow_sound)
    return function(inst)
        inst.AnimState:PlayAnimation(grow_animation)
        inst.SoundEmitter:PlaySound(grow_sound)
        PushSway(inst)
    end
end

local growth_stages = {
    {
        name = "short",
        time = function() return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[1].base, TUNING.CLAWPALMTREE_GROW_TIME[1].random) end,
        fn = GetStageFn("short"),
        growfn = GetGrowFn("short", "grow_tall_to_short", "dontstarve_DLC003/common/harvested/clawtree/wilt_to_grow"),
    },
    {
        name = "normal",
        time = function() return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[2].base, TUNING.CLAWPALMTREE_GROW_TIME[2].random) end,
        fn = GetStageFn("normal"),
        growfn = GetGrowFn("normal", "grow_short_to_normal", "dontstarve_DLC003/common/harvested/clawtree/grow"),
    },
    {
        name = "tall",
        time = function() return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[3].base, TUNING.CLAWPALMTREE_GROW_TIME[3].random) end,
        fn = GetStageFn("tall"),
        growfn = GetGrowFn("tall", "grow_normal_to_tall", "dontstarve_DLC003/common/harvested/clawtree/grow"),
    },
}

local function OnFinishCallbackStump(inst, digger)
    inst.components.lootdropper:SpawnLootPrefab("cork")
    inst:Remove()
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

    inst.MiniMapEntity:SetIcon("claw_tree_stump.tex")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(OnFinishCallbackStump)
    inst.components.workable:SetWorkLeft(1)
end

local function OnFinishCallbackBurnt(inst, chopper)
    local anim = anims[inst.stage]
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/clawtree/chop")
    inst.AnimState:PlayAnimation(anim.chop_burnt)
    RemovePhysicsColliders(inst)
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    if math.random() < 0.4 then
        inst.components.lootdropper:SpawnLootPrefab("charcoal")
    end
end

local function OnWorkCallback(inst, chopper, chops)
    if not (chopper and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/clawtree/chop")
        if not chopper or not chopper:HasTag("beaver") then
            inst.SoundEmitter:PlaySound("dontstarve/wilson/chop_tree_break", nil, 0.3)
        end
    end

    local fx = SpawnPrefab("chop_mangrove_blue")
    local x, y, z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + 2 + math.random() * 2, z)

    inst.AnimState:PlayAnimation(anims[inst.stage].chop)
    inst.AnimState:PushAnimation(anims[inst.stage].sway1, true)
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

    MakeStump(inst)

    local fx = SpawnPrefab("fall_mangrove_blue")
    fx.Transform:SetPosition(pt.x, pt.y + 2 + math.random() * 2, pt.z)

    inst:DoTaskInTime(0.4, function()
        local scale = inst.stage > 2 and 0.5 or 0.25
        ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, scale, inst, 6)
    end)
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

local burnt_highlight_override = {0.5, 0.5, 0.5}
local function OnBurnt(inst)
    OnBurntChanges(inst)

    inst.AnimState:PlayAnimation(anims[inst.stage].burnt, true)
    inst.MiniMapEntity:SetIcon("claw_tree_burnt.tex")
    inst:AddTag("burnt")
    inst.highlight_override = burnt_highlight_override
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

    if not inst.flushed and math.random() < 0.4 then
        inst.flushed = true

        local prefab = math.random() < 0.5 and "scorpion" or "snake_amphibious"

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

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
    data.stump = inst:HasTag("stump")
    data.stage = inst.stage
    data.flushed = inst.flushed
end

local function onload(inst, data)
    if not data then
        return
    end

    inst.stage = data.stage or 1

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
end

local function MakeTreeBurnable(inst)
    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
    inst.components.burnable.extinguishimmediately = false
    inst.components.burnable:SetFXLevel(5)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
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

local function MakeTree(name, stage, data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 0.25)

        local color = 0.5 + math.random() * 0.5
        inst.AnimState:SetBuild("claw_tree_build")
        inst.AnimState:SetBank("clawtree")
        inst.AnimState:SetMultColour(color, color, color, 1)
        inst.AnimState:SetTime(math.random() * 2)

        inst.MiniMapEntity:SetIcon("claw_tree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("workable")
        inst:AddTag("shelter")
        inst:AddTag("gustable")
        inst:AddTag("plainstree")

        inst:SetPrefabName("clawpalmtree")

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

        -- inst:AddComponent("mystery")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(inst.stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(3)
        inst.components.burnable:SetOnBurntFn(OnBurnt)

        MakeSmallPropagator(inst)
        inst.components.burnable:SetOnIgniteFn(OnIgnite)

        MakeSnowCovered(inst, .01)
        MakeHauntableWork(inst)
        MakeTreeBlowInWindGust(inst, {"short", "normal", "tall"}, TUNING.JUNGLETREE_WINDBLOWN_SPEED, TUNING.JUNGLETREE_WINDBLOWN_FALL_CHANCE)

        inst.growfromseed = GrowFromSeed
        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake

        if data == "burnt" then
            OnBurnt(inst)
        elseif data == "stump" then
            MakeStump(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return  MakeTree("clawpalmtree", 0),
        MakeTree("clawpalmtree_normal", 2),
        MakeTree("clawpalmtree_tall", 3),
        MakeTree("clawpalmtree_short", 1),
        MakeTree("clawpalmtree_burnt", 0, "burnt"),
        MakeTree("clawpalmtree_stump", 0, "stump")

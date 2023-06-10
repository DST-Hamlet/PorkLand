local assets =
{
    -- Asset("ANIM", "anim/tree_forest_deep_build.zip"),
    Asset("ANIM", "anim/tree_rainforest_normal.zip"),
    Asset("ANIM", "anim/tree_rainforest_short.zip"),
    Asset("ANIM", "anim/tree_rainforest_tall.zip"),
    Asset("ANIM", "anim/tree_rainforest_web_build.zip"),
    Asset("ANIM", "anim/dust_fx.zip"),
    Asset("SOUND", "sound/forest.fsb"),
    Asset("MINIMAP_IMAGE", "spiderTree"),
    Asset("MINIMAP_IMAGE", "tree_rainforest_stump"),
    Asset("MINIMAP_IMAGE", "tree_rainforest_burnt"),
}

local prefabs =
{
    "log",
    "charcoal",
    "silk",
}

local builds =
{
    normal = {
        file="tree_rainforest_web_build",
        prefab_name="spider_monkey_tree",
        normal_loot = {"log", "log", "silk", "silk"},
        short_loot = {"log", "silk"},
        tall_loot = {"log", "log", "log", "silk", "silk"},
    }
}

local function makeanims(stage)
    return {
        idle="idle_"..stage,
        sway1="sway1_loop_"..stage,
        sway2="sway2_loop_"..stage,
        chop="chop_"..stage,
        fallleft="fallleft_"..stage,
        fallright="fallright_"..stage,
        stump="stump_"..stage,
        burning="burning_loop_"..stage,
        burnt="burnt_"..stage,
        chop_burnt="chop_burnt_"..stage,
        idle_chop_burnt="idle_chop_burnt_"..stage,
        blown1="blown_loop_"..stage.."1",
        blown2="blown_loop_"..stage.."2",
        blown_pre="blown_pre_"..stage,
        blown_pst="blown_pst_"..stage
    }
end

local short_anims = makeanims("short")
local tall_anims = makeanims("tall")
local normal_anims = makeanims("normal")
local old_anims =
{
    idle="idle_old",
    sway1="idle_old",
    sway2="idle_old",
    chop="chop_old",
    fallleft="chop_old",
    fallright="chop_old",
    stump="stump_old",
    burning="idle_olds",
    burnt="burnt_tall",
    chop_burnt="chop_burnt_tall",
    idle_chop_burnt="idle_chop_burnt_tall",
    blown="blown_loop",
    blown_pre="blown_pre",
    blown_pst="blown_pst"
}

local function dig_up_stump(inst, chopper)
    inst:Remove()
    inst.components.lootdropper:SpawnLootPrefab("log")

    if inst:HasTag("mystery") and inst.components.mystery.investigated then
        inst.components.lootdropper:SpawnLootPrefab(inst.components.mystery.reward)
        inst:RemoveTag("mystery")
    end
end

local function chop_down_burnt_tree(inst, chopper)
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
    RemovePhysicsColliders(inst)
    inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst:ListenForEvent("entitysleep", inst.Remove)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()
    if inst.pineconetask then
        inst.pineconetask:Cancel()
        inst.pineconetask = nil
    end
end

local function GetBuild(inst)
    local build = builds[inst.build]
    if build == nil then
        return builds["normal"]
    end
    return build
end

local burnt_highlight_override = {.5, .5, .5}
local function OnBurnt(inst, imm)

    local function changes()
        if inst.components.burnable then
            inst.components.burnable:Extinguish()
        end
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("growable")
        inst:RemoveComponent("blowinwindgust")
        inst:RemoveTag("shelter")
        inst:RemoveTag("dragonflybait_lowprio")
        inst:RemoveTag("fire")
        inst:RemoveTag("gustable")

        inst.components.lootdropper:SetLoot({})

        if inst.components.workable then
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnWorkCallback(nil)
            inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
        end
    end

    if imm then
        changes()
    else
        inst:DoTaskInTime(0.5, changes)
    end
    inst.AnimState:PlayAnimation(inst.anims.burnt, true)
    inst.MiniMapEntity:SetIcon("tree_rainforest_burnt.tex")
    inst:AddTag("burnt")

    inst.highlight_override = burnt_highlight_override
end

local function PushSway(inst)
    if math.random() > .5 then
        inst.AnimState:PushAnimation(inst.anims.sway1, true)
    else
        inst.AnimState:PushAnimation(inst.anims.sway2, true)
    end
end

local function Sway(inst)
    if math.random() > .5 then
        inst.AnimState:PlayAnimation(inst.anims.sway1, true)
    else
        inst.AnimState:PlayAnimation(inst.anims.sway2, true)
    end
    inst.AnimState:SetTime(math.random()*2)
end

local function SetShort(inst)
    inst.anims = short_anims

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_SMALL)
    end

    inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)
    inst.Transform:SetScale(0.9,0.9,0.9)
    Sway(inst)
end

local function GrowShort(inst)
    inst.AnimState:PlayAnimation("grow_tall_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    PushSway(inst)
end

local function SetNormal(inst)
    inst.anims = normal_anims

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_NORMAL)
    end

    inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)
    inst.Transform:SetScale(0.8,0.8,0.8)
    Sway(inst)
end

local function GrowNormal(inst)
    inst.AnimState:PlayAnimation("grow_short_to_normal")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function SetTall(inst)
    inst.anims = tall_anims
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_TALL)
    end

    inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)
    inst.Transform:SetScale(0.7,0.7,0.7)
    Sway(inst)
end

local function GrowTall(inst)
    inst.AnimState:PlayAnimation("grow_normal_to_tall")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function inspect_tree(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

local growth_stages =
{
    {name = "short",  time = function(inst) return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[1].base, TUNING.JUNGLETREE_GROW_TIME[1].random) end, fn = function(inst) SetShort(inst) end,  growfn = function(inst) GrowShort(inst) end , leifscale = .7   },
    {name = "normal", time = function(inst) return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[2].base, TUNING.JUNGLETREE_GROW_TIME[2].random) end, fn = function(inst) SetNormal(inst) end, growfn = function(inst) GrowNormal(inst) end, leifscale = 1    },
    {name = "tall",   time = function(inst) return GetRandomWithVariance(TUNING.JUNGLETREE_GROW_TIME[3].base, TUNING.JUNGLETREE_GROW_TIME[3].random) end, fn = function(inst) SetTall(inst) end,   growfn = function(inst) GrowTall(inst) end,   leifscale = 1.25 },
}


local function chop_tree(inst, chopper, chops)

    if chopper and chopper.components.beaverness and chopper.components.beaverness:IsBeaver() then
        inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/beaver_chop_tree")
    else
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end

    inst.AnimState:PlayAnimation(inst.anims.chop)
    inst.AnimState:PushAnimation(inst.anims.sway1, true)

    -- tell any nearby leifs to wake up
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, TUNING.PALMTREEGUARD_REAWAKEN_RADIUS, {"treeguard"})
    for k, v in pairs(ents) do
        if v.components.sleeper and v.components.sleeper:IsAsleep() then
            v:DoTaskInTime(math.random(), function() v.components.sleeper:WakeUp() end)
        end
        v.components.combat:SuggestTarget(chopper)
    end
end

local function chop_down_tree(inst, chopper)
    inst:RemoveComponent("burnable")
    MakeSmallBurnable(inst)
    inst:RemoveComponent("propagator")
    MakeSmallPropagator(inst)
    inst:RemoveComponent("workable")
    inst:RemoveTag("shelter")
    inst:RemoveComponent("blowinwindgust")
    inst:RemoveTag("gustable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local he_right = true

    if chopper then
        local hispos = chopper:GetPosition()
        he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
    else
        if math.random() > 0.5 then
            he_right = false
        end
    end

    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    inst:DoTaskInTime(.4, function()
        local sz = (inst.components.growable and inst.components.growable.stage > 2) and .5 or .25
        ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, sz, inst, 6)
    end)

    RemovePhysicsColliders(inst)
    inst.AnimState:PushAnimation(inst.anims.stump)
    inst.MiniMapEntity:SetIcon("tree_rainforest_stump.tex")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    inst:AddTag("stump")
    if inst.components.growable then
        inst.components.growable:StopGrowing()
    end

    inst:AddTag("NOCLICK")
    inst:DoTaskInTime(2, function() inst:RemoveTag("NOCLICK") end)
end

local function chop_down_tree_leif(inst, chopper)
    chop_down_tree(inst, chopper)
end

local function tree_burnt(inst)
    OnBurnt(inst)
    inst.pineconetask = inst:DoTaskInTime(10,
        function()
            local pt = Vector3(inst.Transform:GetWorldPosition())
            if math.random(0, 1) == 1 then
                pt = pt + TheCamera:GetRightVec()
            else
                pt = pt - TheCamera:GetRightVec()
            end
            inst.components.lootdropper:DropLoot(pt)
            inst.pineconetask = nil
        end)
end


local function dropCritter(inst, prefab)

    local snake = SpawnPrefab(prefab)
    local pt = Vector3(inst.Transform:GetWorldPosition())

    if math.random(0, 1) == 1 then
        pt = pt + (TheCamera:GetRightVec()*((math.random()*1)+1))
    else
        pt = pt - (TheCamera:GetRightVec()*((math.random()*1)+1))
    end

    snake.sg:GoToState("fall")
    pt.y = pt.y + (2*inst.components.growable.stage)

    snake.Transform:SetPosition(pt:Get())
end

local function tree_lit(inst)
    DefaultIgniteFn(inst)
    if not inst.flushed and math.random() < 0.4 then
        inst.flushed = true

        local prefab = "snake_amphibious"

        if math.random() < 0.5 then
            prefab = "scorpion"
        end

        inst:DoTaskInTime(math.random()*0.5, function() dropCritter(inst, prefab) end)
        if math.random() < 0.3 then
            inst:DoTaskInTime(math.random()*0.5, function() dropCritter(inst, prefab) end)
        end
    end
end


local function handler_growfromseed (inst)
    inst.components.growable:SetStage(1)
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end

    if inst.flushed then
        data.flushed = inst.flushed
    end

    if inst:HasTag("stump") then
        data.stump = true
    end

    if inst.build ~= "normal" then
        data.build = inst.build
    end
end

local function onload(inst, data)
    if data then
        if not data.build or builds[data.build] == nil then
            inst.build = "normal"
        else
            inst.build = data.build
        end

        if data.flushed then
            inst.flushed = data.flushed
        end

        if data.burnt then
            inst:AddTag("fire") -- Add the fire tag here: OnEntityWake will handle it actually doing burnt logic
            inst.MiniMapEntity:SetIcon("tree_rainforest_burnt.tex")
        elseif data.stump then
            inst:RemoveComponent("burnable")
            MakeSmallBurnable(inst)
            inst:RemoveComponent("workable")
            inst:RemoveComponent("propagator")
            MakeSmallPropagator(inst)
            inst:RemoveComponent("growable")
            RemovePhysicsColliders(inst)
            inst.AnimState:PlayAnimation(inst.anims.stump)
            inst.MiniMapEntity:SetIcon("tree_rainforest_stump.tex")
            inst:AddTag("stump")
            inst:RemoveTag("shelter")
            inst:RemoveTag("gustable")
            inst:RemoveComponent("blowinwindgust")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(dig_up_stump)
            inst.components.workable:SetWorkLeft(1)
        end
    end
end

local function OnEntitySleep(inst)
    local fire = false
    if inst:HasTag("fire") then
        fire = true
    end
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
                inst.components.burnable:SetOnBurntFn(tree_burnt)
            end
        end

        if not inst.components.propagator then
            if inst:HasTag("stump") then
                MakeSmallPropagator(inst)
            else
                MakeLargePropagator(inst)
                inst.components.burnable:SetOnIgniteFn(tree_lit)
            end
        end
    elseif not inst:HasTag("burnt") and inst:HasTag("fire") then
        OnBurnt(inst, true)
    end

    if not inst.components.inspectable then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end
end

local function OnGustAnimDone(inst)
    if inst:HasTag("stump") or inst:HasTag("burnt") then
        inst:RemoveEventCallback("animover", OnGustAnimDone)
        return
    end
    if inst.components.blowinwindgust and inst.components.blowinwindgust:IsGusting() then
        local anim = math.random(1, 2)
        inst.AnimState:PlayAnimation(inst.anims["blown"..tostring(anim)], false)
    else
        inst:DoTaskInTime(math.random()/2, function(inst)
            if not inst:HasTag("stump") and not inst:HasTag("burnt") then
                inst.AnimState:PlayAnimation(inst.anims.blown_pst, false)
                PushSway(inst)
            end
            inst:RemoveEventCallback("animover", OnGustAnimDone)
        end)
    end
end

local function OnGustStart(inst, windspeed)
    if inst:HasTag("stump") or inst:HasTag("burnt") then
        return
    end
    inst:DoTaskInTime(math.random()/2, function(inst)
        if inst:HasTag("stump") or inst:HasTag("burnt") then
			return
		end
        if inst.spotemitter == nil then
            AddToNearSpotEmitter(inst, "treeherd", "tree_creak_emitter", TUNING.TREE_CREAK_RANGE)
        end
        inst.AnimState:PlayAnimation(inst.anims.blown_pre, false)
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wind_tree_creak")
        inst:ListenForEvent("animover", OnGustAnimDone)
    end)
end

local function OnGustEnd(inst, windspeed)
end

local function OnGustFall(inst)
    if inst:HasTag("burnt") then
        chop_down_burnt_tree(inst, GetPlayer())
    else
        chop_down_tree(inst, GetPlayer())
    end
end

local function makefn(build, stage, data)

    local function fn(Sim)
        local l_stage = stage
        if l_stage == 0 then
            l_stage = math.random(1, 3)
        end

        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        local sound = inst.entity:AddSoundEmitter()

        inst.creep = inst.entity:AddGroundCreepEntity()
        inst.creep:SetRadius( 5 )

        MakeObstaclePhysics(inst, .25)

        local minimap = inst.entity:AddMiniMapEntity()
        minimap:SetIcon("spiderTree.tex")

        minimap:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("workable")
        inst:AddTag("shelter")
        inst:AddTag("gustable")
        inst:AddTag("spider_monkey_tree")

        inst.build = build
        anim:SetBuild(GetBuild(inst).file)
        anim:SetBank("rainforesttree")
        local color = 0.5 + math.random() * 0.5
        anim:SetMultColour(color, color, color, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -------------------
        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(3)
        inst.components.burnable:SetOnBurntFn(tree_burnt)
        --inst.components.burnable:MakeDragonflyBait(1)

        MakeSmallPropagator(inst)
        inst.components.burnable:SetOnIgniteFn(tree_lit)

        -------------------
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree


        -------------------
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree_leif)

        -------------------
        inst:AddComponent("lootdropper")
        ---------------------
        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(l_stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        inst.growfromseed = handler_growfromseed

        --inst:AddComponent("blowinwindgust")
        --inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING.JUNGLETREE_WINDBLOWN_SPEED)
        --inst.components.blowinwindgust:SetDestroyChance(TUNING.JUNGLETREE_WINDBLOWN_FALL_CHANCE)
        --inst.components.blowinwindgust:SetGustStartFn(OnGustStart)
        ---- inst.components.blowinwindgust:SetGustEndFn(OnGustEnd)
        --inst.components.blowinwindgust:SetDestroyFn(OnGustFall)
        --inst.components.blowinwindgust:Start()

        ---------------------
        -- PushSway(inst)
        inst.AnimState:SetTime(math.random()*2)

        ---------------------

        inst.OnSave = onsave
        inst.OnLoad = onload

        MakeSnowCovered(inst, .01)
        ---------------------

        inst:SetPrefabName(GetBuild(inst).prefab_name)

        if data =="burnt"  then
            OnBurnt(inst)
        end

        if data =="stump"  then
            inst:RemoveComponent("burnable")
            MakeSmallBurnable(inst)
            inst:RemoveComponent("workable")
            inst:RemoveComponent("propagator")
            MakeSmallPropagator(inst)
            inst:RemoveComponent("growable")
            inst:RemoveComponent("blowinwindgust")
            inst:RemoveTag("gustable")
            RemovePhysicsColliders(inst)
            inst.AnimState:PlayAnimation(inst.anims.stump)
            inst.MiniMapEntity:SetIcon("tree_rainforest_stump.tex")
            inst:AddTag("stump")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(dig_up_stump)
            inst.components.workable:SetWorkLeft(1)
        end


        inst:ListenForEvent("seasonChange", function(it, data)
            if not inst:HasTag("stump") then
                if data.season == SEASONS.LUSH then
                    -- start pollinating and droping burrs
                else
                    -- stop pollinating
                end
            end
        end, TheWorld)


        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake


        return inst
    end
    return fn
end

local function tree(name, build, stage, data)
    return Prefab("jungle/objects/trees/"..name, makefn(build, stage, data), assets, prefabs)
end

return tree("spider_monkey_tree", "normal", 0),
        tree("spider_monkey_tree_normal", "normal", 2),
        tree("spider_monkey_tree_tall", "normal", 3),
        tree("spider_monkey_tree_short", "normal", 1),
        tree("spider_monkey_tree_burnt", "normal", 0, "burnt"),
        tree("spider_monkey_tree_stump", "normal", 0, "stump")

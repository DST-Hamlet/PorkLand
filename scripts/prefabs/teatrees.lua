local assets =
{
    Asset("ANIM", "anim/tree_leaf_short.zip"),
    Asset("ANIM", "anim/tree_leaf_normal.zip"),
    Asset("ANIM", "anim/tree_leaf_tall.zip"),

    Asset("ANIM", "anim/teatree_trunk_build.zip"),  -- trunk build (winter leaves build)
    Asset("ANIM", "anim/teatree_build.zip"),

    Asset("ANIM", "anim/dust_fx.zip"),
}

local prefabs =
{
    "log",
    "twigs",
    "teatree_nut",
    "charcoal",
    "green_leaves",
    "green_leaves_chop",
}

SetSharedLootTable("teatree_short",
{
    {"log", 1.0},
})

SetSharedLootTable("teatree_normal",
{
    {"log", 1.0},
    {"twigs", 1.0},
    {"teatree_nut", 1.0},
})

SetSharedLootTable("teatree_tall",
{
    {"log", 1.0},
    {"log", 1.0},
    {"teatree_nut", 1.0},
    {"teatree_nut", 1.0},
})

SetSharedLootTable("teatree_burnt",
{
    {"charcoal", 1.0},
    {"teatree_nut", 0.1}
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
        blown1 = "blown_loop_" ..stage.. "1",
        blown2 = "blown_loop_" ..stage.. "2",
        blown_pre = "blown_pre_" .. stage,
        blown_pst = "blown_pst_" .. stage,
    }
end

local anims = {
    MakeAnims("short"),
    MakeAnims("normal"),
    MakeAnims("tall"),
}

local function PushSway(inst)
    inst.AnimState:PushAnimation(math.random() < 0.5 and anims[inst.stage].sway1 or anims[inst.stage].sway2, true)
end

local function GetStageFn(stage)
    return function(inst)
        inst.stage = inst.components.growable.stage
        if inst.components.workable then
            inst.components.workable:SetWorkLeft(TUNING["TEATREE_CHOPS_" .. string.upper(stage)])
        end
        inst.components.lootdropper:SetChanceLootTable("teatree_" .. stage)
    end
end

local function GetGrowFn(stage, grow_animation)
    return function(inst)
        inst.AnimState:PlayAnimation(grow_animation)
        PushSway(inst)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    end
end

local growth_stages = {
    {
        name = "short",
        time = function() return GetRandomWithVariance(TUNING.TEATREE_GROW_TIME[1].base, TUNING.TEATREE_GROW_TIME[1].random) end,
        fn = GetStageFn("short"),
        growfn = GetGrowFn("short", "grow_tall_to_short"),
    },
    {
        name = "normal",
        loot = {"log", "twigs", "teatree_nut"},
        time = function() return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[2].base, TUNING.DECIDUOUS_GROW_TIME[2].random) end,
        fn = GetStageFn("normal"),
        growfn = GetGrowFn("normal", "grow_short_to_normal"),
    },
    {
        name = "tall",
        time = function() return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[3].base, TUNING.DECIDUOUS_GROW_TIME[3].random) end,
        fn = GetStageFn("tall"),
        growfn = GetGrowFn("tall", "grow_normal_to_tall"),
    },
}

local function GetNewChildPrefab()
    return math.random() < 0.2 and "piko_orange" or "piko"
end

local function SpawnOffsetOverride(inst)
    local function NoHoles(pt)
        return not TheWorld.Map:IsPointNearHole(pt)
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    local rad = 0.0 + inst:GetPhysicsRadius(0) + inst.components.spawner.child:GetPhysicsRadius(0)
    local start_angle = math.random() * 2 *PI

    local offset = FindWalkableOffset(Vector3(x, 0, z), start_angle, rad, 8, false, true, NoHoles, false, false)
    if offset == nil then
        -- well it's gotta go somewhere!
        x = x + rad * math.cos(start_angle)
        z = z - rad * math.sin(start_angle)
    else
        x = x + offset.x
        z = z + offset.z
    end

    return x, y, z
end

local function OnVacated(inst, child)
    child.sg:GoToState("descendtree")
    child:UpdateLight()
end

local SPAWNER_STARTDELAY_TIMERNAME = "Spawner_SpawnDelay"
local function OnPhaseChange(inst)
    local is_rabid_phase = TheWorld.state.phase == "night" and (TheWorld.state.moonphase == "full" or TheWorld.state.moonphase == "blood")
    if TheWorld.state.phase == "day" or is_rabid_phase then
        if inst.components.worldsettingstimer:ActiveTimerExists(SPAWNER_STARTDELAY_TIMERNAME) then -- if we have a paused timer, resume it
            inst.components.worldsettingstimer:ResumeTimer(SPAWNER_STARTDELAY_TIMERNAME)
        else
            inst.components.worldsettingstimer:StopTimer(SPAWNER_STARTDELAY_TIMERNAME)
            inst.components.worldsettingstimer:StartTimer(SPAWNER_STARTDELAY_TIMERNAME, 2 + math.random(20)) -- otherwise spawn piko
        end
    else
        inst.components.worldsettingstimer:PauseTimer(SPAWNER_STARTDELAY_TIMERNAME)
    end
end

local function OnOccupied(inst, child)
    if child.components.inventory then
        local items = child.components.inventory:ReferenceAllItems()
        for i, item in ipairs(items) do
            inst.components.inventory:GiveItem(item)
        end
    end
    OnPhaseChange(inst)
end

local function MakePikoNest(inst, piko)
    if piko then
        inst.components.worldsettingstimer:PauseTimer(SPAWNER_STARTDELAY_TIMERNAME)
        inst.components.spawner:TakeOwnership(piko)
    end

    if not inst.is_piko_nest then
        inst.is_piko_nest = true
        inst:WatchWorldState("phase", OnPhaseChange)
        inst:WatchWorldState("moonphase", OnPhaseChange)
        OnPhaseChange(inst)
    end
end

local function DeleteChild(inst)
    local spawner = inst.components.spawner
    if spawner then
        if inst.components.spawner:IsOccupied() then
            inst.components.spawner:ReleaseChild()
        end

        local child = spawner.child
        if child then
            spawner.child = nil

            if child.components.knownlocations then
                child.components.knownlocations:ForgetLocation("home")
            end
            child:RemoveComponent("homeseeker")

            inst:RemoveEventCallback("ontrapped", spawner._onchildkilled, child)
            inst:RemoveEventCallback("death", spawner._onchildkilled, child)
            inst:RemoveEventCallback("detachchild", spawner._onchildkilled, child)
            inst:RemoveEventCallback("onremove", spawner._onchildkilled, spawner.child)
        end
    end
end

local function DestroyPikoNest(inst)
    if inst.is_piko_nest then
        inst.is_piko_nest = false

        inst:StopWatchingWorldState("phase", OnPhaseChange)
        inst:StopWatchingWorldState("moonphase", OnPhaseChange)

        DeleteChild(inst)
        inst.components.worldsettingstimer:StopTimer(SPAWNER_STARTDELAY_TIMERNAME)
    end
end

local function GetStatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

local function GrowFromSeed(inst)
    inst.components.growable:SetStage(1)

    -- inst.AnimState:OverrideSymbol("swap_leaves", "teatree_build", "swap_leaves")
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    PushSway(inst)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local function OnWorkCallback(inst, chopper)
    if not (chopper and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/in_tree")
    end

    local fx = SpawnPrefab("green_leaves_chop")
    local x, y, z = inst.Transform:GetWorldPosition()
    y = y + (inst.stage == 2 and 0.3 or 0)  -- FX height is slightly higher for normal stage
    y = y + (math.random() * 2)  -- Randomize height a bit for chop FX
    fx.Transform:SetPosition(x, y, z)

    inst.AnimState:PlayAnimation(anims[inst.stage].chop)
    PushSway(inst)
end

local function OnFinishCallbackStump(inst, digger)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function MakeStump(inst)
    inst:RemoveTag("shelter")
    inst:RemoveTag("cattoyairborne")

    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("workable")
    -- inst:RemoveComponent("blowinwindgust")
    inst:RemoveComponent("hauntable")

    inst:AddTag("stump")
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
    RemovePhysicsColliders(inst)

    inst.components.growable:StopGrowing()

    inst.AnimState:PushAnimation(anims[inst.stage].stump)

    inst.MiniMapEntity:SetIcon("teatree_stump.tex")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(OnFinishCallbackStump)
    inst.components.workable:SetWorkLeft(1)
end

local function OnFinishCallback(inst, chopper)
    DestroyPikoNest(inst)

    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

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

    inst.components.inventory:DropEverything(false, false)

    MakeStump(inst)

    inst:DoTaskInTime(0.4, function()
        local scale = (inst.stage > 2) and 0.5 or 0.25
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

    inst.components.inventory:DropEverything(false, false)
    inst.components.lootdropper:DropLoot()
end

local function OnBurntChanges(inst)
    inst:RemoveTag("shelter")
    inst:RemoveTag("cattoyairborne")

    inst:RemoveComponent("growable")
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("hauntable")
    MakeHauntableWork(inst)
    -- inst:RemoveComponent("blowinwindgust")

    inst.components.lootdropper:SetChanceLootTable("palmconetree_burnt")

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(OnFinishCallbackBurnt)
    end
end

local function OnBurnt(inst, immediate)
    -- NOTE(ziwbi): Burnable.onburnt only accepts 1 argument actually
    -- if immediate then
        OnBurntChanges(inst)
    -- else
    --     inst:DoTaskInTime(0.5, OnBurntChanges)
    -- end

    inst:AddTag("burnt")

    DestroyPikoNest(inst)

    inst.AnimState:PlayAnimation(anims[inst.stage].burnt, true)
    inst.MiniMapEntity:SetIcon("teatree_burnt.tex")

    inst.AnimState:SetRayTestOnBB(true)
end

local function OnIgnite(inst)
    -- if inst.components.inventory then
    --     local items = inst.components.inventory:FindItems(function(item) return item.components.burnable end)
    --     for _, item in ipairs(items) do
    --         item.components.burnable:Ignite(true)
    --     end
    -- end
    DeleteChild(inst)
    inst.components.worldsettingstimer:PauseTimer(SPAWNER_STARTDELAY_TIMERNAME)
end

local function OnExtinguish(inst)
    local is_rabid_phase = TheWorld.state.phase == "night" and (TheWorld.state.moonphase == "full" or TheWorld.state.moonphase == "blood")
    if TheWorld.state.phase == "day" or is_rabid_phase then
        if inst.components.worldsettingstimer:ActiveTimerExists(SPAWNER_STARTDELAY_TIMERNAME) then -- if we have a paused timer, resume it
            inst.components.worldsettingstimer:ResumeTimer(SPAWNER_STARTDELAY_TIMERNAME)
        end
    else
        inst.components.worldsettingstimer:PauseTimer(SPAWNER_STARTDELAY_TIMERNAME)
    end
end

local function MakeTreeBurnable(inst)
    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
    inst.components.burnable.extinguishimmediately = false
    inst.components.burnable:SetFXLevel(5)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable:SetOnIgniteFn(OnIgnite)
    inst.components.burnable:SetOnExtinguishFn(OnExtinguish)
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

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
    data.stump = inst:HasTag("stump")
    data.stage = inst.stage
    data.is_piko_nest = inst.is_piko_nest
end

local function OnPreLoad(inst, data)
    WorldSettings_Spawner_PreLoad(inst, data, TUNING.PIKO_RESPAWN_TIME)
end

local function OnLoad(inst, data)
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
        if data.is_piko_nest then
            inst:MakePikoNest()
        end

        if is_burnt then
            OnBurnt(inst, true)
        else
            PushSway(inst)
        end
    end
end

local function MakeTeaTree(name, stage, state)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 0.25)

        inst.MiniMapEntity:SetIcon("teatree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("teatree")
        inst:AddTag("shelter")
        inst:AddTag("workable")
        inst:AddTag("cattoyairborne")

        inst.stage = stage == 0 and math.random(1, 3) or stage
        local color = 0.7 + math.random() * 0.3

        inst.AnimState:SetBank("tree_leaf")
        inst.AnimState:SetBuild("teatree_trunk_build")
        inst.AnimState:AddOverrideBuild("teatree_build")
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:SetPrefabName("teatree")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -- The inventory is separate from the loot in the regard that it stores items that entities deposit in the tree.
        -- An example of this is the squirrel (ie. piko), which steals items off the ground and takes them back to the tree.
        inst:AddComponent("inventory")

        inst:AddComponent("lootdropper")

        --inst:AddComponent("mystery")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(OnWorkCallback)
        inst.components.workable:SetOnFinishCallback(OnFinishCallback)

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(inst.stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        inst.growfromseed = GrowFromSeed

        inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

        inst:AddComponent("spawner")
        WorldSettings_Spawner_SpawnDelay(inst, TUNING.PIKO_RESPAWN_TIME, TUNING.PIKO_ENABLED)
        inst.components.spawner.delay = TUNING.PIKO_RESPAWN_TIME  -- This "delay" is actually respawn time
        inst.components.spawner.childfn = GetNewChildPrefab
        inst.components.spawner:SetOnVacateFn(OnVacated)
        inst.components.spawner:SetOnOccupiedFn(OnOccupied)
        inst.components.spawner.overridespawnlocation = SpawnOffsetOverride

        inst.MakePikoNest = MakePikoNest
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake
        inst.OnSave = OnSave
        inst.OnPreLoad = OnPreLoad
        inst.OnLoad = OnLoad

        MakeTreeBlowInWindGust(inst, {
            "short",
            "normal",
            "tall",
            "old",
        }, TUNING.DECIDUOUS_WINDBLOWN_SPEED, TUNING.DECIDUOUS_WINDBLOWN_FALL_CHANCE)
        MakeHauntableWork(inst)
        MakeSnowCovered(inst, .01)
        MakeLargePropagator(inst)
        MakeTreeBurnable(inst)

        if state == "burnt" then
            OnBurnt(inst)
        elseif state == "stump" then
            MakeStump(inst)
        elseif state == "piko_nest" then
            inst:MakePikoNest()
        end

        inst.AnimState:SetTime(math.random() * 2)
        PushSway(inst)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return  MakeTeaTree("teatree", 0),
        MakeTeaTree("teatree_short", 1),
        MakeTeaTree("teatree_normal", 2),
        MakeTeaTree("teatree_tall", 3),
        MakeTeaTree("teatree_burnt", 0, "burnt"),
        MakeTeaTree("teatree_stump", 0, "stump"),
        MakeTeaTree("teatree_piko_nest", 0, "piko_nest")

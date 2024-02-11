local assets =
{
    Asset("ANIM", "anim/tree_leaf_short.zip"),
    Asset("ANIM", "anim/tree_leaf_normal.zip"),
    Asset("ANIM", "anim/tree_leaf_tall.zip"),

    Asset("ANIM", "anim/teatree_trunk_build.zip"), --trunk build (winter leaves build)
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

local teatree_data = {
    leavesbuild = "teatree_build",
    prefab_name = "teatree",
    normal_loot = {"log", "twigs", "teatree_nut"},
    short_loot = {"log"},
    tall_loot = {"log", "log", "twigs", "teatree_nut", "teatree_nut"},
    drop_nut = true,
    fx = "green_leaves",
    chopfx = "green_leaves_chop",
    shelter = true,
}

local function getstatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

--#region animation

local function makeanims(stage)
    return {
        idle = "idle_" .. stage,
        sway1 = "sway1_loop_" .. stage,
        sway2 = "sway2_loop_" .. stage,
        swayaggropre = "sway_agro_pre",
        swayaggro = "sway_loop_agro",
        swayaggropst = "sway_agro_pst",
        swayaggroloop = "idle_loop_agro",
        swayfx = "swayfx_" .. stage,
        chop = "chop_" .. stage,
        fallleft = "fallleft_" .. stage,
        fallright = "fallright_" .. stage,
        stump = "stump_" .. stage,
        burning = "burning_loop_" .. stage,
        burnt = "burnt_" .. stage,
        chop_burnt = "chop_burnt_" .. stage,
        idle_chop_burnt = "idle_chop_burnt_" .. stage,
        dropleaves = "drop_leaves_" .. stage,
        growleaves = "grow_leaves_" .. stage,
        blown1 = "blown_loop_" .. stage .. "1",
        blown2 = "blown_loop_" .. stage .."2",
        blown_pre = "blown_pre_" .. stage,
        blown_pst = "blown_pst_" .. stage
    }
end

local short_anims = makeanims("short")
local tall_anims = makeanims("tall")
local normal_anims = makeanims("normal")

local function SpawnLeafFX(inst, waittime, chop)
    if inst:HasTag("fire") or inst:HasTag("stump") or inst:HasTag("burnt") or inst:IsAsleep() then
        return
    end
    if waittime then
        inst:DoTaskInTime(waittime, function(inst, chop)
            SpawnLeafFX(inst, nil, chop)
        end)
        return
    end

    local fx = (chop and teatree_data.chopfx) and SpawnPrefab(teatree_data.chopfx)
        or (teatree_data.fx and SpawnPrefab(teatree_data.fx)) or nil

    if fx then
        local x, y, z= inst.Transform:GetWorldPosition()
        if inst.components.growable and inst.components.growable.stage == 1 then
            y = y + 0 --Short FX height
        elseif inst.components.growable and inst.components.growable.stage == 2 then
            y = y - .3 --Normal FX height
        elseif inst.components.growable and inst.components.growable.stage == 3 then
            y = y + 0 --Tall FX height
        end
        if chop then y = y + (math.random() * 2) end --Randomize height a bit for chop FX
        fx.Transform:SetPosition(x, y, z)
    end
end

local function PushSway(inst)
    inst.AnimState:PushAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
end

local function Sway(inst, ...)
    if inst.sg:HasStateTag("burning") or inst:HasTag("stump") then return end

    PushSway(inst)
end
--#endregion

--#region growable component

local function GrowLeavesFn(inst)
    if inst:HasTag("stump") or inst:HasTag("burnt") or inst:HasTag("fire") then
        inst:RemoveEventCallback("animover", GrowLeavesFn)
        return
    end

    if teatree_data.leavesbuild then
        inst.AnimState:OverrideSymbol("swap_leaves", teatree_data.leavesbuild, "swap_leaves")
    else
        inst.AnimState:ClearOverrideSymbol("swap_leaves")
    end

    if inst.components.growable then
        if inst.components.growable.stage == 1 then
            inst.components.lootdropper:SetLoot(teatree_data.short_loot)
        elseif inst.components.growable.stage == 2 then
            inst.components.lootdropper:SetLoot(teatree_data.normal_loot)
        else
            inst.components.lootdropper:SetLoot(teatree_data.tall_loot)
        end
    end

    inst.leaf_state = inst.target_leaf_state
    inst.AnimState:Show("mouseover")

    Sway(inst)
end

local function OnChangeLeaves(inst)
    if inst:HasTag("stump") or inst:HasTag("burnt") or inst:HasTag("fire") then
        inst.targetleaveschangetime = nil
        inst.leaveschangetask = nil
        return
    end

    if inst.components.workable and inst.components.workable.lastworktime and inst.components.workable.lastworktime < GetTime() - 10 then
        inst.targetleaveschangetime = GetTime() + 11
        inst.leaveschangetask = inst:DoTaskInTime(11, OnChangeLeaves)
        return
    else
        inst.targetleaveschangetime = nil
        inst.leaveschangetask = nil
    end

    inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
    inst.build = "normal"



    if teatree_data.leavesbuild then
        inst.AnimState:OverrideSymbol("swap_leaves", teatree_data.leavesbuild, "swap_leaves")
    else
        inst.AnimState:ClearOverrideSymbol("swap_leaves")
    end
    inst.AnimState:PlayAnimation(inst.anims.growleaves)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    inst:ListenForEvent("animover", GrowLeavesFn)

    if teatree_data.shelter then
        if not inst:HasTag("shelter") then inst:AddTag("shelter") end
    else
        while inst:HasTag("shelter") do inst:RemoveTag("shelter") end
    end
end

local function ChangeSizeFn(inst)
    inst:RemoveEventCallback("animover", ChangeSizeFn)
    if inst.components.growable then
        if inst.components.growable.stage == 1 then
            inst.anims = short_anims
        elseif inst.components.growable.stage == 2 then
            inst.anims = normal_anims
        else
            inst.anims = tall_anims
        end
    end

    Sway(inst)
end

local growth_stages = {
    {
        name = "short",
        time = function()
            return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[1].base, TUNING.DECIDUOUS_GROW_TIME[1].random)
        end,
        fn = function(inst)
            inst.anims = short_anims
            if inst.components.workable then
               inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_SMALL)
            end
            inst.components.lootdropper:SetLoot(teatree_data.short_loot)
        end,
        growfn = function(inst)
            inst.AnimState:PlayAnimation("grow_tall_to_short")
            inst:ListenForEvent("animover", ChangeSizeFn)
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
        end,
    },
    {
        name="normal",
        time = function()
            return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[2].base, TUNING.DECIDUOUS_GROW_TIME[2].random)
        end,
        fn = function(inst)
            inst.anims = normal_anims
            if inst.components.workable then
                inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_NORMAL)
            end
            inst.components.lootdropper:SetLoot(teatree_data.normal_loot)
        end,
        growfn =  function(inst)
            inst.AnimState:PlayAnimation("grow_short_to_normal")
            inst:ListenForEvent("animover", ChangeSizeFn)
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
        end,
    },
    {
        name="tall",
        time = function(inst)
            return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[3].base, TUNING.DECIDUOUS_GROW_TIME[3].random)
        end,
        fn = function(inst)
            inst.anims = tall_anims
            if inst.components.workable then
                inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_TALL)
            end
            inst.components.lootdropper:SetLoot(teatree_data.tall_loot)
        end,
        growfn = function(inst)
            inst.AnimState:PlayAnimation("grow_normal_to_tall")
            inst:ListenForEvent("animover", ChangeSizeFn)
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
        end,
    },
}

local function detachchild(inst)
    if inst.components.spawner and inst.components.spawner.child then
        local child = inst.components.spawner.child
        if child.components.knownlocations then
            child.components.knownlocations:ForgetLocation("home")
        end
        child:RemoveComponent("homeseeker")
    end
end

local function chop_tree(inst, chopper, chopsleft, numchops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

    SpawnLeafFX(inst, nil, true)

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/in_tree")
    end

    inst.AnimState:PlayAnimation(inst.anims.chop)
    PushSway(inst)
end

local function dig_up_stump(inst, chopper)
    inst:Remove()
    inst.components.lootdropper:SpawnLootPrefab("log")
end

local function chop_down_tree(inst, chopper)
    inst:RemoveComponent("burnable")
    MakeSmallBurnable(inst)
    inst:RemoveComponent("propagator")
    MakeSmallPropagator(inst)
    inst:RemoveComponent("workable")
    --inst:RemoveComponent("blowinwindgust")
    inst:RemoveComponent("hauntable")
    MakeHauntableIgnite(inst)

    while inst:HasTag("shelter") do inst:RemoveTag("shelter") end
    while inst:HasTag("cattoyairborne") do inst:RemoveTag("cattoyairborne") end
    inst:AddTag("stump")

    if inst.leaveschangetask then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end

    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

    local pt = Vector3(inst.Transform:GetWorldPosition())
    local hispos = Vector3(chopper.Transform:GetWorldPosition())

    local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0

    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    inst.components.inventory:DropEverything(false, false)

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end

    detachchild(inst)

    inst:DoTaskInTime(.4, function()
        local scale = (inst.components.growable and inst.components.growable.stage > 2) and .5 or .25
        ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, scale, inst, 6)
    end)

    RemovePhysicsColliders(inst)
    inst.AnimState:PushAnimation(inst.anims.stump)
    inst.MiniMapEntity:SetIcon("teatree_stump.tex")

    if inst.leaveschangetask then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    if inst.components.growable then
        inst.components.growable:StopGrowing()
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
    inst.components.inventory:DropEverything(false, false)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()
end

local function growfromseed (inst)
    inst.components.growable:SetStage(1)

    if TheWorld.state.season then
        inst.build = "normal"
        inst.leaf_state = "normal"
        inst.target_leaf_state = "normal"
    end

    if teatree_data.leavesbuild then
        inst.AnimState:OverrideSymbol("swap_leaves", teatree_data.leavesbuild, "swap_leaves")
    else
        inst.AnimState:ClearOverrideSymbol("swap_leaves")
    end

    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    inst.anims = short_anims

    PushSway(inst)
end

--#endregion

--#region fire

local function BurnInventoryItems(inst)
    if inst.components.inventory then
        local burnableItems = inst.components.inventory:GetItems(function(k, v) return v.components.burnable end)
        for index, burnableItem in ipairs(burnableItems) do
            burnableItem.components.burnable:Ignite(true)
        end
    end
end

local function OnBurnt(inst, immediate)
    local function onburntchanges(inst)
        inst:RemoveComponent("growable")
        -- inst:RemoveComponent("blowinwindgust")
        inst:RemoveComponent("spawner")
        inst:RemoveComponent("hauntable")

        while inst:HasTag("shelter") do inst:RemoveTag("shelter") end
        while inst:HasTag("cattoyairborne") do inst:RemoveTag("cattoyairborne") end

        inst:RemoveTag("fire")

        inst.components.lootdropper:SetLoot({})
        if teatree_data.drop_nut then
            inst.components.lootdropper:AddChanceLoot("teatree_nut", 0.1)
        end

        if inst.components.workable then
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnWorkCallback(nil)
            inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
        end

        if inst.leaveschangetask then
            inst.leaveschangetask:Cancel()
            inst.leaveschangetask = nil
        end

        detachchild(inst)


        MakeHauntableWork(inst)

        inst.AnimState:PlayAnimation(inst.anims.burnt, true)
        inst.MiniMapEntity:SetIcon("teatree_burnt.tex")
        inst:DoTaskInTime(3 * FRAMES, function(inst)
            if inst.components.burnable and inst.components.propagator then
                inst.components.burnable:Extinguish()
                inst.components.propagator:StopSpreading()
                inst:RemoveComponent("burnable")
                inst:RemoveComponent("propagator")
            end
        end)
    end

    inst:AddTag("burnt")
    if immediate then
        onburntchanges(inst)
    else
        inst:DoTaskInTime(0.5, onburntchanges)
    end
    inst.AnimState:SetRayTestOnBB(true);
end

local function tree_burnt(inst)
    OnBurnt(inst)

    if inst.leaveschangetask then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end
end

local function OnIgnite(inst)
    BurnInventoryItems(inst)

    if inst.components.spawner then
        local child = inst.components.spawner.child
        if child then
            child.components.knownlocations:ForgetLocation("home")
        end

        if inst.components.spawner:IsOccupied() then
            inst.components.spawner:ReleaseChild()
        end
    end
end
--#endregion

--#region spawner

local function GetNewChildPrefab()
    return math.random() < 0.2 and "piko_orange" or "piko"
end

local function OnVacated(inst, child)
    child.sg:GoToState("descendtree")
end

local function OnOccupied(inst,child)
    if child.components.inventory:NumItems() > 0 then
        for i, item in ipairs(child.components.inventory:GetItems(function() return true end)) do
            child.components.inventory:DropItem(item)
            inst.components.inventory:GiveItem(item)
        end
    end
end

local function start_spawning(inst)
    if inst.components.spawner then
        inst.components.spawner:SpawnWithDelay(2 + math.random(20))
    end
end

local function stop_spawning(inst)
    if inst.components.spawner then
        inst.components.spawner:CancelSpawning()
    end
end

local function OnPhaseChange(inst, phase)
    if phase == "day" or (TheWorld.state.moonphase == "new" and phase == "night") then
        start_spawning(inst)
    else
        stop_spawning(inst)
    end
end

local function SetUpSpawner(inst)
    inst:AddTag("dumpchildrenonignite")

    inst:AddComponent("spawner")
    inst.components.spawner:Configure("piko", 10) --TUNING.PIKO_RESPAWN_TIME
    inst.components.spawner.childfn = GetNewChildPrefab
    inst.components.spawner:SetOnVacateFn(OnVacated)
    inst.components.spawner:SetOnOccupiedFn(OnOccupied)

    inst:WatchWorldState("phase", OnPhaseChange)
end

--#endregion

--#region save load and stuff

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
                inst.components.burnable:SetOnBurntFn(tree_burnt)
                inst.components.burnable.extinguishimmediately = false
            end
        end

        if not inst.components.propagator then
            if inst:HasTag("stump") then
                MakeSmallPropagator(inst)
            else
                MakeLargePropagator(inst)
            end
        end
    end

    if not inst:HasTag("burnt") and inst:HasTag("fire") then
        inst.sg:GoToState("empty")
        if not inst:HasTag("stump") then
            inst.AnimState:ClearOverrideSymbol("legs")
            inst.AnimState:ClearOverrideSymbol("legs_mouseover")
        end
        inst.AnimState:SetBank("tree_leaf")
        OnBurnt(inst, true)
    end

    if not inst.components.inspectable then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus
    end

end

local function OnSave(inst, data)
    data.burnt = inst:HasTag("burnt") or inst:HasTag("fire")
    data.stump = inst:HasTag("stump")
    data.build = inst.build
    data.target_leaf_state = inst.target_leaf_state
    data.leaf_state = inst.leaf_state

    if inst.leaveschangetask and inst.targetleaveschangetime then
        data.leaveschangetime = inst.targetleaveschangetime - GetTime()
    end
end

local function OnLoad(inst, data)
    if not data then
        if inst.build ~= "normal" or inst.leaf_state ~= inst.target_leaf_state then
            OnChangeLeaves(inst)
        else
            inst.AnimState:Show("mouseover")
            Sway(inst)
        end
        return
    end

    if data.spawner then
        SetUpSpawner(inst)
    end

    inst.build = data.build or "normal"

    inst.target_leaf_state = data.target_leaf_state
    inst.leaf_state = data.leaf_state

    if inst.components.growable then
        if inst.components.growable.stage == 1 then
            inst.anims = short_anims
        elseif inst.components.growable.stage == 2 then
            inst.anims = normal_anims
        else
            inst.anims = tall_anims
        end
    else
        inst.anims = tall_anims
    end

    if data.burnt then
        inst:AddTag("fire") -- Add the fire tag here: OnEntityWake will handle it actually doing burnt logic
        inst.MiniMapEntity:SetIcon("teatree_burnt.tex")
    elseif data.stump then
        while inst:HasTag("shelter") do inst:RemoveTag("shelter") end
        while inst:HasTag("cattoyairborne") do inst:RemoveTag("cattoyairborne") end
        inst:RemoveComponent("burnable")
        if not inst:HasTag("stump") then inst:AddTag("stump") end

        inst.AnimState:PlayAnimation(inst.anims.stump)
        inst.MiniMapEntity:SetIcon("teatree_stump.png")

        MakeSmallBurnable(inst)
        inst:RemoveComponent("workable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("growable")
        -- inst:RemoveComponent("blowinwindgust")
        RemovePhysicsColliders(inst)

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(dig_up_stump)
        inst.components.workable:SetWorkLeft(1)
    else
        if inst.build ~= "normal" or inst.leaf_state ~= inst.target_leaf_state then
            OnChangeLeaves(inst)
        else
            inst.AnimState:Show("mouseover")
            Sway(inst)
        end
    end

    if data and data.leaveschangetime then
        inst.leaveschangetask = inst:DoTaskInTime(data.leaveschangetime, OnChangeLeaves)
    end
end
--#endregion

--#region wind

local function OnGustAnimDone(inst)
    if inst:HasTag("stump") or inst:HasTag("burnt") then
        inst:RemoveEventCallback("animover", OnGustAnimDone)
        return
    end
    if inst.components.blowinwindgust and inst.components.blowinwindgust:IsGusting() then
        local anim = math.random(1,2)
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

local function OnGustFall(inst)
    if inst:HasTag("burnt") then
        chop_down_burnt_tree(inst, GetPlayer())
    else
        chop_down_tree(inst, GetPlayer())
    end
end

--#endregion

local function MakeTeaTree(name, build, stage, data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("teatree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("teatree")
        inst:AddTag("shelter")
        inst:AddTag("workable")
        inst:AddTag("cattoyairborne")

        inst.build = build
        inst.color = 0.7 + math.random() * 0.3

        inst.AnimState:SetBank("tree_leaf")
        inst.AnimState:SetBuild("teatree_trunk_build")
        if teatree_data.leavesbuild then
            inst.AnimState:OverrideSymbol("swap_leaves", teatree_data.leavesbuild, "swap_leaves")
        end
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        --inst:AddComponent("mystery")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree)

        -- The inventory is separate from the loot in the regard that it stores items that entities deposit in the tree.
        -- An example of this is the squirrel (ie. piko), which steals items off the ground and takes them back to the tree.
        inst:AddComponent("inventory")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(stage > 0 and stage or math.random(1, 3))
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        --[[
        inst:AddComponent("blowinwindgust")
        inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING.DECIDUOUS_WINDBLOWN_SPEED)
        inst.components.blowinwindgust:SetDestroyChance(TUNING.DECIDUOUS_WINDBLOWN_FALL_CHANCE)
        inst.components.blowinwindgust:SetGustStartFn(OnGustStart)
        inst.components.blowinwindgust:SetDestroyFn(OnGustFall)
        inst.components.blowinwindgust:Start()
        --]]

        MakeHauntableWork(inst)
        MakeSnowCovered(inst, .01)
        MakeLargePropagator(inst)
        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(tree_burnt)
        inst.components.burnable.extinguishimmediately = false
        inst.components.burnable:SetOnIgniteFn(OnIgnite)

        inst.leaf_state = "normal"
        inst.lastleaffxtime = 0
        inst.leaffxinterval = math.random(TUNING.MIN_SWAY_FX_FREQUENCY, TUNING.MAX_SWAY_FX_FREQUENCY)

        inst.SpawnLeafFX = SpawnLeafFX
        inst.growfromseed = growfromseed
        inst.SetUpSpawner = SetUpSpawner
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake
        inst.Sway = Sway
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        if data == "burnt" then
            OnBurnt(inst)
        end

        if data == "stump" then
            inst:RemoveTag("shelter")
            inst:RemoveComponent("burnable")
            inst:RemoveComponent("workable")
            inst:RemoveComponent("propagator")
            inst:RemoveComponent("growable")
            inst:RemoveComponent("blowinwindgust")

            inst:AddTag("stump")

            inst.AnimState:PlayAnimation(inst.anims.stump)
            inst.MiniMapEntity:SetIcon("teatree_stump.tex")

            MakeSmallPropagator(inst)
            MakeSmallBurnable(inst)
            RemovePhysicsColliders(inst)

            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(dig_up_stump)
            inst.components.workable:SetWorkLeft(1)
        end

        if data == "piko_nest" then
            SetUpSpawner(inst)
        end

        inst:SetStateGraph("SGdeciduoustree")
        inst.sg:GoToState("empty")

        inst:SetPrefabName(teatree_data.prefab_name)
        inst.AnimState:SetTime(math.random() * 2)

        inst:ListenForEvent("sway", inst.Sway)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return  MakeTeaTree("teatree", "normal", 0),
        MakeTeaTree("teatree_short", "normal", 1),
        MakeTeaTree("teatree_normal", "normal", 2),
        MakeTeaTree("teatree_tall", "normal", 3),
        MakeTeaTree("teatree_burnt", "normal", 0, "burnt"),
        MakeTeaTree("teatree_stump", "normal", 0, "stump"),
        MakeTeaTree("teatree_piko_nest", "normal", 0, "piko_nest")

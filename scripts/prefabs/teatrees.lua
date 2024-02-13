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

local ChangeSizeFn

local STAGES = {
    {
        name = "short",
        loot = {"log"},
        time = function()
            return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[1].base, TUNING.DECIDUOUS_GROW_TIME[1].random)
        end,
        fn = function(inst)
            if inst.components.workable then
               inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_SMALL)
            end
            inst.components.lootdropper:SetLoot({"log"})
        end,
        growfn = function(inst)
            inst.AnimState:PlayAnimation("grow_tall_to_short")
            inst:ListenForEvent("animover", ChangeSizeFn)
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
        end,
        anims = {
            idle = "idle_short",
            sway1 = "sway1_loop_short",
            sway2 = "sway2_loop_short",
            chop = "chop_short",
            fallleft = "fallleft_short",
            fallright = "fallright_short",
            stump = "stump_short",
            burning = "burning_loop_short",
            burnt = "burnt_short",
            chop_burnt = "chop_burnt_short",
            idle_chop_burnt = "idle_chop_burnt_short",
            dropleaves = "drop_leaves_short",
            blown1 = "blown_loop_short1",
            blown2 = "blown_loop_short2",
            blown_pre = "blown_pre_short",
            blown_pst = "blown_pst_short"
        },
    },
    {
        name = "normal",
        loot = {"log", "twigs", "teatree_nut"},
        time = function()
            return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[2].base, TUNING.DECIDUOUS_GROW_TIME[2].random)
        end,
        fn = function(inst)
            if inst.components.workable then
                inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_NORMAL)
            end
            inst.components.lootdropper:SetLoot({"log", "twigs", "teatree_nut"})
        end,
        growfn =  function(inst)
            inst.AnimState:PlayAnimation("grow_short_to_normal")
            inst:ListenForEvent("animover", ChangeSizeFn)
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
        end,
        anims = {
            idle = "idle_normal",
            sway1 = "sway1_loop_normal",
            sway2 = "sway2_loop_normal",
            chop = "chop_normal",
            fallleft = "fallleft_normal",
            fallright = "fallright_normal",
            stump = "stump_normal",
            burning = "burning_loop_normal",
            burnt = "burnt_normal",
            chop_burnt = "chop_burnt_normal",
            idle_chop_burnt = "idle_chop_burnt_normal",
            dropleaves = "drop_leaves_normal",
            blown1 = "blown_loop_normal1",
            blown2 = "blown_loop_normal2",
            blown_pre = "blown_pre_normal",
            blown_pst = "blown_pst_normal"
        },
    },
    {
        name = "tall",
        loot = {"log", "log", "twigs", "teatree_nut", "teatree_nut"},
        time = function()
            return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[3].base, TUNING.DECIDUOUS_GROW_TIME[3].random)
        end,
        fn = function(inst)
            if inst.components.workable then
                inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_TALL)
            end
            inst.components.lootdropper:SetLoot({"log", "log", "twigs", "teatree_nut", "teatree_nut"})
        end,
        growfn = function(inst)
            inst.AnimState:PlayAnimation("grow_normal_to_tall")
            inst:ListenForEvent("animover", ChangeSizeFn)
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
        end,
        anims = {
            idle = "idle_tall",
            sway1 = "sway1_loop_tall",
            sway2 = "sway2_loop_tall",
            chop = "chop_tall",
            fallleft = "fallleft_tall",
            fallright = "fallright_tall",
            stump = "stump_tall",
            burning = "burning_loop_tall",
            burnt = "burnt_tall",
            chop_burnt = "chop_burnt_tall",
            idle_chop_burnt = "idle_chop_burnt_tall",
            dropleaves = "drop_leaves_tall",
            blown1 = "blown_loop_tall1",
            blown2 = "blown_loop_tall2",
            blown_pre = "blown_pre_tall",
            blown_pst = "blown_pst_short"
        },
    },
}

local function PushSway(inst, stage)
    inst.AnimState:PushAnimation(math.random() < 0.5 and STAGES[stage].anims.sway1 or STAGES[stage].anims.sway2, true)
end

local function Sway(inst, ...)
    if inst:HasTag("burning") or inst:HasTag("stump") then return end

    PushSway(inst, inst.components.growable.stage)
end

ChangeSizeFn = function(inst)
    inst:RemoveEventCallback("animover", ChangeSizeFn)

    Sway(inst)
end

local function StartSpawning(inst)
    if inst.components.spawner then
        inst.components.spawner:SpawnWithDelay(2 + math.random(20))
    end
end

local function StopSpawning(inst)
    if inst.components.spawner then
        inst.components.spawner:CancelSpawning()
    end
end

local function detachchild(inst)
    if inst.components.spawner and inst.components.spawner.child then
        local child = inst.components.spawner.child
        if child.components.knownlocations then
            child.components.knownlocations:ForgetLocation("home")
        end
        child:RemoveComponent("homeseeker")
    end
end

local function GetNewChildPrefab()
    return math.random() < 0.2 and "piko_orange" or "piko"
end

local function OnVacated(inst, child)
    child.sg:GoToState("descendtree")
end

local function OnOccupied(inst,child)
    if child.components.inventory:NumItems() > 0 then
        for i, item in ipairs(child.components.inventory:FindItems(function() return true end)) do
            child.components.inventory:DropItem(item)
            inst.components.inventory:GiveItem(item)
        end
    end
end

local function OnPhaseChange(inst, phase)
    if TheWorld.state.phase == "day" or (TheWorld.state.moonphase == "new" and TheWorld.state.phase == "night") then
        StartSpawning(inst)
    else
        StopSpawning(inst)
    end
end

local function SetUpSpawner(inst)
    inst.components.spawner.childname = "piko"
    inst.components.spawner.delay = TUNING.PIKO_RESPAWN_TIME -- This "delay" is actually respawn time
    inst.components.spawner.childfn = GetNewChildPrefab
    inst.components.spawner:SetOnVacateFn(OnVacated)
    inst.components.spawner:SetOnOccupiedFn(OnOccupied)

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst)
end

local function GetStatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

local function SpawnLeafFX(inst)
    if inst:HasTag("fire") or inst:HasTag("stump") or inst:HasTag("burnt") or inst:IsAsleep() then
        return
    end

    local fx = SpawnPrefab("green_leaves_chop")

    if fx then
        local x, y, z= inst.Transform:GetWorldPosition()

        -- FX height is slightly higher for normal stage
        y = y + (inst.components.growable and inst.components.growable.stage == 2 and 0.3 or 0)

        --Randomize height a bit for chop FX
        y = y + (math.random() * 2)

        fx.Transform:SetPosition(x, y, z)
    end
end

local function GrowFromSeed(inst)
    inst.components.growable:SetStage(1)

    inst.AnimState:OverrideSymbol("swap_leaves", "teatree_build", "swap_leaves")
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")

    PushSway(inst, inst.components.growable.stage)
end

local function OnWorkCallback(inst, chopper)
    if not (chopper and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

    SpawnLeafFX(inst)

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/in_tree")
    end

    inst.AnimState:PlayAnimation(STAGES[inst.components.growable.stage].anims.chop)
    PushSway(inst, inst.components.growable.stage)    
end

local function OnFinishCallbackStump(inst, digger)
    inst:Remove()
    inst.components.lootdropper:SpawnLootPrefab("log") 
end

local function OnFinishCallback(inst, chopper)
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

    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

    local pt = Vector3(inst.Transform:GetWorldPosition())
    local hispos = Vector3(chopper.Transform:GetWorldPosition())
    local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0

    if he_right then
        inst.AnimState:PlayAnimation(STAGES[inst.components.growable.stage].anims.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(STAGES[inst.components.growable.stage].anims.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    inst.components.inventory:DropEverything(false, false)

    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end

    detachchild(inst)

    inst:DoTaskInTime(0.4, function()
        local scale = (inst.components.growable and inst.components.growable.stage > 2) and 0.5 or 0.25
        ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, scale, inst, 6)
    end)

    RemovePhysicsColliders(inst)
    inst.AnimState:PushAnimation(STAGES[inst.components.growable.stage].anims.stump)
    inst.MiniMapEntity:SetIcon("teatree_stump.tex")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(OnFinishCallbackStump)
    inst.components.workable:SetWorkLeft(1)

    if inst.components.growable then
        inst.components.growable:StopGrowing()
    end

    inst:StopWatchingWorldState("phase", inst.OnPhaseChange)    
    inst.components.spawner:CancelSpawning()
end

local function OnFinishCallbackBurnt(inst, chopper)
    inst:RemoveComponent("workable")

    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    inst.AnimState:PlayAnimation(STAGES[inst.components.growable.stage].anims.chop_burnt)
    RemovePhysicsColliders(inst)

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    inst.components.inventory:DropEverything(false, false)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()   
end

local function burn_inventory_items(inst)
    if not inst.components.inventory then
        return
    end

    local burnable_items = inst.components.inventory:FindItems(function(v) return v.components.burnable end)
    for _, item in pairs(burnable_items) do
        item.components.burnable:Ignite(true)
    end    
end

local function OnBurnt(inst)
    local function onburntchanges(inst)
        local stage = inst.components.growable.stage
        inst:RemoveTag("shelter")
        inst:RemoveTag("cattoyairborne")
        inst:RemoveTag("fire")

        inst:RemoveComponent("growable")
        -- inst:RemoveComponent("blowinwindgust")
        inst:RemoveComponent("hauntable")

        inst.components.lootdropper:SetLoot({})
        inst.components.lootdropper:AddChanceLoot("teatree_nut", 0.1)

        if inst.components.workable then
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnWorkCallback(nil)
            inst.components.workable:SetOnFinishCallback(OnFinishCallbackBurnt)
        end

        -- detachchild(inst)

        MakeHauntableWork(inst)

        inst.AnimState:PlayAnimation(STAGES[stage].anims.burnt, true) -- todo
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
    inst:StopWatchingWorldState("phase", inst.OnPhaseChange)
    inst.components.spawner:CancelSpawning()
    inst:DoTaskInTime(0.5, onburntchanges)

    inst.AnimState:SetRayTestOnBB(true);
end

local function OnIgnite(inst)
    burn_inventory_items(inst)

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
                inst.components.burnable:SetOnIgniteFn(OnIgnite)
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
        inst.AnimState:SetBank("tree_leaf")
        OnBurnt(inst)
    end

    if not inst.components.inspectable then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
    end

end

local function OnSave(inst, data)
    data.burnt = inst:HasTag("burnt") or inst:HasTag("fire")
    data.stump = inst:HasTag("stump")
end

local function OnLoad(inst, data)
    if not data then
        inst.AnimState:Show("mouseover")
        Sway(inst)
        return
    end

    if data.burnt then
        inst:AddTag("fire") -- Add the fire tag here: OnEntityWake will handle it actually doing burnt logic
        inst.MiniMapEntity:SetIcon("teatree_burnt.tex")
        inst.StopWatchingWorldState("phase", inst.OnPhaseChange)
        inst.components.spawner:CancelSpawning()
    elseif data.stump then
        local stage = inst.components.growable.stage

        inst:RemoveTag("shelter")
        inst:RemoveTag("cattoyairborne")

        inst:RemoveComponent("burnable")
        inst:RemoveComponent("workable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("growable")
        -- inst:RemoveComponent("blowinwindgust")

        inst.AnimState:PlayAnimation(STAGES[stage].anims.stump)
        inst.MiniMapEntity:SetIcon("teatree_stump.tex")

        RemovePhysicsColliders(inst)
        MakeSmallBurnable(inst)

        if not inst:HasTag("stump") then
            inst:AddTag("stump")
        end

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(OnFinishCallbackStump)
        inst.components.workable:SetWorkLeft(1)

        inst.StopWatchingWorldState("phase", inst.OnPhaseChange)
        inst.components.spawner:CancelSpawning()
    else
        inst.AnimState:Show("mouseover")
        Sway(inst)
    end
end

local function MakeTeaTree(name, stage, state)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 0.25)

        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("teatree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("teatree")
        inst:AddTag("shelter")
        inst:AddTag("workable")
        inst:AddTag("cattoyairborne")

        local growth_stage = stage > 0 and stage or math.random(1, 3)
        local color = 0.7 + math.random() * 0.3 -- Is this line neccessary?

        inst.AnimState:SetBank("tree_leaf")
        inst.AnimState:SetBuild("teatree_trunk_build")
        inst.AnimState:PlayAnimation("idle_" .. STAGES[growth_stage].name)
        inst.AnimState:OverrideSymbol("swap_leaves", "teatree_build", "swap_leaves")
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        --inst:AddComponent("mystery")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(OnWorkCallback)
        inst.components.workable:SetOnFinishCallback(OnFinishCallback)

        -- The inventory is separate from the loot in the regard that it stores items that entities deposit in the tree.
        -- An example of this is the squirrel (ie. piko), which steals items off the ground and takes them back to the tree.
        inst:AddComponent("inventory")

        inst:AddComponent("growable")
        inst.components.growable.stages = STAGES
        inst.components.growable:SetStage(growth_stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        inst.growfromseed = GrowFromSeed
        inst.SetUpSpawner = SetUpSpawner
        inst.OnPhaseChange = OnPhaseChange
        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        --MakeTreeBlowInWindGust(inst, "DECIDUOUS")
        MakeHauntableWork(inst)
        MakeSnowCovered(inst, .01)
        MakeLargePropagator(inst)
        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(OnBurnt)
        inst.components.burnable.extinguishimmediately = false
        inst.components.burnable:SetOnIgniteFn(OnIgnite)


        inst:AddComponent("spawner")
        inst:SetUpSpawner()

        if state == "burnt" then
            OnBurnt(inst)
        elseif state == "stump" then
            inst:RemoveTag("shelter")
            inst:RemoveComponent("burnable")
            inst:RemoveComponent("workable")
            inst:RemoveComponent("propagator")
            inst:RemoveComponent("growable")
            --inst:RemoveComponent("blowinwindgust")

            inst:AddTag("stump")

            inst.AnimState:PlayAnimation(STAGES[growth_stage].anims.stump)
            inst.MiniMapEntity:SetIcon("teatree_stump.tex")

            MakeSmallPropagator(inst)
            MakeSmallBurnable(inst)
            RemovePhysicsColliders(inst)

            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(OnFinishCallbackStump)
            inst.components.workable:SetWorkLeft(1)
        elseif state ~= "piko_nest" then
            inst:StopWatchingWorldState("phase", OnPhaseChange)
            inst.components.spawner:CancelSpawning()
        end

        inst:SetPrefabName("teatree")
        inst.AnimState:SetTime(math.random() * 2)

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

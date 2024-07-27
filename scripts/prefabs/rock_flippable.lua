local assets =
{
    Asset("ANIM", "anim/rock_flipping.zip"),
    Asset("MINIMAP_IMAGE", "rock_flipping"),
}

local prefabs =
{
    "jellybug",
    "slugbug",
}

local function wobble(inst)
    if inst.AnimState:IsCurrentAnimation("idle") then
        inst.AnimState:PlayAnimation("wobble")
        inst.AnimState:PushAnimation("idle")
        --inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/flipping_rock/move")
    end
end

local function dowobbletest(inst)
    if math.random() < 0.5 then
        wobble(inst)
    end
end

local function setloot(inst)
    local tile = TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition())

    -- inst.components.lootdropper:AddExternalLoot("rocks") -- for wheeler tracker

    if tile == GROUND.PLAINS then
        inst.components.lootdropper:AddRandomLoot("jellybug", 2) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("rocks", 8) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("flint", 8) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("cutgrass", 8) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("goldnugget", 1) -- Weighted average
    elseif tile == GROUND.RAINFOREST then
        inst.components.lootdropper:AddRandomLoot("jellybug", 10.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("slugbug", 10.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("rocks", 15.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("flint", 15.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("cutgrass", 10.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("rabid_beetle", 0.1) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("goldnugget", 1) -- Weighted average
    elseif tile == GROUND.DEEPRAINFOREST then
        inst.components.lootdropper:AddRandomLoot("jellybug", 15.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("slugbug", 15.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("rocks", 5.0) -- Weighted averagettt
        inst.components.lootdropper:AddRandomLoot("flint", 5.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("cutgrass", 5.0) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("rabid_beetle", 10) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("snake_amphibious", 10) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("goldnugget", 3) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("relic_1", 1) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("relic_2", 1) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("relic_3", 1) -- Weighted average
    else
        inst.components.lootdropper:AddRandomLoot("rocks", 8) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("flint", 8) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("cutgrass", 8) -- Weighted average
        inst.components.lootdropper:AddRandomLoot("goldnugget", 1) -- Weighted average
    end
end

local function onpickedfn(inst, picker)
    inst.AnimState:PlayAnimation("flip_over", false)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/flipping_rock/open")
    inst.components.lootdropper:DropLoot(inst:GetPosition())
end

local function makefullfn(inst)
    inst.AnimState:PlayAnimation("flip_close")
    inst.AnimState:PushAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/flipping_rock/open")

    inst:DoTaskInTime(0, setloot)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("flip_over", false)
end

local function getregentimefn(inst)
    return TUNING.FLIPPABLE_ROCK_REPOPULATE_TIME  + math.random() * TUNING.FLIPPABLE_ROCK_REPOPULATE_VARIANCE
end

local function OnEntitySleep(inst)
    if inst.fliptask then
        inst.fliptask:Cancel()
        inst.fliptask = nil
    end
end

local function OnEntityWake(inst)
    if inst.fliptask then
        inst.fliptask:Cancel()
    end
    inst.fliptask = inst:DoPeriodicTask(10 + (math.random() * 10), dowobbletest)
end

local function OnWorked(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLootPrefab(SpawnPrefab("rocks"))

        if math.random() < 0.3 then
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("rocks"))
        end

        if inst.components.pickable.canbepicked then
            inst.components.lootdropper:DropLoot()
        end

        inst:Remove()
    end
end

local function fn(Sim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("rock_flipping.tex")
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("rock")
    inst:AddTag("flippable")

    MakeObstaclePhysics(inst, .1)

    inst.AnimState:SetBank("flipping_rock")
    inst.AnimState:SetBuild("rock_flipping")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("pickable")
    inst.components.pickable:SetUp(nil, TUNING.FLIPPABLE_ROCK_REPOPULATE_TIME)
    inst.components.pickable.getregentimefn = getregentimefn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makefullfn = makefullfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.quickpick = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetOnWorkCallback(OnWorked)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.chancerandomloot = 1.0 -- drop some random item X% of the time
    -- inst.components.lootdropper.alwaysinfront = true
    inst:DoTaskInTime(0, setloot)

    inst:AddComponent("inspectable")

    inst.fliptask = inst:DoPeriodicTask(10 + (math.random() * 10), dowobbletest)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    MakeHauntableWork()

    return inst
end

return Prefab("rock_flippable", fn, assets, prefabs)

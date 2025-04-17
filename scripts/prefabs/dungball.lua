local assets = {
    Asset("ANIM", "anim/tumbleweed.zip"),
    Asset("ANIM", "anim/dungball_build.zip"),
}

local prefabs = {
    "cutgrass",
    "twigs",
    "rocks",
    "flint",
    "poop",
}

local possible_loots = {
    cutgrass = 1,
    twigs = 1,
    rocks = 10,
    flint = 10,
    seeds = 1,
    relic_1 = 0.1,
}

local function setloot(inst)
    for k, v in pairs(possible_loots) do
        inst.components.lootdropper:AddRandomLoot(k, v)
    end
    inst.components.lootdropper.numrandomloot = math.random(1)

    local lootdropper = inst.components.lootdropper
    for k = 1, lootdropper.numrandomloot do
        local loot = lootdropper:PickRandomLoot()
        if loot then
            inst.components.storageloot:AddLoot(loot)
        end
    end
    inst.components.lootdropper:ClearRandomLoot()
end

local function OnPickUp(inst, picker)
    inst.components.lootdropper:DropLoot()
    local loots = inst.components.storageloot:TakeAllLoots()
    for i, v in ipairs(loots) do
        inst.components.lootdropper:SpawnLootPrefab(v)
    end

    inst.AnimState:PlayAnimation("break")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/dungball_break")
    inst.DynamicShadow:Enable(false)
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return true -- This makes the inventoryitem component not actually give the tumbleweed to the player
end

local function OnHauntFn(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        OnPickUp(inst)
    end
    return true
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.DynamicShadow:SetSize(1.7, 0.8)

    MakeCharacterPhysics(inst, 0.5, 1)
    inst.Physics:SetFriction(1)
    inst.Physics:SetRestitution(0.5)

    inst:AddTag("dungball")

    inst.AnimState:SetBank("tumbleweed")
    inst.AnimState:SetBuild("dungball_build")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddChanceLoot("poop", 1)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    inst.components.pickable.onpickedfn = OnPickUp
    inst.components.pickable.canbepicked = true
    inst.components.pickable.witherable = false

    inst:AddComponent("storageloot")

    setloot(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHauntFn)

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 5 + math.random() * 3
    -- inst.components.propagator.propagaterange = 5

    inst:ListenForEvent("onremove", function()
        if inst.beetle and inst.beetle:IsValid() then
            inst.bettle:PushEvent("bumped")
        end
    end)

    return inst
end

return Prefab("dungball", fn, assets, prefabs)

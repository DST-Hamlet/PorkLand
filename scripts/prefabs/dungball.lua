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

local possible_loot = {
    cutgrass = 1,
    twigs = 1,
    rocks = 10,
    flint = 10,
    seeds = 1,
    poop = 5,
    relic_1 = 0.1,
}

local function OnPickUp(inst, picker)
    local loots = weighted_random_choices(possible_loot, 2)
    table.insert(loots, "poop")

    for i, v in ipairs(loots) do
        if inst.components.lootdropper then
            inst.components.lootdropper:SpawnLootPrefab(v)
        end
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

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    inst.components.pickable.onpickedfn = OnPickUp
    inst.components.pickable.canbepicked = true
    inst.components.pickable.witherable = false

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHauntFn)

    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 5 + math.random() * 3
    -- inst.components.propagator.propagaterange = 5

    return inst
end

return Prefab("dungball", fn, assets, prefabs)

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

local function OnPickUp(inst, picker)
    for i, v in ipairs(inst.loot) do
        if inst.components.lootdropper then
            inst.components.lootdropper:SpawnLootPrefab(v)
        end
    end

    inst.AnimState:PlayAnimation("break")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/dungball_break")
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return true --This makes the inventoryitem component not actually give the tumbleweed to the player
end

local function MakeLoot(inst)
    local possible_loot = {
        {chance = 1,   item = "cutgrass"},
        {chance = 1,   item = "twigs"   },
        {chance = 10,  item = "rocks"   },
        {chance = 10,  item = "flint"   },
        {chance = 1,   item = "seeds"   },
        {chance = 5,   item = "poop"    },
        {chance = 0.1, item = "relic_1" },
    }

    local totalchance = 0
    for k, v in ipairs(possible_loot) do
        totalchance = totalchance + v.chance
    end

    inst.loot = {}
    table.insert(inst.loot, "poop")

    inst.lootaggro = {}
    local next_loot = nil
    local next_aggro = nil
    local next_chance = nil
    local num_loots = 2
    while num_loots > 0 do
        next_chance = math.random() * totalchance
        next_loot = nil
        next_aggro = nil
        for k, v in ipairs(possible_loot) do
            next_chance = next_chance - v.chance
            if next_chance <= 0 then
                next_loot = v.item
                if v.aggro then next_aggro = true end
                break
            end
        end
        if next_loot ~= nil then
            table.insert(inst.loot, next_loot)
            if next_aggro then
                table.insert(inst.lootaggro, true)
            else
                table.insert(inst.lootaggro, false)
            end
            num_loots = num_loots - 1
        end
    end
end

local function OnHauntFn(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        OnPickUp(inst)
        inst:Remove()
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
    inst.DynamicShadow:SetSize(1.7, .8)

    MakeCharacterPhysics(inst, .5, .5)
    inst.Physics:SetFriction(1)

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

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHauntFn)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    inst.components.pickable.onpickedfn = OnPickUp
    inst.components.pickable.canbepicked = true
    inst.components.pickable.witherable = false

    inst.MakeLoot = MakeLoot

    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 5 + math.random() * 3
    -- inst.components.propagator.propagaterange = 5

    MakeLoot(inst)

    return inst
end

return Prefab("dungball", fn, assets, prefabs)

local assets =
{
    Asset("ANIM", "anim/lava_pool.zip"),
}

local prefabs=
{
    "ash",
    "rocks",
    "charcoal",
    "rock1",
    "obsidian",
}

local function ShouldAcceptItem(inst, item)
    return item.prefab == "ice"
end

local function OnGetItemFromPlayer(inst, giver, item)
    local x, y, z = inst.Transform:GetWorldPosition()

    local obsidian = SpawnPrefab("obsidian")
    obsidian.Transform:SetPosition(x, y, z)

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(x, y, z)

    inst:Remove()
end

local function OnExtinguish(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    --spawn some things
    local radius = 1
    local things = {"rocks", "rocks", "ash", "ash", "charcoal"}
    for i = 1, #things do
        local thing = SpawnPrefab(things[i])
        thing.Transform:SetPosition(x + radius * UnitRand(), y, z + radius * UnitRand())
    end

    inst.AnimState:ClearBloomEffectHandle()
    inst:Remove()
end

local function FueledUpdateFn(inst)
    if inst.components.burnable and inst.components.fueled then
        inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
    end
end

local function FueledSectionCallback(new_section, old_section, inst)
    if new_section == 0 then
        inst.components.burnable:Extinguish()

    else
        if not inst.components.burnable:IsBurning() then
            inst.components.burnable:Ignite()
        end

        inst.components.burnable:SetFXLevel(new_section, inst.components.fueled:GetSectionPercent())
        local ranges = {1, 1, 1, 1}
        local output = {2, 5, 5, 10}
        inst.components.propagator.propagaterange = ranges[new_section]
        inst.components.propagator.heatoutput = output[new_section]
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.6)

    inst.AnimState:SetBank("lava_pool")
    inst.AnimState:SetBuild("lava_pool")
    inst.AnimState:PlayAnimation("dump")
    inst.AnimState:PushAnimation("idle_loop")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Physics:SetCollides(false)

    inst.Transform:SetFourFaced()

    inst:AddTag("fire")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, 0, 0))
    inst.components.burnable:SetOnExtinguishFn(OnExtinguish)

    inst:AddComponent("propagator")
    inst.components.propagator.damagerange = 1
    inst.components.propagator.damages = true
    inst.components.propagator:StartSpreading()

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.LAVAPOOL_FUEL_START)
    inst.components.fueled:SetSections(4)
    inst.components.fueled:SetUpdateFn(FueledUpdateFn)
    inst.components.fueled:SetSectionCallback(FueledSectionCallback)
    inst.components.fueled.maxfuel = TUNING.LAVAPOOL_FUEL_MAX
    inst.components.fueled.accepting = false
    inst.components.fueled.rate = 1

    inst:AddComponent("inspectable")

    inst:AddComponent("cooker")

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer

    MakeHauntable(inst)

    return inst
end

return Prefab("lavapool", fn, assets, prefabs)

local assets =
{
    Asset("ANIM", "anim/pango_basic.zip"),
    Asset("ANIM", "anim/pango_action.zip"),
}

local brain = require("brains/pangoldenbrain")

local prefabs =
{
    "meat",
}

SetSharedLootTable("pangolden",
{
    {"meat",            1.00},
    {"meat",            1.00},
    {"meat",            1.00},
})

local EATEN_GOLD = 1 / 3
local DRUNK_GOLD = 1 / 8

local function OnEat(inst)
    inst.gold_level = inst.gold_level + EATEN_GOLD
end

local function OnDrunk(inst)
    inst.gold_level = inst.gold_level + DRUNK_GOLD
end

local function OnSave(inst, data)
    data.gold_level = inst.gold_level
end

local function OnLoad(inst, data)
    if data and data.gold_level then
        inst.gold_level = data.gold_level
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.DynamicShadow:SetSize(6, 2)

    inst.AnimState:SetBank("pango")
    inst.AnimState:SetBuild("pango_action")
    inst.AnimState:PlayAnimation("idle_loop", true)

    MakeCharacterPhysics(inst, 100, 0.5)

    inst:AddTag("pangolden")
    inst:AddTag("animal")
    inst:AddTag("largecreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.gold_level = 0

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODGROUP.GOLDDUST}, {FOODGROUP.GOLDDUST})
    inst.components.eater:SetOnEatFn(OnEat)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pang_bod"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PANGOLDEN_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("pangolden")

    inst:AddComponent("locomotor")  -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.PANGOLDEN_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.PANGOLDEN_RUN_SPEED

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpangolden")

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
    MakeLargeBurnableCharacter(inst, "swap_fire")
    MakeLargeFreezableCharacter(inst, "pang_bod")
    inst.OnDrunk = OnDrunk
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("pangolden", fn, assets, prefabs)

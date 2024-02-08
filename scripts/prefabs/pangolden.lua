local assets=
{
	Asset("ANIM", "anim/pango_basic.zip"),
    Asset("ANIM", "anim/pango_action.zip"),
}

local brain = require "brains/pangoldenbrain"

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

local DRUNK_GOLD = 1/8
local EATEN_GOLD = 1/3

local function special_action(act)
    if act.doer.puddle and act.doer.puddle.stage > 0 then
        act.doer.puddle:shrink()
        act.doer.goldlevel = act.doer.goldlevel + DRUNK_GOLD
    end
end

local function special_action2(act)
    local gold = SpawnPrefab("goldnugget")
    local x, y, z = act.doer.Transform:GetWorldPosition()
    gold.Transform:SetPosition(x, y, z)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.AnimState:SetBank("pango")
    inst.AnimState:SetBuild("pango_action")
    inst.AnimState:PlayAnimation("idle_loop", true)
	inst.DynamicShadow:SetSize(6, 2)

    MakeCharacterPhysics(inst, 100, 0.5)

    inst:AddTag("pangolden")
    inst:AddTag("animal")
    inst:AddTag("largecreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("eater")
    inst.components.eater.foodprefs = {"GOLDDUST"}
    inst.components.eater.ablefoods = {"GOLDUST"}
    inst.components.eater.oneatfn = function()
        inst.goldlevel = inst.goldlevel + EATEN_GOLD
    end

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pang_bod"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PANGOLDEN_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("pangolden")

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst.special_action = special_action
    inst.special_action2 = special_action2

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
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

    inst.goldlevel = 0

    inst.OnSave = function(inst, data)
        data.goldlevel = inst.goldlevel
    end

    inst.OnLoad = function(inst, data)
        if data and data.goldlevel then
            inst.goldlevel = data.goldlevel
        end
    end

    return inst
end

return Prefab("pangolden", fn, assets, prefabs)

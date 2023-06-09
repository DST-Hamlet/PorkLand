require "brains/pangoldenbrain"
require "stategraphs/SGPangolden"

local assets=
{
	Asset("ANIM", "anim/pango_basic.zip"),
    Asset("ANIM", "anim/pango_action.zip"),
}

local prefabs =
{
    "meat",
}

SetSharedLootTable( 'pangolden',
{
    {'meat',            1.00},
    {'meat',            1.00},
    {'meat',            1.00},
})

local sounds =
{
    walk = "dontstarve_DLC003/creatures/pangolden/walk",
    grunt = "dontstarve_DLC003/creatures/pangolden/grunt",
    yell = "dontstarve_DLC003/creatures/pangolden/yell",
    swish = "dontstarve_DLC003/creatures/pangolden/tail_swish",
    curious = "dontstarve_DLC003/creatures/pangolden/curious",
    angry = "dontstarve_DLC003/creatures/pangolden/angry",
}

DRUNK_GOLD = 1/8
EATEN_GOLD = 1/3

local function Retarget(inst)

end

local function KeepTarget(inst, target)
    return (not inst.sg:HasStateTag("ball")) and distsq(Vector3(target.Transform:GetWorldPosition() ), Vector3(inst.Transform:GetWorldPosition() ) ) < TUNING.PANGOLDEN_CHASE_DIST * TUNING.PANGOLDEN_CHASE_DIST
end

local function OnNewTarget(inst, data)
    if inst.components.follower and data and data.target and data.target == inst.components.follower.leader then
        inst.components.follower:SetLeader(nil)
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    --inst.components.combat:ShareTarget(data.attacker, 30,function(dude)
        --return dude:HasTag("pangolden") and not dude:HasTag("player") and not dude.components.health:IsDead()
    --end, 5)
end

local function special_action(act)
    if act.doer.puddle and act.doer.puddle.stage > 0 then
        act.doer.puddle:shrink()
        act.doer.goldlevel = act.doer.goldlevel + DRUNK_GOLD
    end
end

local function special_action2(act)
    local gold = SpawnPrefab("goldnugget")
    local x,y,z = act.doer.Transform:GetWorldPosition()
    gold.Transform:SetPosition(x,y,z)
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	inst.sounds = sounds
	local shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	shadow:SetSize( 6, 2 )
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 100, .5)

    inst:AddTag("pango_baisc")
    anim:SetBank("pango")
    anim:SetBuild("pango_action")
    anim:PlayAnimation("idle_loop", true)

    inst:AddTag("pangolden")
    inst:AddTag("animal")
    inst:AddTag("largecreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakePoisonableCharacter(inst)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.GOLDDUST }, { FOODTYPE.GOLDDUST })
    inst.components.eater.oneatfn = function()
        inst.goldlevel = inst.goldlevel + EATEN_GOLD
    end

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pang_bod"
    inst.components.combat:SetDefaultDamage(TUNING.PANGOLDEN_DAMAGE)
    inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PANGOLDEN_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('pangolden')

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst.special_action = special_action
    inst.special_action2 = special_action2

    MakeLargeBurnableCharacter(inst, "pang_bod")
    MakeLargeFreezableCharacter(inst, "pang_bod")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 2.5
    inst.components.locomotor.runspeed = 8

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)

    local brain = require "brains/pangoldenbrain"
    inst:SetBrain(brain)
    inst:SetStateGraph("SGPangolden")

    inst:ListenForEvent("attacked", OnAttacked)

    inst.goldlevel = 0

    inst.OnSave = function(inst, data)
            data.goldlevel = inst.goldlevel
        end

    inst.OnLoad = function(inst, data)
            if data then
                if data.goldlevel then
                    inst.goldlevel = data.goldlevel
                end
            end
        end

    return inst
end

return Prefab( "forest/animals/pangolden", fn, assets, prefabs)

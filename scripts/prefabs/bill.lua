require "stategraphs/SGbill"
local brain = require "brains/billbrain"

local assets =
{
	Asset("ANIM", "anim/bill_agro_build.zip"),
	Asset("ANIM", "anim/bill_calm_build.zip"),
	Asset("ANIM", "anim/bill_basic.zip"),
	Asset("ANIM", "anim/bill_water.zip"),
}

local prefabs =
{
	"bill_quill",
}

local billsounds =
{

}

SetSharedLootTable( 'bill',
{
    {'meat',            1.00},
    {'bill_quill',      1.00},
    {'bill_quill',      1.00},
    {'bill_quill',      0.33},
})



function IsBillFood(item)
	return item:HasTag("billfood")
end

local function UpdateAggro(inst)
	local threatWasNearby = inst.threatNearby
	local player = ThePlayer

	local instPosition = Vector3(inst.Transform:GetWorldPosition())
	local playerPosition = Vector3(player.Transform:GetWorldPosition()) --TODO may need a fix.
	inst.lotusTheifNearby = (distsq(playerPosition, instPosition) < (TUNING.BILL_TARGET_DIST * TUNING.BILL_TARGET_DIST)) and player.components.inventory:FindItem(IsBillFood)

	-- If the threat level changes then modify the build.
	if inst.lotusTheifNearby then
		inst.AnimState:SetBuild("bill_agro_build")
	else
		inst.AnimState:SetBuild("bill_calm_build")
	end
end

local function UpdateTumble(inst)
	inst.letsGetReadyToTumble = true
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target) and (target == ThePlayer)
end


local function CanEat(inst, item)
	return item:HasTag("billfood")
end

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, 20, function(dude) return dude:HasTag("platapine") end, 2)
end

local function fn(Sim)
	local inst    = CreateEntity()
	local trans   = inst.entity:AddTransform()
	local anim    = inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	local physics = inst.entity:AddPhysics()
	local sound   = inst.entity:AddSoundEmitter()
	local shadow  = inst.entity:AddDynamicShadow()

	inst.letsGetReadyToTumble = false

	shadow:SetSize(1, 0.75)
	inst.Transform:SetFourFaced()

	MakeAmphibiousCharacterPhysics(inst, 1, 0.5)
	MakePoisonableCharacter(inst)

	anim:SetBank("bill")
	anim:SetBuild("bill_calm_build")
	anim:PlayAnimation("idle", true)

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	local bank = "bill"

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.BILL_RUN_SPEED

	inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetBanks(bank, bank.."_water")
        inst.components.amphibiouscreature:SetEnterWaterFn(
            function(inst)
                inst.landspeed = inst.components.locomotor.runspeed
                inst.components.locomotor.runspeed = TUNING.BILL_RUN_SPEED
                inst.hop_distance = inst.components.locomotor.hop_distance
                inst.components.locomotor.hop_distance = 4
            end)
        inst.components.amphibiouscreature:SetExitWaterFn(
            function(inst)
                if inst.landspeed then
                    inst.components.locomotor.runspeed = inst.landspeed
                end
                if inst.hop_distance then
                    inst.components.locomotor.hop_distance = inst.hop_distance
                end
            end)

	inst.components.locomotor.pathcaps = { allowocean = true }

	inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("platapine")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('bill')

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.BILL_HEALTH)
	inst.components.health.murdersound = "dontstarve/rabbit/scream_short"

	inst:AddComponent("inspectable")
	inst:AddComponent("sleeper")
	inst:AddComponent("eater")
	-- inst.components.eater:SetCanEatTestFn(CanEat) --TODO why we need a test function
	-- inst.components.eater:SetCanEat(CanEat) not working find hack

	inst:AddComponent("knownlocations")
	inst:DoTaskInTime(0, function() inst.components.knownlocations:RememberLocation("home", Point(inst.Transform:GetWorldPosition()), true) end)

	inst:DoPeriodicTask(1, UpdateAggro)
	inst:DoPeriodicTask(4, UpdateTumble)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.BILL_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.BILL_ATTACK_PERIOD)
	inst.components.combat:SetRange(2, 3)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat.hiteffectsymbol = "chest"

	MakeSmallBurnableCharacter(inst, "chest")
	MakeTinyFreezableCharacter(inst, "chest")

	inst:ListenForEvent("attacked", OnAttacked)



	inst:SetStateGraph("SGbill")
	inst:SetBrain(brain)
	inst.data = {}

	inst.sounds = billsounds

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

	return inst
end

return Prefab("forest/animals/bill", fn, assets, prefabs)

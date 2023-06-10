require "brains/spidermonkeybrain"
require "stategraphs/SGspidermonkey"

local assets =
{
	--Asset("ANIM", "anim/kiki_basic.zip"),
	--Asset("ANIM", "anim/spidermonkey_build.zip"),
    Asset("ANIM", "anim/spiderape_basics.zip"),
    Asset("ANIM", "anim/spiderape_build.zip"),

	Asset("SOUND", "sound/monkey.fsb"),
}

local prefabs =
{
	"poop",
	"monkeyprojectile",
	"monstermeat",
	"spidergland",
}

local SLEEP_DIST_FROMHOME   = 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_CHASEAWAY_DIST    = 32
local MAX_TARGET_SHARES     = 5
local SHARE_TARGET_DIST     = 40

SetSharedLootTable('spidermonkey',
{
    {'monstermeat',     1.0},
    {'monstermeat',     1.0},
    {'spidergland',    0.75},
    {'beardhair',      0.75},
    {'beardhair',      0.75},
    {'beardhair',      0.75},
    {'silk',           0.25},
    ----------Changed in DST
    {'monstermeat',     1.0},
    {'monstermeat',     0.5},
    {'spidergland',    0.75},
    {'beardhair',         1},
    {'silk',            0.5},
})

local function oneat(inst)
	-- Monkey ate some food. Give him some poop!
	if inst.components.inventory then
		local maxpoop = 3
		local poopstack = inst.components.inventory:FindItem(function(item) return item.prefab == "poop" end)
		if poopstack and poopstack.components.stackable.stacksize < maxpoop then
			local newpoop = SpawnPrefab("poop")
			inst.components.inventory:GiveItem(newpoop)
		elseif not poopstack then
			local newpoop = SpawnPrefab("poop")
			inst.components.inventory:GiveItem(newpoop)
		end
	end
end

local function OnAttacked(inst, data)
	inst.components.combat:SuggestTarget(data.attacker)
end

local function FindThreatToNest(inst)
    local notags = {"FX", "NOCLICK", "INLIMBO", "spidermonkey"}
    local yestags = {"character", "animal", "monster"}
    if inst.components.homeseeker and inst.components.homeseeker:HasHome() then
        return FindEntity(inst.components.homeseeker.home, TUNING.SPIDER_MONKEY_DEFEND_DIST, function(guy)
            return guy.components.health
                and not guy.components.health:IsDead()
                and inst.components.combat:CanTarget(guy)
        end, nil, notags, yestags)
    end
end

local function retargetfn(inst)
	local newtarget = FindThreatToNest(inst)

    if not newtarget then
        local notags = {"FX", "NOCLICK", "INLIMBO", "aquatic", "werepig"}
        local yestags = {"pig"}
        newtarget = FindEntity(inst,TUNING.SPIDER_MONKEY_TARGET_DIST, function(guy)
            return guy.components.health
                   and not guy.components.health:IsDead()
                   and inst.components.combat:CanTarget(guy)
        end, yestags, notags)
    end

    if not newtarget then
        local notags = {"FX", "NOCLICK", "INLIMBO", "aquatic", "spidermonkey", "aquatic"}
        local yestags = {"character", "monster"}
        newtarget = FindEntity(inst,TUNING.SPIDER_MONKEY_TARGET_DIST, function(guy)
            return  guy.components.health
                and not guy.components.health:IsDead()
                and inst.components.combat:CanTarget(guy)
        end, nil, notags, yestags)
    end

	return newtarget
end

local function KeepTarget(inst, target)
    local home = inst.components.homeseeker and inst.components.homeseeker.home

    if home then
        return distsq(Vector3(home.Transform:GetWorldPosition()), Vector3(inst.Transform:GetWorldPosition())) < MAX_CHASEAWAY_DIST*MAX_CHASEAWAY_DIST
    else
        return true
    end
end

local function IsInCharacterList(name)
	local characters = GetActiveCharacterList()

	for k,v in pairs(characters) do
		if name == v then
			return true
		end
	end
end

local function OnMonkeyDeath(inst, data)
	if data.inst:HasTag("monkey") then	-- A monkey died!
		if IsInCharacterList(data.cause) then	-- And it was the player! Run home!
			-- Drop all items, go home
			inst:DoTaskInTime(math.random(), function()
				if inst.components.inventory then
					inst.components.inventory:DropEverything(false, true)
				end

				if inst.components.homeseeker and inst.components.homeseeker.home then
					inst.components.homeseeker.home:PushEvent("monkeydanger")
				end
			end)
		end
	end
end

local function onpickup(inst, data)
	if data.item then
		if data.item.components.equippable and
		data.item.components.equippable.equipslot == EQUIPSLOTS.HEAD and not
		inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
			-- Ugly special case for how the PICKUP action works.
			-- Need to wait until PICKUP has called "GiveItem" before equipping item.
			inst:DoTaskInTime(0.1, function() inst.components.inventory:Equip(data.item) end)
		end
	end
end

local function DoFx(inst)
    if ExecutingLongUpdate then
        return
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local fx = SpawnPrefab("statue_transition_2")
    if fx then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.AnimState:SetScale(.8, .8, .8)
    end
    fx = SpawnPrefab("statue_transition")
    if fx then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.AnimState:SetScale(.8, .8, .8)
    end
end

local function onnear(inst)
    inst:AddTag("agitated")
    inst:PushEvent("agitated")
    -- inst.components.locomotor.walkspeed = TUNING.SPIDER_MONKEY_SPEED_AGITATED
end

local function onfar(inst)
    inst:RemoveTag("agitated")
    -- inst.components.locomotor.walkspeed = TUNING.SPIDER_MONKEY_SPEED
end

local function OnPooped(inst, poop)
	local heading_angle = -(inst.Transform:GetRotation()) + 180

	local pos = Vector3(inst.Transform:GetWorldPosition())
	pos.x = pos.x + (math.cos(heading_angle*DEGREES))
	pos.y = pos.y + 0.3
	pos.z = pos.z + (math.sin(heading_angle*DEGREES))
	poop.Transform:SetPosition(pos.x, pos.y, pos.z)

	if poop.components.inventoryitem then
		poop.components.inventoryitem:OnStartFalling()
	end
end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.soundtype = ""
	local shadow = inst.entity:AddDynamicShadow()
	shadow:SetSize(2, 1.25)

	inst.Transform:SetFourFaced()

	--inst.Transform:SetScale(2.2, 2.2, 2.2)
	MakeCharacterPhysics(inst, 40, 1.5)

    anim:SetBank("spiderape")
	anim:SetBuild("SpiderApe_build")

	anim:PlayAnimation("idle_loop", true)

	inst:AddTag("spider_monkey")
	inst:AddTag("animal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeLargeBurnableCharacter(inst, "body")
    MakeLargeFreezableCharacter(inst, "body")

	inst:AddComponent("inventory")

	inst:AddComponent("inspectable")

	inst:AddComponent("thief")

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = false }
    inst.components.locomotor.walkspeed = TUNING.SPIDER_MONKEY_SPEED_AGITATED
    inst.components.locomotor.runspeed = TUNING.SPIDER_MONKEY_SPEED_AGITATED

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_MONKEY_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.SPIDER_MONKEY_MELEE_RANGE)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_MONKEY_DAMAGE)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SPIDER_MONKEY_HEALTH)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("poop")
    inst.components.periodicspawner:SetRandomTimes(200, 400)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(15)
    --inst.components.periodicspawner:SetOnSpawnFn(OnPooped)
    inst.components.periodicspawner:Start()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("spidermonkey")
    inst.components.lootdropper.droppingchanceloot = false

	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
	inst.components.eater:SetOnEatFn(oneat)

	inst:AddComponent("sleeper")
	-- inst.components.sleeper:SetNocturnal()

    inst:AddComponent("knownlocations")
    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("spider_monkey_herd")

	inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(20, 23)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)

	inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

	local brain = require "brains/spidermonkeybrain"
	inst:SetBrain(brain)
	inst:SetStateGraph("SGspidermonkey")

    inst.listenfn = function(listento, data) OnMonkeyDeath(inst, data) end

	inst:ListenForEvent("onpickup", onpickup)
    inst:ListenForEvent("attacked", OnAttacked)

	return inst
end

return Prefab("porkland/monsters/spider_monkey", fn, assets, prefabs)

require "stategraphs/SGpiko"

-- TODO: Convert any rabbit related things such as audio and artwork to the piko (ie. squirrel).

local INTENSITY = .5

local assets =
{
	Asset("ANIM", "anim/ds_squirrel_basic.zip"),
	Asset("ANIM", "anim/squirrel_cheeks_build.zip"),
	Asset("ANIM", "anim/squirrel_build.zip"),

	Asset("ANIM", "anim/orange_squirrel_cheeks_build.zip"),
	Asset("ANIM", "anim/orange_squirrel_build.zip"),

	Asset("INV_IMAGE", "piko_orange"),

	Asset("SOUND", "sound/rabbit.fsb"),
}

local prefabs =
{
	"smallmeat",
	"cookedsmallmeat",
}

local pikosounds =
{
	scream = "dontstarve_DLC003/creatures/piko/scream",
	hurt = "dontstarve_DLC003/creatures/piko/scream",
}

local brain = require "brains/pikobrain"

local function updatebuild(inst, cheeks)
	local build = "squirrel_build"

	if cheeks then
		build = "squirrel_cheeks_build"
	end

	if inst:HasTag("orange") then
		build = "orange_"..build
	end

	inst.AnimState:SetBuild("squirrel_cheeks_build")
end

local function refreshbuild(inst)
	if inst.components.inventory:NumItems() > 0 then
		inst.updatebuild(inst, true)
	else
		inst.updatebuild(inst, false)
	end
end

local function OnDrop(inst)
	refreshbuild(inst)
	inst.sg:GoToState("stunned")
end

local function OnWake(inst)
	-- TODO: Decide what happens when a piko wakes.
end

local function OnSleep(inst)
	if inst.checktask then
		inst.checktask:Cancel()
		inst.checktask = nil
	end
end

local function GetCookableProduct(inst)
	return "cookedsmallmeat"
end

local function OnCooked(inst)
	inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/scream")
end

local function OnAttacked(inst, data)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 30, {'piko'})

	local num_friends = 0
	local maxnum = 5
	for k, v in pairs(ents) do
		v:PushEvent("gohome")
		num_friends = num_friends + 1

		if num_friends > maxnum then
			break
		end
	end
end

local function OnWentHome(inst)
    local tree = inst.components.homeseeker and inst.components.homeseeker.home or nil
    if not tree then return end
    if tree.components.inventory then
        inst.components.inventory:TransferInventory(tree)
        inst.updatebuild(inst, false)
    end
end

local function OnPickup(inst)
	inst.updatebuild(inst,true)
end

local function OnDrop(inst)
	refreshbuild(inst)
end


local function Retarget(inst)
    local dist = TUNING.PIKO_TARGET_DIST

    return FindEntity(inst, dist, function(guy)
		return not guy:HasTag("piko") and inst.components.combat:CanTarget(guy) and guy.components.inventory and (guy.components.inventory:NumItems() > 0)
    end)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnStolen(inst, victim, item)
	-- TODO: Sort out if anything needs to happen when a piko steals from another entity.
end

local function fadein(inst)
    inst.components.fader:StopAll()
	inst.AnimState:Show("eye_red")
	inst.AnimState:Show("eye2_red")
    inst.Light:Enable(true)
	if inst:IsAsleep() then
		inst.Light:SetIntensity(INTENSITY)
	else
		inst.Light:SetIntensity(0)
		inst.components.fader:Fade(0, INTENSITY, 3+math.random()*2, function(v) inst.Light:SetIntensity(v) end)
	end
end

local function fadeout(inst)
    inst.components.fader:StopAll()
	inst.AnimState:Hide("eye_red")
	inst.AnimState:Hide("eye2_red")
	if inst:IsAsleep() then
		inst.Light:SetIntensity(0)
	else
		inst.components.fader:Fade(INTENSITY, 0, 0.75+math.random()*1, function(v) inst.Light:SetIntensity(v) end)
	end
end

local function updatelight(inst)
    if inst.currentlyRabid then
        if not inst.lighton then
            inst:DoTaskInTime(math.random()*2, function()
                fadein(inst)
            end)

        else
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end
		inst.AnimState:Show("eye_red")
		inst.AnimState:Show("eye2_red")
        inst.lighton = true
    else
        if inst.lighton then
            inst:DoTaskInTime(math.random()*2, function()
                fadeout(inst)
            end)
        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end

		inst.AnimState:Hide("eye_red")
		inst.AnimState:Hide("eye2_red")

        inst.lighton = false
    end
end

local function OnDeath(inst)
	inst.Light:Enable(false)
end

local function SetAsRabid(inst, rabid)
 	inst.currentlyRabid = rabid
 	inst.components.sleeper.nocturnal = rabid
 	updatelight(inst)
end

local function transformtest(inst)
    if TheWorld.state.isnight and (TheWorld.state.moonphase == "full" or TheWorld.state.bloodmoon) then
        if not inst.currentlyRabid then
            inst:DoTaskInTime(1+(math.random()*1), function() SetAsRabid(inst, true) end)
        end
    else
        if inst.currentlyRabid then
            inst:DoTaskInTime(1+(math.random()*1), function() SetAsRabid(inst, false) end)
        end
    end
end

local function converttoorange(inst)

end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local physics = inst.entity:AddPhysics()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	shadow:SetSize(1, 0.75)

	local light = inst.entity:AddLight()
    light:SetFalloff(1)
    light:SetIntensity(INTENSITY)
    inst.Light:SetColour(150/255, 40/255, 40/255)  --197 10 10
    inst.Light:SetFalloff(0.9)
    inst.Light:SetRadius(2)
    light:Enable(false)

	inst.Transform:SetFourFaced()

	MakeCharacterPhysics(inst, 1, 0.12)

	anim:SetBank("squirrel")
	anim:SetBuild("squirrel_build")
	anim:PlayAnimation("idle", true)
--[[
	inst:DoPeriodicTask(5.0,
		function()
			local rabid = GetPlayer().components.sanity and GetPlayer().components.sanity:GetPercent(false) < TUNING.PIKO_RABID_SANITY_THRESHOLD
			SetAsRabid(inst, rabid)
		end)
]]
	inst.currentlyRabid = false

	inst:AddTag("animal")
	inst:AddTag("prey")
	inst:AddTag("piko")
	inst:AddTag("smallcreature")
	inst:AddTag("canbetrapped")
	inst:AddTag("cannotstealequipped")
    inst:AddTag("cattoy")
	inst:AddTag("catfood")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fader")

    MakePoisonableCharacter(inst)

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = TUNING.PIKO_RUN_SPEED

	inst:SetStateGraph("SGpiko")

	inst:SetBrain(brain)

	inst.data = {}

	-- Squirrels (ie. pikos), have the same diet as birds, mainly seeds,
	-- which is why this is being set on a non-avian creature.
	inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.SEEDS }, { FOODTYPE.SEEDS })

	inst:AddComponent("inventory")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.canbepickedup = false
	-- inst.components.inventoryitem:SetOnDroppedFn(OnDrop) Done in MakeFeedablePet
	inst.force_onwenthome_message = true
	inst:AddComponent("sanityaura")

	inst:AddComponent("cookable")
	inst.components.cookable.product = GetCookableProduct
	inst.components.cookable:SetOnCookedFn(OnCooked)

	inst:AddComponent("knownlocations")
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.PIKO_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PIKO_ATTACK_PERIOD)
    inst.components.combat:SetRange(0.7)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat.hiteffectsymbol = "chest"
	inst.components.combat.onhitotherfn = function(inst, other, damage) inst.components.thief:StealItem(other) end

    inst:AddComponent("thief")
    inst.components.thief:SetOnStolenFn(OnStolen)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.PIKO_HEALTH)
	inst.components.health.murdersound = "dontstarve_DLC003/creatures/piko/death"

	MakeSmallBurnableCharacter(inst, "chest")
	MakeTinyFreezableCharacter(inst, "chest")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({"smallmeat"})

	inst:AddComponent("tradable")

	inst:AddComponent("inspectable")
	inst:AddComponent("sleeper")

	inst.sounds = pikosounds

	inst.OnEntityWake = OnWake
	inst.OnEntitySleep = OnSleep

	inst.updatebuild = updatebuild

	inst.OnSave = function(inst, data)
		-- TODO: Determine if there will be another "rabid" condition for the piko and save it here.
		-- Use the rabbit as an example of how to do this, given that the rabbit has various models.
		if inst.lighton then
            data.lighton = inst.lighton
        end
        if inst:HasTag("orange") then
        	data.orange = true
        end
	end

	inst.OnLoad = function(inst, data)
        if data then
            if data.lighton then
                fadein(inst)
                inst.Light:Enable(true)
                inst.Light:SetIntensity(INTENSITY)
				inst.AnimState:Show("eye_red")
				inst.AnimState:Show("eye2_red")
                inst.lighton = true
            end
            if data.orange then
            	converttoorange(inst)
            end
        end
        if inst.spawntask then
        	inst.spawntask:Cancel()
        	inst.spawntask = nil
		end

		refreshbuild(inst)
		-- TODO: Determine if there will be another "rabid" condition for the piko and set it on load here.
		-- Use the rabbit as an example of how to do this, given that the rabbit has various models.
	end

    inst:WatchWorldState("isday", transformtest)
    inst:WatchWorldState("isdusk", transformtest)
    inst:WatchWorldState("isnight", transformtest)

	inst:ListenForEvent("death", OnDeath)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onwenthome", OnWentHome)
	inst:ListenForEvent("itemget", OnPickup)
	inst:ListenForEvent("dropitem", OnDrop)

	MakeFeedablePet(inst, TUNING.TOTAL_DAY_TIME*2, nil, OnDrop)

	-- When a piko is first created, ensure that it isn't rabid.
	SetAsRabid(inst, false)
	transformtest(inst)

	inst:ListenForEvent("exitlimbo", updatelight)

	return inst
end

local function orangefn()
	local inst = fn()

	inst:AddTag("orange")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.updatebuild(inst)

	return inst
end

return Prefab("forest/animals/piko", fn, assets, prefabs),
		Prefab("forest/animals/piko_orange", orangefn, assets, prefabs)

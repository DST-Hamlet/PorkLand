require("brains/glowflybrain")
require("stategraphs/SGglowfly")

local assets = {
	Asset("ANIM", "anim/lantern_fly.zip"),
}

local prefabs = {
    "glowfly_cocoon"
}

local brain = require("brains/glowflybrain")

local sounds = {
	takeoff = "dontstarve/creatures/mosquito/mosquito_takeoff",
	attack = "dontstarve/creatures/mosquito/mosquito_attack",
	-- buzz = "pl/creatures/glowfly/buzz_LP",
	hit = "pl/creatures/glowfly/hit",
	death = "pl/creatures/glowfly/death",
	explode = "dontstarve/creatures/mosquito/mosquito_explo",
}

SetSharedLootTable("glowfly", {
	{"lightbulb", .1},
})

SetSharedLootTable("glowflyinventory",
{
	{"lightbulb", 1},
})

local INTENSITY = .75

local function FadeIn(inst)
    inst.components.fader:StopAll()
    inst.Light:Enable(true)
	if inst:IsAsleep() then
		inst.Light:SetIntensity(INTENSITY)
	else
		inst.Light:SetIntensity(0)
		inst.components.fader:Fade(0, INTENSITY, 3+math.random()*2, function(v)
            inst.Light:SetIntensity(v)
        end)
	end
end

local function FadeOut(inst)
    inst.components.fader:StopAll()
	if inst:IsAsleep() then
		inst.Light:SetIntensity(0)
	else
		inst.components.fader:Fade(INTENSITY, 0, .75+math.random()*1, function(v)
            inst.Light:SetIntensity(v)
        end, function()
            inst.Light:Enable(false)
        end)
	end
end

-- 光源
local function UpdateLight(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local tile_type = TheWorld.Map:GetTileAtPoint(x,y,z)
    if tile_type == WORLD_TILES.DEEPRAINFOREST or tile_type == WORLD_TILES.GASJUNGLE then
        inst:AddTag("under_leaf_canopy")
    else
        inst:RemoveTag("under_leaf_canopy")
    end

    if (TheWorld.state.isnight or TheWorld.state.isdusk or inst:HasTag("under_leaf_canopy")) and not inst.components.inventoryitem.owner then
        if not inst.lighton then
            FadeIn(inst)
        else
            inst.Light:Enable(true)
            inst.Light:SetIntensity(INTENSITY)
        end
        inst.lighton = true
    else
        if inst.lighton then
            FadeOut(inst)
        else
            inst.Light:Enable(false)
            inst.Light:SetIntensity(0)
        end
        inst.lighton = false
    end
end

local function OnChangePhase(inst)
    inst:DoTaskInTime(2 + math.random() * 1, function()
        UpdateLight(inst)
    end)
end

local function OnWorked(inst, worker)
	if worker.components.inventory ~= nil then
        if inst.glowflyspawner ~= nil then
            inst.glowflyspawner:StopTracking(inst)
        end
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    else
		inst:Remove()
	end
end

-- 死亡时
local function OnDeath(inst)
    inst.components.fader:Fade(INTENSITY, 0, .75+math.random()*1, function(v)
        inst.Light:SetIntensity(v)
    end, function()
        inst.Light:Enable(false)
    end)
end

-- 孵化时
local function OnBorn(inst)
	inst.components.fader:Fade(0, INTENSITY, .75 + math.random() * 1, function(v)
        inst.Light:SetIntensity(v)
    end)
end

-- 检查删除萤火虫
local function CheckRemoveGlowfly(inst)
    for _, player in ipairs(AllPlayers) do
        if not inst:HasTag("cocoonspawn") and inst:GetDistanceSqToInst(player) > 30*30 and not inst.components.inventoryitem:IsHeld() then
            inst:Remove()
        end
    end
end

local function OnRemoveEntity(inst)
    if inst.glowflyspawner ~= nil then
        inst.glowflyspawner:StopTracking(inst)
    end
end

local function BeginCocoonStage(inst)
	inst:AddTag("wantstococoon")
end

local function ChangeToCocoon(inst, force)
    inst:AddTag("cocoonspawn")
    if force then
        if not TheWorld.state.istemperate then
            local pos = inst:GetPosition()
            local cocoon = SpawnPrefab("glowfly_cocoon")
            cocoon:AddTag("readytohatch")
            cocoon.Transform:SetPosition(pos.x, pos.y, pos.z)
            inst:Remove()
            if inst.glowflyspawner ~= nil then
                inst.glowflyspawner:StopTracking(inst)
            end
        end
    else
        inst.sg:GoToState("idle")
    	inst.AnimState:SetTime(math.random() * 2)
	end
end

local function OnDropped(inst)


    if inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(1)
	end

	if inst.brain ~= nil then
		inst.brain:Start()
	end

	if inst.sg ~= nil then
		inst.sg:Start()
	end

	UpdateLight(inst)
	inst.components.lootdropper:SetChanceLootTable("glowfly")
	inst.sg:GoToState("idle")

    if inst.glowflyspawner ~= nil then
        inst.glowflyspawner:StartTracking(inst)
    end

	if inst.components.stackable ~= nil then
		while inst.components.stackable:StackSize() > 1 do
			local item = inst.components.stackable:Get()
			if item ~= nil then
				if item.components.inventoryitem ~= nil then
					item.components.inventoryitem:OnDropped()
				end
				item.Physics:Teleport(inst.Transform:GetWorldPosition())
			end
		end
	end
end

local function ForceCocoon(inst)
	inst.ChangeToCocoon(inst, false)
end

local function GetStatus(inst)
	if inst.components.health:GetPercent() <= 0 then
    	return "DEAD"
    elseif inst.components.sleeper:IsAsleep() then
    	return "SLEEPING"
    end
end

local function SetCocoonTask(inst, time)
	if not time then
		time = math.random() * 3
	end
	inst.cocoon_task, inst.cocoon_taskinfo = inst:ResumeTask(time, function()
        inst.BeginCocoonStage(inst)
    end)
end

local function OnPutInInventory(inst)
	inst.components.lootdropper:SetChanceLootTable("glowflyinventory")
    if inst.glowflyspawner ~= nil then
        inst.glowflyspawner:StopTracking(inst)
    end
end

-- Save
local function OnSave(inst, data)
	if inst.cocoon_task ~= nil then
		data.cocoon_task = inst:TimeRemainingInTask(inst.cocoon_taskinfo)
	end

	if inst:HasTag("cocoonspawn") then
		data.cocoonspawn = true
	end
end

-- Load
local function OnLoad(inst, data)
	if data ~= nil then

        if data.cocoon_task ~= nil then
			inst.SetCocoonTask(inst, data.cocoon_task)
		end

        if data.cocoon then
			inst.ForceCocoon(inst)
		end

        if data.cocoonspawn then
			inst:AddTag("cocoonspawn")
		end
	end
end

local function commonfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLightWatcher()
	inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize( .8, .5 )

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(0.6,0.6,0.6)

	inst:AddTag("insect")
	inst:AddTag("flying")
	inst:AddTag("animal")
	inst:AddTag("smallcreature")
	inst:AddTag("glowfly")
	inst:AddTag("cattoyairborne")

    MakeAmphibiousCharacterPhysics(inst, 1, .5)
	inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
	inst.Physics:CollidesWith(COLLISION.FLYERS)

    inst.AnimState:SetBank("lantern_fly")
	inst.AnimState:SetBuild("lantern_fly")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetRayTestOnBB(true)

    inst.Light:SetFalloff(.7)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetRadius(2)
    inst.Light:SetColour(120/255, 120/255, 120/255)
    inst.Light:Enable(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fader")

	inst:AddComponent("locomotor")
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.walkspeed = TUNING.GLOWFLY_WALK_SPEED
	inst.components.locomotor.runspeed = TUNING.GLOWFLY_RUN_SPEED
    inst.components.locomotor.pathcaps = { allowocean = true }

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
	inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
	inst.components.inventoryitem.canbepickedup = false
	inst.components.inventoryitem:ChangeImageName("lantern_fly")

    -- 授粉组件
	inst:AddComponent("pollinator")

	inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("glowfly")

	inst:AddComponent("tradable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.NET)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(OnWorked)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "body"

	inst:AddComponent("sleeper")

	inst:AddComponent("knownlocations")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("death", OnDeath)

    inst:ListenForEvent("onchangecanopyzone", OnChangePhase)

    inst:WatchWorldState("phase", OnChangePhase)

	inst:SetStateGraph("SGglowfly")
	inst:SetBrain(brain)

    inst.glowflyspawner = TheWorld.components.glowflyspawner
    if inst.glowflyspawner ~= nil then
        inst.components.inventoryitem:SetOnPickupFn(inst.glowflyspawner.StopTrackingFn)
        inst:ListenForEvent("onremove", inst.glowflyspawner.StopTrackingFn)
        inst.glowflyspawner:StartTracking(inst)
    end

	inst.sounds = sounds

	inst.OnRemoveEntity = OnRemoveEntity

	inst.OnBorn = OnBorn
    inst.BeginCocoonStage = BeginCocoonStage
    inst.ForceCocoon = ForceCocoon
    inst.ChangeToCocoon = ChangeToCocoon
    inst.SetCocoonTask = SetCocoonTask

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	inst:DoTaskInTime(0, UpdateLight)
	inst:DoPeriodicTask(5, CheckRemoveGlowfly, math.random() * 5)

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
	MakeSmallBurnableCharacter(inst, "upper_body", Vector3(0, -1, 1))
	MakeTinyFreezableCharacter(inst, "upper_body", Vector3(0, -1, 1))

	return inst
end

return Prefab("glowfly", commonfn, assets, prefabs)

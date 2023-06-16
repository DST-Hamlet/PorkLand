local assets =
{
	Asset("ANIM", "anim/nettle.zip"),
	Asset("ANIM", "anim/nettle_bulb_build.zip"),
	Asset("ANIM", "anim/nettle_budding_build.zip"),
	Asset("SOUND", "sound/common.fsb"),
	Asset("MINIMAP_IMAGE", "nettle"),
}

local prefabs =
{
    "cutnettle",
   	"hacking_tall_grass_fx",
}
local valid_tiles= {
	WORLD_TILES.DEEPRAINFOREST,
	WORLD_TILES.DEEPRAINFOREST_NOCANOPY,
}
local function testtiles(tile)
	for i,tiletype in ipairs(valid_tiles) do
		if tiletype == tile then
			return true
		end
	end
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow")
	inst.AnimState:PushAnimation("idle", true)
	if inst.dryuptask then
		inst.dryuptask:Cancel()
		inst.dryuptask = nil
	end
end

local function makeemptyfn(inst)
	inst.AnimState:PlayAnimation("picked", true)
	if inst.dryuptask then
		inst.dryuptask:Cancel()
		inst.dryuptask = nil
	end
end

local function makebarrenfn(inst)
	if inst.dryuptask then
		inst.dryuptask:Cancel()
		inst.dryuptask = nil
	end

	if inst.AnimState:IsCurrentAnimation("idle_dead") then return end

	if inst.components.pickable and inst.components.pickable.withered then
		if not inst.components.pickable.hasbeenpicked then
			inst.AnimState:PlayAnimation("full_to_dead")
		else
			inst.AnimState:PlayAnimation("empty_to_dead")
		end
		inst.AnimState:PushAnimation("idle_dead")
	else
		inst.AnimState:PlayAnimation("idle_dead")
	end
end

local function onpickedfn(inst)
	inst.AnimState:PlayAnimation("picking")
	inst.AnimState:PushAnimation("picked", false)
	if inst.dryuptask then
		inst.dryuptask:Cancel()
		inst.dryuptask = nil
	end
end

local function testForGrowth(inst)
	--local sm =  GetSeasonManager()
	local pt = Vector3(inst.Transform:GetWorldPosition())
	local tile = TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)

	if (not testtiles(tile)) or TheWorld.state.iswinter then
		if not inst.components.pickable.paused then
			inst.components.pickable:MakeBarren()
			inst.components.pickable:Pause()
		end
	end
end

local function getstatus(inst)
	local pt = Vector3(inst.Transform:GetWorldPosition())
	local tile = TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)

   	if not testtiles(tile) then
   		return "WITHERED"
   	elseif inst.wet and not inst.components.pickable.canbepicked then
   		return "MOIST"
   	else
   		return "DEFAULT"
   	end
end

local function ontransplantfn(inst)
	local pt = Vector3(inst.Transform:GetWorldPosition())
	local tile = TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
	if not testtiles(tile) then
		inst.components.pickable:MakeBarren()
	else
		inst.components.pickable:MakeEmpty()
	end
	inst.components.pickable:Pause()
	testForGrowth(inst)
end

--[[ local function onsave(inst,data)
	data.loaded = true
	if inst.components.pickable.targettime then
		data.targettime = inst.components.pickable.targettime - GetTime()
	end
end

local function onload(inst,data)
	if data then
		if data.loaded then
			inst.loaded = true
		end
	end
end

local function onloadpostpass(inst,newents,data)
	if data then
		if data.targettime then
			inst:DoTaskInTime(0,function()
					inst.components.pickable.targettime = data.targettime
				end)
		end
	end
end ]]

local function setwet(inst)
    inst.components.pickable.paused = false
    if inst.components.pickable.canbepicked then
        inst:AddTag("pickable")
    end
    inst.wet = true
    inst.AnimState:ClearOverrideBuild("nettle_bulb_build")
    inst.AnimState:ClearOverrideBuild("nettle_budding_build")
    testForGrowth(inst)
end

local function setdry(inst)
    inst.wet = nil
    if inst.moist then
        inst.AnimState:ClearOverrideBuild("nettle_bulb_build")
        inst.AnimState:AddOverrideBuild("nettle_budding_build")
    else
        inst.AnimState:ClearOverrideBuild("nettle_budding_build")
        inst.AnimState:AddOverrideBuild("nettle_bulb_build")
    end
end

local function setmoist(inst)
    if inst.wet then
        inst.AnimState:ClearOverrideBuild("nettle_budding_build")
        inst.AnimState:ClearOverrideBuild("nettle_bulb_build")
    else
        inst.AnimState:ClearOverrideBuild("nettle_bulb_build")
        inst.AnimState:AddOverrideBuild("nettle_budding_build")
    end
    inst.moist = true
end

local function setnomoist(inst)
    inst.moist = false
    if inst.wet then
        inst.AnimState:ClearOverrideBuild("nettle_budding_build")
        inst.AnimState:ClearOverrideBuild("nettle_bulb_build")
    else
        inst.AnimState:ClearOverrideBuild("nettle_budding_build")
        inst.AnimState:AddOverrideBuild("nettle_bulb_build")
    end
end

local function checkcanbepicked(inst)
    if inst.wet then
        if inst.components.pickable.canbepicked then
            inst:AddTag("pickable")
        end
    else
        if inst:HasTag("pickable") then
            inst:RemoveTag("pickable")
        end
    end
end

local function updatemoiseture(inst)
    if inst.components.moisture:GetMoisture() >= inst.wetnessThreshold and not inst.wet then
        setwet(inst)
    elseif inst.components.moisture:GetMoisture() < inst.drynessThreshold and inst.wet then
        setdry(inst)
    end

    if inst.components.moisture:GetMoisture() > 0 and not inst.moist then
        setmoist(inst)
    elseif inst.components.moisture:GetMoisture() <= 0 and inst.moist then
        setnomoist(inst)
    end
end

local function onload_pl(inst,data)
    inst:DoTaskInTime(0,function ()
        updatemoiseture(inst)
        checkcanbepicked(inst)
    end)
end

local function canbepickedfn(inst)
	if inst.wet then
		return true
	end
end

local function makefn(stage)
	local function dig_up(inst, digger)
		if inst.components.pickable and inst.components.pickable:CanBePicked() then
			inst.components.lootdropper:SpawnLootPrefab("cutnettle")
		end
		local bush = inst.components.lootdropper:SpawnLootPrefab("dug_nettle")
		inst:Remove()
	end

	local function fn(Sim)
		local inst = CreateEntity()
		local trans = inst.entity:AddTransform()
		local anim = inst.entity:AddAnimState()
	    local sound = inst.entity:AddSoundEmitter()
		local minimap = inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		inst.MiniMapEntity:SetIcon("nettle.tex")
		inst.AnimState:SetBank("nettle")
		inst.AnimState:SetBuild("nettle")

	    anim:PlayAnimation("idle", true)
	    anim:SetTime(math.random()*2)

	    inst:AddTag("gustable")
	    inst:AddTag("nettle_plant")
	    inst:AddTag("plant")
        inst:AddTag("waterneeded")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

	    inst:AddComponent("pickable")
	    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

	    inst.components.pickable:SetUp("cutnettle", TUNING.NETTLE_REGROW_TIME)
		inst.components.pickable.canbepickedfn = canbepickedfn
		inst.components.pickable.onregenfn = onregenfn
		inst.components.pickable.onpickedfn = onpickedfn
	    inst.components.pickable.makeemptyfn = makeemptyfn
		inst.components.pickable.makebarrenfn = makebarrenfn
		inst.components.pickable.ontransplantfn = ontransplantfn
		--inst.components.pickable:Pause()
		inst.components.pickable.dontunpauseafterwinter = true

		inst.components.pickable.pickydirt = valid_tiles

		inst:DoTaskInTime(0,function() testForGrowth(inst) end)
		inst.testForGrowth = testForGrowth
		inst.growwithsprinkler = true

	    inst:AddComponent("inspectable")

		inst:AddComponent("lootdropper")
	    inst.components.inspectable.getstatus = getstatus

		inst:AddComponent("workable")
	    inst.components.workable:SetWorkAction(ACTIONS.DIG)
	    inst.components.workable:SetOnFinishCallback(dig_up)
	    inst.components.workable:SetWorkLeft(1)

		inst:AddComponent("moisture")

	    --inst:AddComponent("moisturelistener")
	    --inst.components.moisturelistener.wetnessThreshold = TUNING.NETTLE_MOISTURE_WET_THRESHOLD
		--inst.components.moisturelistener.drynessThreshold = TUNING.NETTLE_MOISTURE_DRY_THRESHOLD
	    --inst.components.moisturelistener.overrideinventoryonly = true

        inst.wetnessThreshold = TUNING.NETTLE_MOISTURE_WET_THRESHOLD
        inst.drynessThreshold = TUNING.NETTLE_MOISTURE_DRY_THRESHOLD

        inst:DoPeriodicTask(FRAMES * (math.random(3,6)),function ()
            updatemoiseture(inst)
            checkcanbepicked(inst)
        end)

	    --MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)

	    ---------------------
	    MakeMediumBurnable(inst)
	    MakeSmallPropagator(inst)
	    --inst.components.burnable:MakeDragonflyBait(1)

		MakeNoGrowInWinter(inst)

		inst.AnimState:AddOverrideBuild("nettle_bulb_build")

		--[[
		inst.OnLoadPostPass = onloadpostpass
		inst.OnSave = onsave
		inst.OnLoad = onload
		]]

        inst.OnLoad = onload_pl

		inst.AnimState:Hide("Layer 3")

	    return inst
	end

    return fn
end

return Prefab("nettle", makefn(0), assets, prefabs)

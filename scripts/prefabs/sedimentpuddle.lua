local assets =
{
	Asset("ANIM", "anim/gold_puddle.zip"),
    Asset("MINIMAP_IMAGE", "gold_puddle"),
	Asset("ANIM", "anim/water_ring_fx.zip"),

}

local prefabs =
{
	"gold_dust",
}

local SAFE_EDGE_RANGE = 7
local SAFE_PUDDLE_RANGE = 7

local function getanim(inst, state)
	local size = "big"

	if inst.stage == 1 then
		size = "small"
	elseif inst.stage == 2 then
		size = "med"
	end

	return size .."_" .. state
end

local function setstage0(inst, preanim)
--	print("SET STAGE 0")
	local anim = inst.AnimState

	inst.stage = 0
	inst.components.workable:SetWorkLeft(0)
	inst.components.workable:SetWorkable(false)
	inst.components.ripplespawner:SetRange(0)

	inst:AddTag("NOCLICK")

	inst.MiniMapEntity:SetEnabled(false)

	if preanim then
		anim:PlayAnimation( preanim )
		--anim:PushAnimation( getanim(inst, "idle"), true )
	else
		anim:PlayAnimation( getanim(inst, "idle"), true )
		inst:Hide()
	end
end

local function setstage1(inst, preanim)
--	print("SET STAGE 1")
	local anim = inst.AnimState
	inst:Show()
	inst.stage = 1
	inst.components.workable:SetWorkLeft(1)
	inst.components.ripplespawner:SetRange(1.6)

	inst:RemoveTag("NOCLICK")

	inst.MiniMapEntity:SetEnabled(true)

	if preanim then
		anim:PlayAnimation( preanim )
		anim:PushAnimation( getanim(inst, "idle"), true )
	else
		anim:PlayAnimation( getanim(inst, "idle"), true )
	end
end

local function setstage2(inst, preanim)
--	print("SET STAGE 2")
	local anim = inst.AnimState
	inst:Show()
	inst.stage = 2
	inst.components.workable:SetWorkLeft(2)
	inst.components.ripplespawner:SetRange(2.6)

	inst:RemoveTag("NOCLICK")

	inst.MiniMapEntity:SetEnabled(true)

	if preanim then
		anim:PlayAnimation( preanim )
		anim:PushAnimation( getanim(inst, "idle"), true )
	else
		anim:PlayAnimation( getanim(inst, "idle"), true )
	end
end

local function setstage3(inst, preanim)
--	print("SET STAGE 3")
	local anim = inst.AnimState
	inst:Show()
	inst.stage = 3
	inst.components.workable:SetWorkLeft(3)
	inst.components.ripplespawner:SetRange(3.5)

	inst:RemoveTag("NOCLICK")

	inst.MiniMapEntity:SetEnabled(true)

	if preanim then
		anim:PlayAnimation( preanim )
		anim:PushAnimation( getanim(inst, "idle"), true )
	else
		anim:PlayAnimation( getanim(inst, "idle"), true )
	end
end

local function grow(inst)
	local anim = inst.AnimState
	if inst.stage == 0 then
		inst.watercollected = 0
		setstage1(inst, "appear")
	elseif inst.stage == 1 then
		setstage2(inst, "small_to_med")
	elseif inst.stage == 2 then
		setstage3(inst, "med_to_big")
	end
end

local function shrink(inst)
	local anim = inst.AnimState
	if inst.stage == 3 then
		setstage2(inst, "big_to_med")
	elseif inst.stage == 2 then
		setstage1(inst, "med_to_small")
	elseif inst.stage == 1 then
		inst.watercollected = 0
		setstage0(inst, "disappear")
	end
end

local function initialsetup(inst)
	if not inst.stage then
		local stage = math.random(0,3)
		if stage == 0 then
			setstage0(inst)
		elseif stage == 1 then
			setstage1(inst)
		elseif stage == 2 then
			setstage2(inst)
		elseif stage == 3 then
			setstage3(inst)
		end
	end
end

local function dogrow(inst)
	if not inst.pause then
		grow(inst)
	end
end

local function getnewwaterlimit(inst)
	return 36 + (math.random() * 8)  -- 36 * 5 = 180 seconds to go up one level .. 3 minutes of rain.
end

local function collectrain(inst)
	if not inst.pause then
		inst.watercollected = inst.watercollected + 1
		if inst.watercollected > inst.waterlimit then
			inst.watercollected = 0
			grow(inst)
			inst.waterlimit = getnewwaterlimit(inst)
		end
	end
end

local function generatetask(inst)
	--local time = TUNING.SEG_TIME*6 + (TUNING.SEG_TIME * (math.random()*4))
	inst.growtask = inst:DoPeriodicTask(5, function() collectrain(inst) end )
end

local function OnSave(inst,data)
    local refs = {}
 	data.stage = inst.stage
 	data.growing = inst.growing
 	data.watercollected = inst.watercollected
 	data.waterlimit = inst.waterlimit

 	data.spawned = inst.spawned
 	data.rot = inst.Transform:GetRotation()
--[[
    if refs and #refs >0 then
        return refs
    end
    ]]
end

local function OnLoad(inst,data)
	if data then
	   	inst.stage = data.stage
		if inst.stage == 0 then
			setstage0(inst)
		elseif inst.stage == 1 then
			setstage1(inst)
		elseif inst.stage == 2 then
			setstage2(inst)
		elseif inst.stage == 3 then
			setstage3(inst)
		end
		inst.watercollected = data.watercollected
		inst.waterlimit = data.waterlimit

	   	inst.growing = data.growing
	   	if inst.growing then
	   		generatetask(inst)
	   	end

	   	if data.spawned then
	   		inst.spawned = true
	   	end

	   	if data.rot then
	   		inst.Transform:SetRotation(data.rot)
	   	end
   	end
end

local function startgrow(inst)
	if (inst.stage and inst.stage > 0) or math.random()<0.2 then
		inst.growing = true
		generatetask(inst)
	end
end

local function stopgrow(inst)
	inst.growing = false
	if inst.growtask then
		inst.growtask:Cancel()
		inst.growtask = nil
	end
end


local function reposition(inst)

	local ground = TheWorld

	local pt = Vector3(inst.Transform:GetWorldPosition())
	local tests = {}

	for i=1,8 do
		local angle = (i-1) * PI/4
		local offset = Vector3(SAFE_EDGE_RANGE * math.cos( angle ), 0, -SAFE_EDGE_RANGE * math.sin( angle ))
		local tile = ground.Map:GetTileAtPoint(pt.x+offset.x, 0, pt.z+offset.z)
		table.insert(tests,tile)
	end

	local offsets = {}
	for i,tile in ipairs(tests)do
		if tile ~= GROUND.PAINTED then
			local angle = ((i -1)*PI/4) - PI
			local offset = Vector3(SAFE_EDGE_RANGE * math.cos( angle ), 0, -SAFE_EDGE_RANGE * math.sin( angle ))
			table.insert(offsets,offset)
		end
	end

	if #offsets > 0 then
		local offset = Vector3(0,0,0)
		for i,noffset in ipairs(offsets) do
			offset = offset + noffset
		end
		offset.x = offset.x / #offsets
		offset.z = offset.z / #offsets

		pt.x = pt.x +offset.x
		pt.y = pt.y +offset.y
		pt.z = pt.z +offset.z

		inst.Transform:SetPosition(pt.x,pt.y,pt.z)
	end

	inst.spawned = true

	local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, SAFE_PUDDLE_RANGE, {"sedimentpuddle"})
 	if #ents>1 then
		print("Overlapping other puddle. REMOVING")
		inst:Remove()
 	end
end

local function commonfn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("sedimentpuddle")
    inst:AddTag("NOBLOCK")
    inst:AddTag("OnFloor")

    anim:SetBuild("gold_puddle")
    anim:SetBank("gold_puddle")
    anim:PlayAnimation( "big_idle", true)
	anim:SetOrientation( ANIM_ORIENTATION.OnGround )
	anim:SetLayer( LAYER_BACKGROUND )
	anim:SetSortOrder( 2 )

	inst.Transform:SetRotation(math.random()*360)
	inst.watercollected = 0
	inst.waterlimit  =  getnewwaterlimit(inst)

	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "gold_puddle.tex" )


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.shrink = shrink
	inst.grow = grow

	inst:AddComponent("lootdropper")

	inst:AddComponent("ripplespawner")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.PAN)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnWorkCallback(
		function(inst, worker, workleft)
			inst.components.lootdropper:SpawnLootPrefab("gold_dust")
			shrink(inst)
		end)

    inst:AddComponent("inspectable")
    inst.no_wet_prefix = true

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0,function() initialsetup(inst) end)

	inst:WatchWorldState("startrain", function() startgrow(inst) end, TheWorld)
	inst:WatchWorldState("stoprain", function()  stopgrow(inst) end, TheWorld)

	inst:ListenForEvent("animover", function(inst, data)
		if anim:IsCurrentAnimation("disappear") then
			inst:Hide()
		end
	end)

	inst:DoTaskInTime(0,function()
			if not inst.spawned then
				reposition(inst)
			end
		end)

	--inst:ListenForEvent("startfog", function() inst.pause = true end, ThePlayer)
	--inst:ListenForEvent("stopfog", function() inst.pause = false end, ThePlayer)

	return inst
end

local function makeripple(speed)

	local function ripplefn()
		local inst = CreateEntity()
		local trans = inst.entity:AddTransform()
		local anim = inst.entity:AddAnimState()
	    inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

	    anim:SetBuild("water_ring_fx")
	    anim:SetBank("water_ring_fx")
	    anim:PlayAnimation( speed )
		anim:SetOrientation( ANIM_ORIENTATION.OnGround )
		anim:SetLayer( LAYER_BACKGROUND )
		anim:SetSortOrder( 3 )

		inst:AddTag("NOBLOCK")

		anim:SetMultColour(1, 1, 1, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

		inst:ListenForEvent("animover", inst.Remove)
		inst:ListenForEvent("entitysleep", inst.Remove)

		return inst
	end

	return ripplefn
end

return Prefab("sedimentpuddle", commonfn, assets, prefabs),
	   Prefab("puddle_ripple_fast_fx", makeripple("fast"), assets, prefabs),
	   Prefab("puddle_ripple_slow_fx", makeripple("slow"), assets, prefabs)

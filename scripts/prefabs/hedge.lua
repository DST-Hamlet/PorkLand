require "prefabutil"

local anims =
{
    { threshold = 0, anim = "broken" },
    { threshold = 0.4, anim = "onequarter" },
    { threshold = 0.5, anim = "half" },
    { threshold = 0.99, anim = "threequarter" },
    { threshold = 1, anim = { "fullA", "fullB", "fullC" } },
}

local function resolveanimtoplay(inst, percent)
    for i, v in ipairs(anims) do
        if percent <= v.threshold then
            if type(v.anim) == "table" then
                -- get a stable animation, by basing it on world position
                local x, y, z = inst.Transform:GetWorldPosition()
                local x = math.floor(x)
                local z = math.floor(z)
                local q1 = #v.anim + 1
                local q2 = #v.anim + 4
                local t = ( ((x%q1)*(x+3)%q2) + ((z%q1)*(z+3)%q2) )% #v.anim + 1
                return v.anim[t]
            else
                return v.anim
            end
        end
    end
end

-- NOTES(DiogoW): Things that add walls to the path finder appear with a wrong visual rotation when
-- entering/exiting interiors. I have no idea why.
local function FixUpRotation(inst)
    inst.Transform:SetRotation(inst.Transform:GetRotation())
end

function MakeHedgeType(data)
	local assets =
	{
		Asset("ANIM", "anim/hedge.zip"),
		Asset("ANIM", "anim/hedge"..data.hedgetype.."_build.zip"),
	}

	local prefabs =
	{
		"collapse_small",
	}

	local function quantizeposition(pt)
		local retval = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
		return retval
	end 

	local function ondeploywall(inst, pt, deployer)
	
		local wall = SpawnPrefab(data.name) 
		if wall ~= nil then
            local x = math.floor(pt.x) + .5
            local z = math.floor(pt.z) + .5
            wall.Physics:SetCollides(false)
            wall.Physics:Teleport(x, 0, z)
            wall.Physics:SetCollides(true)
            inst.components.stackable:Get():Remove()

            if data.buildsound ~= nil then
                wall.SoundEmitter:PlaySound(data.buildsound)
            end
        end		
	end

	local function onhacked(inst, worker)
	    if inst:HasTag("fire") and inst.components.burnable then
	        inst.components.burnable:Extinguish()
	    end

	    inst.reconstruction_project_spawn_state = {
    	    bank = "hedge",
	        build = "hedge"..data.hedgetype.."_build",
        	anim = "growth0_45s",
	    }	
		if not inst.components.fixable then
			inst.components.lootdropper:SpawnLootPrefab("clippings")
			inst.components.lootdropper:SpawnLootPrefab("clippings")
	    end		
		
		local x, y, z = inst.Transform:GetWorldPosition()
        for i=1,math.random(5,10) do
        --    inst:DoTaskInTime(math.random()*0.5,function()                
                local fx = SpawnPrefab("robot_leaf_fx")
                fx.Transform:SetPosition(x + (math.random()*2) -1 ,y+math.random()*0.5,z + (math.random()*2) -1)
                if math.random() < 0.5 then
                	fx.Transform:SetScale(-1,1,-1)
                end
          --  end)
        end
		--sadorldPosition())

		inst:Remove()
	end

	--[[local function ongusthammerfn(inst)
	    --onhammered(inst, nil)
	    inst.components.health:DoDelta(-data.windblown_damage, false, "wind")
	end

	local function test_wall(inst, pt)
		local map = GetWorld().Map
		local tiletype = GetGroundTypeAtPosition(pt)
		local ground_OK = tiletype ~= GROUND.IMPASSABLE and not map:IsWater(tiletype) and IsPointInInteriorBounds(pt, 1)
		
		if ground_OK then
			local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 2, nil, {"NOBLOCK", "player", "FX", "INLIMBO", "DECOR"}) -- or we could include a flag to the search?

			for k, v in pairs(ents) do
				if v ~= inst and v:IsValid() and v.entity:IsVisible() and not v.components.placer and v.parent == nil then
					local dsq = distsq( Vector3(v.Transform:GetWorldPosition()), pt)
					if v:HasTag("wall") then
						if dsq < .1 then return false end
					else
						if  dsq< 1 then return false end
					end
				end
			end

			local playerPos = GetPlayer():GetPosition()
			local xDiff = playerPos.x - pt.x 
			local zDiff = playerPos.z - pt.z 
			local dsq = xDiff * xDiff + zDiff * zDiff
			if dsq < .5 then 
				return false 
			end 

			return true

		end
		return false
		
	end]]

	local function OnIsPathFindingDirty(inst)
		if inst._ispathfinding:value() then
			if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
				inst._pfpos = inst:GetPosition()
				TheWorld.Pathfinder:AddWall(inst._pfpos:Get())
			end
		elseif inst._pfpos ~= nil then
			TheWorld.Pathfinder:RemoveWall(inst._pfpos:Get())
			inst._pfpos = nil
		end
	end

	local function InitializePathFinding(inst)
		inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
		OnIsPathFindingDirty(inst)
	end

	local function makeobstacle(inst)
		inst.Physics:SetActive(true)
		inst._ispathfinding:set(true)
	end

	local function clearobstacle(inst)
		inst.Physics:SetActive(false)
		inst._ispathfinding:set(false)
	end

	--[[local function makeobstacle(inst)
	
		inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)	
	    inst.Physics:ClearCollisionMask()
		--inst.Physics:CollidesWith(GetWorldCollision())
		inst.Physics:SetMass(0)
		inst.Physics:CollidesWith(COLLISION.ITEMS)
		inst.Physics:CollidesWith(COLLISION.CHARACTERS)
		inst.Physics:CollidesWith(COLLISION.WAVES)
		inst.Physics:CollidesWith(COLLISION.INTWALL)
		inst.Physics:SetActive(true)
	    local ground = GetWorld()
	    if ground then
	    	local pt = Point(inst.Transform:GetWorldPosition())
			--print("    at: ", pt)
	    	ground.Pathfinder:AddWall(pt.x, pt.y, pt.z)
	    end
	end
	
	local function clearobstacle(inst)
		-- Alia: 
		-- Since we are removing the wall anytway we may as well not bother setting the physics    
	    -- We had better wait for the callback to complete before trying to remove ourselves
	    inst:DoTaskInTime(2*FRAMES, function()
			if inst:IsValid() then
				inst.Physics:SetActive(false)
			end
		end)
	
	    local ground = GetWorld()
	    if ground then
	    	local pt = Point(inst.Transform:GetWorldPosition())
	    	ground.Pathfinder:RemoveWall(pt.x, pt.y, pt.z)
	    end
	end

	local function onhealthchange(inst, old_percent, new_percent)
		if old_percent <= 0 and new_percent > 0 then makeobstacle(inst) end
		if old_percent > 0 and new_percent <= 0 then clearobstacle(inst) end

		local anim_to_play = resolveanimtoplay(inst, new_percent)
		if new_percent > 0 then
			inst.AnimState:PlayAnimation(anim_to_play.."_hit")		
			inst.AnimState:PushAnimation(anim_to_play, false)		
		else
			inst.AnimState:PlayAnimation(anim_to_play)		
		end
	end]]
	
	local function itemfn(Sim)

		local inst = CreateEntity()
		
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
        inst.entity:AddNetwork()
		
		MakeInventoryPhysics(inst)
		
		inst:AddTag("wallbuilder")
	    
		inst.AnimState:SetBank("hedge")
		inst.AnimState:SetBuild("hedge"..data.hedgetype.."_build")
		inst.AnimState:PlayAnimation("idle")

		MakeInventoryFloatable(inst)
		
		inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")	    
		
		if data.flammable then
			MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
			MakeSmallPropagator(inst)
			
			inst:AddComponent("fuel")
			inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL
		end
		
		inst:AddComponent("deployable")
		inst.components.deployable.ondeploy = ondeploywall
        inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

		--inst.components.deployable.test = test_wall
		--inst.components.deployable.min_spacing = 0
		--inst.components.deployable.placer = data.name.."_placer"
		--inst.components.deployable:SetQuantizeFunction(quantizeposition)
		--inst.components.deployable.deploydistance = 1.5
		
		return inst
	end

	local function onhit(inst)

	 	local fx = SpawnPrefab("robot_leaf_fx")
	    local x, y, z= inst.Transform:GetWorldPosition()
	    fx.Transform:SetPosition(x,y + math.random()*0.5,z)
				
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")		
	end

	local function onrepaired(inst)
		inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_straw")		
		makeobstacle(inst)
	end

	local function ongrowth(inst)
		inst.AnimState:PlayAnimation("growth2", false)		
		inst.components.shearable.canshaveable = true
	end

	local function onshear(inst)
		inst.AnimState:PlayAnimation("growth1", false)		
		inst.components.shearable.canshaveable = nil
		inst.setAgeTask(inst)
	end
	
	local function canshave(inst, shaver, shaving_implement)
		return inst:HasTag("SHEAR_workable")
	end
	

	local function onsave(inst, data)		
	    if inst.task then
	        data.timeleft = inst:TimeRemainingInTask(inst.taskinfo)
	    end
	    if inst.components.shearable:CanShear() then
	    	data.canshear = true
	    end
	end

	local function onload(inst, data)
		-- This is run everytime the hedges are loaded into the world, including the fisrt. But the result is overridden by the save data afterwards. 
		if math.random() < 0.05 or 
			(data and data.canshear) then
			print("LOAD HEDGE", data.canshear)
			ongrowth(inst)
		else
			onshear(inst)
		end
		if data then
			if data.timeleft then
				inst.setAgeTask(inst, data.timeleft)
			end
			
			if data.gridnudge then
				local function normalize(coord)

					local temp = coord%0.5
					coord = coord + 0.5 - temp

					if  coord%1 == 0 then
						coord = coord -0.5
					end

					return coord
				end

				local pt = Vector3(inst.Transform:GetWorldPosition())
				pt.x = normalize(pt.x)
				pt.z = normalize(pt.z)
				inst.Transform:SetPosition(pt.x,pt.y,pt.z)
			end
		end
		makeobstacle(inst)
	end

	local function onremoveentity(inst)
		inst._ispathfinding:set_local(false)
		OnIsPathFindingDirty(inst)
		--clearobstacle(inst)
	end

	local function setAgeTask(inst, time)
		if inst.task then 
			inst.taskinfo = nil
			inst.task:Cancel()
			inst.task = nil
		end
		if not time then 
			time = TUNING.TOTAL_DAY_TIME / 2 + (math.random() * TUNING.TOTAL_DAY_TIME)
		end
		inst.task, inst.taskinfo = inst:ResumeTask(time, function(inst)
			if math.random() < 0.03 then ongrowth(inst)
			else inst.setAgeTask(inst)
			end
		end, inst)  
	end

	local function getstatus(inst)
	    if inst.components.shearable:CanShear() then
	      	return "SHAVEABLE"
	    end	    
	end

	local function fn(Sim)
		local inst = CreateEntity()
		
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
		
		inst.Transform:SetEightFaced()
		
		MakeObstaclePhysics(inst, .5)
        inst.Physics:SetDontRemoveOnSleep(true)
		
		inst:AddTag("wall")		
		inst:AddTag("grass")
		inst:AddTag("structure")

		inst.AnimState:SetBank("hedge")
		inst.AnimState:SetBuild("hedge"..data.hedgetype.."_build")
	    inst.AnimState:PlayAnimation("growth1", false)
	    
		MakeSnowCoveredPristine(inst)
		
		inst._pfpos = nil
		inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
        makeobstacle(inst)
		
		inst:DoTaskInTime(0, InitializePathFinding)
		
		inst.OnRemoveEntity = onremoveentity
		
		inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
		
		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = getstatus
		inst:AddComponent("lootdropper")

		inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_straw")		
		
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(3)
		inst.components.workable:SetOnFinishCallback(onhacked)
		inst.components.workable:SetOnWorkCallback(onhit) 
		
        inst:AddComponent("fixable")
        inst.components.fixable:AddRecinstructionStageData("broken","hedge","hedge"..data.hedgetype.."_build")
        inst.components.fixable:SetPrefabName("hedge")
        inst.components.fixable.reconstructedanims = {play ="place", push = "growth1"}
        inst.components.fixable.reconstructionprefab = data.name

        --inst:ListenForEvent("entitywake", FixUpRotation)
	    
		inst:SetPrefabNameOverride("hedge")

		--inst:AddComponent("gridnudger")

		inst.setAgeTask = setAgeTask

		MakeMediumBurnable(inst, nil, nil, true)
        MakeMediumPropagator(inst)
		MakeHauntableWork(inst)
        inst:ListenForEvent("burntup", inst.Remove)

		inst:AddComponent("shearable")
		inst.components.shearable:SetProduct("clippings", 2)
		inst.components.shearable:SetOnShearFn(onshear)
		
		inst:AddComponent("shaveable")
		inst.components.shaveable:SetPrize("clippings", 1)
        inst.components.shaveable.can_shave_test = canshave
        inst.components.shaveable.on_shaved = onshear
		

		inst:DoTaskInTime(0.5,function() 
			if not inst.components.shearable:CanShear() and not inst.task then
				setAgeTask(inst)
			end
		end)

	    inst.returntointeriorscene = makeobstacle
    	inst.removefrominteriorscene = clearobstacle
		
		inst.OnSave = onsave
	    inst.OnLoad = onload

		return inst
	end


	local function fn_repaired(Sim)
		local inst = fn(Sim)
		inst.components.health:SetPercent(1)
		inst:SetPrefabName("wall_"..data.name)
		return inst
	end

	return Prefab(data.name, fn, assets, prefabs),	 	 
		   Prefab(data.name.."_item", itemfn, assets, {data.name, data.name.."_item_placer", "collapse_small"}),
		   MakePlacer(data.name.."_item_placer", "hedge", "hedge"..data.hedgetype, "growth1", false, false, true, nil, nil, "eight") 
	end


local hedgeprefabs = {}
local hedgedata = {
			{name = "hedge_block", hedgetype = 1, loot = "cutgrass", maxloots = 2, maxhealth=TUNING.HAYWALL_HEALTH, flammable = true, buildsound="dontstarve/common/place_structure_straw"},
			{name = "hedge_cone", hedgetype = 2, loot = "cutgrass", maxloots = 2, maxhealth=TUNING.HAYWALL_HEALTH, flammable = true, buildsound="dontstarve/common/place_structure_straw",},
			{name = "hedge_layered", hedgetype = 3, loot = "cutgrass", maxloots = 2, maxhealth=TUNING.HAYWALL_HEALTH, flammable = true, buildsound="dontstarve/common/place_structure_straw",},
		}

for k,v in pairs(hedgedata) do
	local hedge, item, placer = MakeHedgeType(v)
	table.insert(hedgeprefabs, hedge)
	table.insert(hedgeprefabs, item)
	table.insert(hedgeprefabs, placer)
end

return unpack(hedgeprefabs) 
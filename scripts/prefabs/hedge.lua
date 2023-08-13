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
		Asset("INV_IMAGE", "hedge_block_item"),
		Asset("INV_IMAGE", "hedge_cone_item"),		
		Asset("INV_IMAGE", "hedge_layered_item"),		
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
		--inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
		local wall = SpawnPrefab(data.name) 
		if wall then 
			pt = quantizeposition(pt)
			wall.Physics:SetCollides(false)
			wall.Physics:Teleport(pt.x, pt.y, pt.z) 
			wall.Physics:SetCollides(true)
			inst.components.stackable:Get():Remove()

		    local ground = GetWorld()
		    if ground then
		    	ground.Pathfinder:AddWall(pt.x, pt.y, pt.z)
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

	local function ongusthammerfn(inst)
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
		
	end

	local function makeobstacle(inst)
		-- print('makeobstacle walls.lua')
	
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
	end
	
	local function itemfn(Sim)

		local inst = CreateEntity()
		inst:AddTag("wallbuilder")
		
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		MakeInventoryPhysics(inst)
	    
		inst.AnimState:SetBank("hedge")
		inst.AnimState:SetBuild("hedge"..data.hedgetype.."_build")
		inst.AnimState:PlayAnimation("idle")

		
		MakeInventoryFloatable(inst, "idle_water", "idle")


		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")	    
		
		if data.flammable then
			MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
			MakeSmallPropagator(inst)
			
			inst:AddComponent("fuel")
			inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

			inst:AddComponent("appeasement")
    		inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL

			inst.components.burnable:MakeDragonflyBait(3)
		end
		
		inst:AddComponent("deployable")
		inst.components.deployable.ondeploy = ondeploywall
		inst.components.deployable.test = test_wall
		inst.components.deployable.min_spacing = 0
		inst.components.deployable.placer = data.name.."_placer"
		inst.components.deployable:SetQuantizeFunction(quantizeposition)
		inst.components.deployable.deploydistance = 1.5
		
		return inst
	end

	local function onhit(inst)

	 	local fx = SpawnPrefab("robot_leaf_fx")
	    local x, y, z= inst.Transform:GetWorldPosition()
	    fx.Transform:SetPosition(x,y + math.random()*0.5,z)
				
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")		
	end

	local function onrepaired(inst)
		if data.buildsound then
			inst.SoundEmitter:PlaySound(data.buildsound)		
		end
		makeobstacle(inst)
	end

	local function age(inst)
		inst.AnimState:PlayAnimation("growth2", false)		
		inst.shaveable = true
	end

	local function unage(inst)
		inst.AnimState:PlayAnimation("growth1", false)		
		inst.shaveable = nil
		inst.setAgeTask(inst)
	end

	local function shave(inst, shaver)
		if inst.shaveable then			
			unage(inst)
			shaver.components.inventory:GiveItem(  SpawnPrefab("clippings"), nil, Vector3(TheSim:GetScreenPos(inst.Transform:GetWorldPosition())))
		end
	end

	local function onshear(inst, shearer)
		unage(inst)
	end

	local function canshear(inst)
		return inst.shaveable
	end

	local function onsave(inst, data)		
	    if inst.task then
	        data.timeleft = inst:TimeRemainingInTask(inst.taskinfo)
	    end
	    if inst.shaveable then
	    	data.shaveable = true
	    end
	end

	local function onload(inst, data)
		-- This is run everytime the hedges are loaded into the world, including the fisrt. But the result is overridden by the save data afterwards. 
		if math.random() < 0.05 then
			age(inst)
		else
			inst.setAgeTask(inst) 
		end

		if data then
			if data.shaveable then
				age(inst)
			else
				unage(inst)
			end
			if data.timeleft then
			    inst.setAgeTask(inst, data.timeleft)
			end  	
		end
		
		makeobstacle(inst)
	end

	local function onremoveentity(inst)
		clearobstacle(inst)
	end

	local function testage(inst)
		if math.random() < 0.03 then
			age(inst)
		else
			inst.setAgeTask(inst)
		end
	end

	local function setAgeTask(inst, time)
		if inst.task then inst.taskinfo = nil inst.task:Cancel() inst.task = nil  end
		if not time then 
			time = TUNING.TOTAL_DAY_TIME/2 + (math.random()* TUNING.TOTAL_DAY_TIME)
		end
		inst.task, inst.taskinfo = inst:ResumeTask( time, function() testage(inst) end)  
	end

	local function getstatus(inst)
	    if inst.shaveable then
	      	return "SHAVEABLE"
	    end	    
	end

	local function fn(Sim)
		local inst = CreateEntity()
		local trans = inst.entity:AddTransform()
		local anim = inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		trans:SetEightFaced()
		--trans:SetScale(1.3,1.3,1.3)
		inst:AddTag("wall")
		inst:AddTag("structure")
		MakeObstaclePhysics(inst, .5)    
        inst.Physics:SetDontRemoveOnSleep(true)

		anim:SetBank("hedge")
		anim:SetBuild("hedge"..data.hedgetype.."_build")
	    anim:PlayAnimation("growth1", false)
	    
		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = getstatus
		inst:AddComponent("lootdropper")
		
		for k,v in ipairs(data.tags) do
		    inst:AddTag(v)
		end

		if data.buildsound then
			inst.SoundEmitter:PlaySound(data.buildsound)		
		end
		
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(3)
		inst.components.workable:SetOnFinishCallback(onhacked)
		inst.components.workable:SetOnWorkCallback(onhit) 
		

        inst:AddComponent("fixable")
        inst.components.fixable:AddRecinstructionStageData("broken","hedge","hedge"..data.hedgetype.."_build")
        inst.components.fixable:SetPrefabName("hedge")
        inst.components.fixable.reconstructedanims ={play ="place", push = "growth1" }
        inst.components.fixable.reconstructionprefab = data.name

        inst:ListenForEvent("entitywake", FixUpRotation)

		inst.OnSave = onsave
	    inst.OnLoad = onload
	    inst.OnRemoveEntity = onremoveentity
		
		inst:SetPrefabNameOverride("hedge")

		inst:AddComponent("gridnudger")

		MakeSnowCovered(inst)

		inst.shave = shave
		inst.setAgeTask = setAgeTask

		MakeMediumBurnable(inst, nil, nil, true)
        MakeMediumPropagator(inst)
        inst:ListenForEvent("burntup", inst.Remove)

		inst:AddComponent("shearable")
		inst.components.shearable:SetProduct("clippings", 2)

		inst.onshear = onshear
		inst.canshear = canshear

		inst:DoTaskInTime(0, makeobstacle)

		inst:DoTaskInTime(0.5,function() 
			if not inst.shaveable and not inst.task then
				setAgeTask(inst)
			end
		end)

	    inst.returntointeriorscene = makeobstacle
    	inst.removefrominteriorscene = clearobstacle

		return inst
	end


	local function fn_repaired(Sim)
		local inst = fn(Sim)
		inst.components.health:SetPercent(1)
		inst:SetPrefabName("wall_"..data.name)
		return inst
	end

	return Prefab( "common/"..data.name, fn, assets, prefabs),	 	 
		   Prefab( "common/"..data.name.."_item", itemfn, assets, {data.name, data.name.."_placer", "collapse_small"}),
		   MakePlacer("common/"..data.name.."_placer", "hedge", "hedge"..data.hedgetype.."_build", "growth1", false, false, true, nil, nil, nil, "eight") 
	end


local hedgeprefabs = {}
local hedgedata = {
			{name = "hedge_block", hedgetype = 1, tags={"grass"}, loot = "cutgrass", maxloots = 2, maxhealth=TUNING.HAYWALL_HEALTH, buildsound="dontstarve/common/place_structure_straw", destroysound="dontstarve/common/destroy_straw"},
			{name = "hedge_cone", hedgetype = 2, tags={"grass"}, loot = "cutgrass", maxloots = 2, maxhealth=TUNING.HAYWALL_HEALTH, flammable = true, buildsound="dontstarve/common/place_structure_straw", destroysound="dontstarve/common/destroy_straw", windblown_speed=TUNING.WALLWOOD_WINDBLOWN_SPEED, windblown_fall_chance=TUNING.WALLWOOD_WINDBLOWN_DAMAGE_CHANCE, windblown_damage=TUNING.WALLWOOD_WINDBLOWN_DAMAGE},
			{name = "hedge_layered", hedgetype = 3, tags={"grass"}, loot = "cutgrass", maxloots = 2, maxhealth=TUNING.HAYWALL_HEALTH, flammable = true, buildsound="dontstarve/common/place_structure_straw", destroysound="dontstarve/common/destroy_straw", windblown_speed=TUNING.WALLHAY_WINDBLOWN_SPEED, windblown_fall_chance=TUNING.WALLHAY_WINDBLOWN_DAMAGE_CHANCE, windblown_damage=TUNING.WALLHAY_WINDBLOWN_DAMAGE},
		}

for k,v in pairs(hedgedata) do
	local hedge, item, placer = MakeHedgeType(v)
	table.insert(hedgeprefabs, hedge)
	table.insert(hedgeprefabs, item)
	table.insert(hedgeprefabs, placer)
end

return unpack(hedgeprefabs) 
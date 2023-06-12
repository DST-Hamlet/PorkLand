
local basalt_assets =
{
	Asset("ANIM", "anim/rock_basalt.zip"),
	Asset("MINIMAP_IMAGE", "rock"),
}

local antqueen_throne_assets = 
{
	Asset("ANIM", "anim/throne.zip"),
}

local ruins_assets =
{
	Asset("ANIM", "anim/ruins_artichoke.zip"),
	Asset("ANIM", "anim/ruins_giant_head.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_pig.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_ant.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_idol.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_plaque.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_mushroom.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_idol_blue.zip"),

	
	Asset("MINIMAP_IMAGE", "statue_pig_ruins_mushroom"),
	Asset("MINIMAP_IMAGE", "statue_pig_ruins_idol_blue"),

	Asset("MINIMAP_IMAGE", "ruins_giant_head"),
	Asset("MINIMAP_IMAGE", "ruins_artichoke"),

	Asset("MINIMAP_IMAGE", "statue_pig_ruins_ant"),
	Asset("MINIMAP_IMAGE", "statue_pig_ruins_pig"),	

	Asset("MINIMAP_IMAGE", "statue_pig_ruins_idol"),
	Asset("MINIMAP_IMAGE", "statue_pig_ruins_plaque"),	
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "relic_3",
    "pigghost",
}    

SetSharedLootTable( 'ruins_artichoke',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'nitre',  0.25},
    {'flint',  0.60},
    {'flint',  0.60},
    {'gold_dust',  0.60},
})

SetSharedLootTable( 'ruins_pig',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'flint',  0.60},     
    {'gold_dust',  0.60},
    {'pigghost', 0.2},
})

SetSharedLootTable( 'ruins_gianthead',
{
	{'gold_dust', 0.2},
	{'gold_dust', 0.2},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'nitre',  0.25},
    {'flint',  0.60},
    {'flint',  0.60},
    {'pigghost', 0.2},
})

SetSharedLootTable( 'antqueen_throne',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    
    {'flint',  1.0},
    {'flint',  1.0},
    {'flint',  0.8},
    {'flint',  0.8},
    {'flint',  0.8},
    {'flint',  0.8},

    {'nitre',  0.8},
    {'nitre',  0.8},
    {'nitre',  0.8},
    {'nitre',  0.8},

    {'gold_dust', 0.6},
    {'gold_dust', 0.6},

    {'gold_nugget', 1.0},
	{'gold_nugget', 1.0},
	{'gold_nugget', 0.3},
	{'gold_nugget', 0.3},

    {'bluegem', 0.5},
    {'bluegem', 0.5},
})

SetSharedLootTable( 'basalt',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  0.50},
    {'flint',  1.00},
    {'flint',  0.30},
})

local function triggerdarts(inst)
	
    print("TRIGGER DARTS!")
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, {"dartthrower"}, {"INTERIOR_LIMBO"})
    for i, ent in ipairs(ents) do
    	if ent.components.autodartthrower then
    		ent.components.autodartthrower:TurnOn()
    	elseif ent.shoot then        	
            ent.shoot(ent)
        end
    end 
end
local function setdislodged(inst)
	inst.dislodged = true
	inst.AnimState:PlayAnimation("extract_success")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_EXTRACTED"])	
end

local function ondislodged(inst)
	if inst:HasTag("trggerdarttraps") then
		triggerdarts(inst)
	end
	setdislodged(inst)
end

local function onsave(inst,data)
	if inst:HasTag("trggerdarttraps") then
		data.trggerdarttraps = true
	end
	if inst.dislodged then
		data.dislodged = true
	end
end
local function onload(inst, data)
	if data then
		if data.trggerdarttraps then
			inst:AddTag("trggerdarttraps")
		end
		if data.dislodged then
			setdislodged(inst)	
			inst.components.dislodgeable:SetDislodged()
		end
	end
end

local function baserock_fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeObstaclePhysics(inst, 1)
	
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "rock.tex")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper") 
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
	
	-- inst.entity:SetPristine()

	-- if not TheWorld.ismastersim then
		-- return inst
	-- end
	
	inst.components.workable:SetOnWorkCallback(
		function(inst, worker, workleft)

			local pt = Point(inst.Transform:GetWorldPosition())
			if workleft <= 0 then
				if inst:HasTag("trggerdarttraps") then
					triggerdarts(inst)
				end

				inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				inst.components.lootdropper:DropLoot(pt)
				--[[
				if inst:HasTag("mystery") and inst.components.mystery.investigated then
					inst.components.lootdropper:SpawnLootPrefab(inst.components.mystery.reward)
					inst:RemoveTag("mystery")
				end
				]]
				inst:Remove()
			else
				if workleft < TUNING.ROCKS_MINE*(1/3) then
					inst.AnimState:PlayAnimation("low")
				elseif workleft < TUNING.ROCKS_MINE*(2/3) then
					inst.AnimState:PlayAnimation("med")
				else
					if not inst.components.dislodgeable or inst.components.dislodgeable:CanBeDislodged() then
						inst.AnimState:PlayAnimation("full")
					else
						inst.AnimState:PlayAnimation("extract_success")
					end
				end
			end
		end)

    local color = 0.5 + math.random() * 0.5
    anim:SetMultColour(color, color, color, 1)    

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "ROCK"

	inst:AddComponent("mystery")

    inst.OnSave = onsave 
    inst.OnLoad = onload

	MakeSnowCovered(inst, .01)
	return inst
end


local function pig_ruins_head()
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("pig_ruins_head")
	inst.AnimState:SetBuild("ruins_giant_head")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "ruins_giant_head.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)  
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])
	inst.components.lootdropper:SetChanceLootTable('ruins_gianthead')

	inst:AddComponent("dislodgeable")
	inst.components.dislodgeable:SetUp("relic_3",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = function() 
			if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
				return false
			end
			return true
		end

	inst.components.inspectable.nameoverride = nil

	return inst
end


local function shine(inst)
    inst.task = nil
   
   	if inst.components.dislodgeable and inst.components.dislodgeable:CanBeDislodged() then
   		inst.AnimState:PlayAnimation("sparkle")
   		inst.AnimState:PushAnimation("full")
   	end
    
    if inst.entity:IsAwake() then
        inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
    end
end

local function onwake(inst)
    inst.task = inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
end

local function pig_ruins_pig()
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("statue_pig_ruins_pig")
	inst.AnimState:SetBuild("statue_pig_ruins_pig")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_pig.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)  
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst:AddComponent("dislodgeable")
	inst.components.dislodgeable:SetUp("goldnugget",2)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
    inst.OnEntityWake = onwake
	inst.components.dislodgeable.canbedislodgedfn = function() 
			if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
				return false
			end
			return true
		end

	inst.components.inspectable.nameoverride = nil

	return inst
end

local function pig_ruins_ant()
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("statue_pig_ruins_ant")
	inst.AnimState:SetBuild("statue_pig_ruins_ant")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_ant.tex" )
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)  

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst:AddComponent("dislodgeable")
	inst.components.dislodgeable:SetUp("goldnugget",2)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)

    inst.OnEntityWake = onwake

	inst.components.dislodgeable.canbedislodgedfn = function() 
			if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
				return false
			end
			return true
		end
	return inst
end

local function pig_ruins_idol()	
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("statue_pig_ruins_idol")
	inst.AnimState:SetBuild("statue_pig_ruins_idol")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_idol.tex" )
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	MakeObstaclePhysics(inst, 0.75)

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)  

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_IDOL"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst:AddComponent("dislodgeable")
	inst.components.dislodgeable:SetUp("relic_1",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = function() 
			if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
				return false
			end
			return true
		end

	inst.components.inspectable.nameoverride = nil

	return inst
end

local function pig_ruins_plaque()
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("statue_pig_ruins_plaque")
	inst.AnimState:SetBuild("statue_pig_ruins_plaque")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_plaque.tex" )
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	MakeObstaclePhysics(inst, 0.75)

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)  

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_PLAQUE"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst:AddComponent("dislodgeable")
	inst.components.dislodgeable:SetUp("relic_2",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = function() 
			if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
				return false
			end
			return true
		end

	inst.components.inspectable.nameoverride = nil

	return inst
end

local function pig_ruins_artichoke()
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("rock")
	inst.AnimState:SetBuild("ruins_artichoke")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "ruins_artichoke.tex" )
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["ROCK_FLINTLESS"])
	inst.components.lootdropper:SetChanceLootTable('ruins_artichoke')

	return inst
end

local function antqueen_throne()
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("throne")
	inst.AnimState:SetBuild("throne")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "ruins_artichoke.tex" )
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.Transform:SetScale(0.9, 0.9, 0.9)
	MakeObstaclePhysics(inst, 3.5)

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["ANTQUEEN_THRONE"])
	inst.components.lootdropper:SetChanceLootTable('antqueen_throne')

	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_GIANT)

	inst:ListenForEvent( "onremove", function()
		local x, y, z = inst.Transform:GetWorldPosition()

		local ents = TheSim:FindEntities(x,y,z, 10, {"throne_wall"})
	    for k,v in pairs(ents) do
	        v:Remove()
	    end
	end, inst )

	return inst
end


local function pig_ruins_truffle()	
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("statue_pig_ruins_mushroom")
	inst.AnimState:SetBuild("statue_pig_ruins_mushroom")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_mushroom.tex" )
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	MakeObstaclePhysics(inst, 0.75)

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)  

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_MUSHROOM"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst:AddComponent("dislodgeable")
	inst.components.dislodgeable:SetUp("relic_5",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = function() 
			if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
				return false
			end
			return true
		end

	return inst
end

local function pig_ruins_sow()	
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("statue_pig_ruins_idol_blue")
	inst.AnimState:SetBuild("statue_pig_ruins_idol_blue")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_idol_blue.tex" )
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	MakeObstaclePhysics(inst, 0.75)

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)  

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_SOW"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst:AddComponent("dislodgeable")
	inst.components.dislodgeable:SetUp("relic_4",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = function() 
			if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
				return false
			end
			return true
		end

	return inst
end

local function basalt_fn(Sim)
	local inst = baserock_fn(Sim)
	inst.AnimState:SetBank("rock_basalt")
	inst.AnimState:SetBuild("rock_basalt")
	inst.AnimState:PlayAnimation("full")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.lootdropper:SetChanceLootTable('basalt')

	return inst
end

return  Prefab("pig_ruins_head", pig_ruins_head, ruins_assets, prefabs),
        Prefab("pig_ruins_pig", pig_ruins_pig, ruins_assets, prefabs),
        Prefab("pig_ruins_ant", pig_ruins_ant, ruins_assets, prefabs),
        Prefab("pig_ruins_idol", pig_ruins_idol, ruins_assets, prefabs),
        Prefab("pig_ruins_plaque", pig_ruins_plaque, ruins_assets, prefabs),
        Prefab("pig_ruins_artichoke", pig_ruins_artichoke, ruins_assets, prefabs),
        Prefab("pig_ruins_truffle", pig_ruins_truffle, ruins_assets, prefabs),
        Prefab("pig_ruins_sow", pig_ruins_sow, ruins_assets, prefabs),
        Prefab("antqueen_throne", antqueen_throne, antqueen_throne_assets, prefabs),
        Prefab("rock_basalt", basalt_fn, basalt_assets, prefabs)
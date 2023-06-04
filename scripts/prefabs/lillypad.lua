local assets =
{
	Asset("ANIM", "anim/lily_pad.zip"),
	Asset("ANIM", "anim/splash.zip"),
	Asset("MINIMAP_IMAGE", "lily_pad"),

}

local prefabs =
{
	"frog_poison",
	"mosquito",
}

function MakeLilypadPhysics(inst, rad)
    inst:AddTag("blocker")
    inst.entity:AddPhysics()
    --this is lame. Bullet wants 0 mass for static objects, 
    -- for for some reason it is slow when we do that

    -- Doesnt seem to slow anything down now.
    inst.Physics:SetMass(0)
    inst.Physics:SetCapsule(rad,0.01)
   -- inst.Physics:SetCylinder(rad, 1.0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
	inst.Physics:CollidesWith((TheWorld.has_ocean and COLLISION.GROUND) or COLLISION.WORLD) -- i ADDED THIS
    -- inst.Physics:CollidesWith(COLLISION.WAVES) TODO Fix This
    -- inst.Physics:CollidesWith(COLLISION.INTWALL) TODO fix this
	inst.Physics:CollidesWith(COLLISION.WORLD)
end

local function ReturnChildren(inst)
	for k,child in pairs(inst.components.childspawner.childrenoutside) do
		if child.components.homeseeker then
			child.components.homeseeker:GoHome()
		end
		child:PushEvent("gohome")
	end
end


local function OnSpawned(inst, child)
	if inst.components.childspawner.childname == "frog_poison" then
	 	inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/water/small_submerge")		
		child.sg:GoToState("submerge")
	end
end
--[[
local function OnSnowCoverChange(inst, thresh)
	thresh = thresh or .02
	local snow_cover = GetSeasonManager() and GetSeasonManager():GetSnowPercent() or 0

	if snow_cover > thresh and not inst.frozen then
		inst.frozen = true
		inst.AnimState:PlayAnimation("frozen")
		inst.SoundEmitter:PlaySound("dontstarve/winter/pondfreeze")
	    inst.components.childspawner:StopSpawning()
		inst.components.fishable:Freeze()

        inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(GetWorldCollision())
        inst.Physics:CollidesWith(COLLISION.ITEMS)

		for i,item in ipairs(inst.decor) do
			item:Remove()
		end
		inst.decor = {}
	elseif snow_cover < thresh and inst.frozen then
		inst.frozen = false
		inst.AnimState:PlayAnimation("idle"..inst.pondtype)
	    inst.components.childspawner:StartSpawning()
		inst.components.fishable:Unfreeze()

		inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(GetWorldCollision())
        inst.Physics:CollidesWith(COLLISION.ITEMS)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
		inst.Physics:CollidesWith(COLLISION.WAVES)

		SpawnPlants(inst, inst.planttype)
	end
end
]]
local function refreshimage(inst)
	inst.AnimState:PlayAnimation(inst.size.."_idle", true)
	inst.Transform:SetRotation(inst.rotation)

	if inst.size == "small" then
		MakeLilypadPhysics(inst, 2)
	elseif inst.size == "med" then
		MakeLilypadPhysics(inst, 3)
	elseif inst.size == "big" then
		MakeLilypadPhysics(inst, 4.2)
	end
end

local function dayfn(inst)
	-- if inst.components.childspawner.childname == "frog_poison" then		
	if inst.components.childspawner.childname == "mosquito" then		
		inst.components.childspawner:StartSpawning()					
	end
		if inst.components.childspawner.childname == "mosquito" then
		inst.components.childspawner:StopSpawning()    		
	    ReturnChildren(inst)			
	end
end

local function duskfn(inst)
	 if inst.components.childspawner.childname == "frog_poison" then  --TODO fix
		inst.components.childspawner:StartSpawning()
    end
end

local function nightfn(inst)
	-- if inst.components.childspawner.childname == "frog_poison" then
	if inst.components.childspawner.childname == "frog_poison" then --TODO fix
		inst.components.childspawner:StopSpawning()    		
	    ReturnChildren(inst)	
    end		
end

local function onload(inst, data, newents)
	--OnSnowCoverChange(inst)
	if data then
		if data.size then
			inst.size = data.size
		end
		if data.childname then
			inst.components.childspawner.childname = data.childname 
		end
	end

	if TheWorld.state.isnight then
		nightfn(inst)
	end

	if TheWorld.state.isday then
		dayfn(inst)
	end

	if TheWorld.state.isdusk then
		duskfn(inst)
	end

	refreshimage(inst)
end

local function onsave(inst, data)
	data.size= inst.size
	data.rotation = inst.rotation
	data.childname = inst.components.childspawner.childname
	--OnSnowCoverChange(inst)
end

local function fn(pondtype)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.pondtype = pondtype
	inst.entity:AddNetwork()
  --  MakeObstaclePhysics( inst, 1.95)

    anim:SetBuild("lily_pad")
    anim:SetBank("lily_pad")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end

	inst.size = "small"

    if math.random() < 0.66 then
    	if math.random() < 0.33 then
			inst.size = "med"
    	else
    		inst.size = "big"
    	end
    end

    inst.rotation = math.random(360)
    refreshimage(inst)

	anim:SetOrientation( ANIM_ORIENTATION.OnGround )
	anim:SetLayer( LAYER_BACKGROUND )
	anim:SetSortOrder( 3 )

	inst:AddComponent("waveobstacle")

	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "lily_pad.png" )

	inst:AddComponent( "childspawner" )
	inst.components.childspawner:SetRegenPeriod(TUNING.POND_REGEN_TIME)
	inst.components.childspawner:SetSpawnPeriod(TUNING.POND_SPAWN_TIME)
	inst.components.childspawner:SetMaxChildren(math.random(1,2))
	inst.components.childspawner:SetSpawnedFn(OnSpawned)
	inst.components.childspawner.spawnonwater = true 
	inst.components.childspawner.spawnonwateroffset = 1
	inst.components.childspawner:StartRegen()

    if math.random() <0.5 then
    	inst.components.childspawner.childname = "mosquito"
    	inst.components.childspawner:SetRegenPeriod(TUNING.MOSQUITO_REGEN_TIME)
    	inst.components.childspawner:SetMaxChildren(TUNING.MOSQUITO_MAX_SPAWN)
    else
		inst.components.childspawner.childname = "frog_poison"
		inst.components.childspawner:SetRegenPeriod(TUNING.FROG_POISON_REGEN_TIME)
		inst.components.childspawner:SetMaxChildren(TUNING.FROG_POISON_MAX_SPAWN)
	end

	inst:WatchWorldState("isdusk", duskfn)
    inst:WatchWorldState("isday", dayfn)
	inst:WatchWorldState("isnight", nightfn)
	

	inst.frozen = false

    inst:AddComponent("inspectable")
    inst.no_wet_prefix = true

	inst.OnLoad = onload
	inst.OnSave = onsave


	return inst
end



--Test Codes 
-- inst:ListenForEvent("phasechanged", OnPhaseChanged, _world)
-- local function OnPhaseChanged(src, phase)
--     _daylight = phase == "day"
-- end
-- local _world = TheWorld
return Prefab( "marsh/objects/lilypad", fn, assets, prefabs)

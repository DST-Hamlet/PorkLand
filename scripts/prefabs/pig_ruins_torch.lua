require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/ruins_torch.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins.zip"),   
    Asset("ANIM", "anim/interior_wall_decals_ruins_blue.zip"),       
    Asset("MINIMAP_IMAGE", "ruins_torch"), 
}

local prefabs =
{
    "campfirefire"
}    

local function onignite(inst)
    if not inst.components.cooker then
        inst:AddComponent("cooker")
    end

    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50,{"pig_writing_1"},{"INTERIOR_LIMBO"})
    for i, ent in ipairs(ents) do      
        ent:PushEvent("fire_lit")        
    end

end

local function onextinguish(inst)
    if inst.components.cooker then
        inst:RemoveComponent("cooker")
    end
    if inst.components.fueled then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function destroy(inst)
	local time_to_wait = 1
	local time_to_erode = 1
	local tick_time = TheSim:GetTickTime()

	if inst.DynamicShadow then
        inst.DynamicShadow:Enable(false)
    end

	inst:StartThread( function()
		local ticks = 0
		while ticks * tick_time < time_to_wait do
			ticks = ticks + 1
			Yield()
		end

		ticks = 0
		while ticks * tick_time < time_to_erode do
			local erode_amount = ticks * tick_time / time_to_erode
			inst.AnimState:SetErosionParams( erode_amount, 0.1, 1.0 )
			ticks = ticks + 1
			Yield()
		end
		inst:Remove()
	end)
end

local function onsave(inst, data)    
    data.rotation = inst.Transform:GetRotation()
    if inst.flipped then
        data.flipped = inst.flipped
    end    
end


local function onload(inst, data)
    if data then
        if data.rotation then
            inst.Transform:SetRotation(data.rotation)
        end
        if data.flipped then
            inst.flipped = data.flipped
            local rx,ry,rz = inst.Transform:GetScale()
            inst.AnimState:SetScale(-rx,ry,rz)
        end         
    end  
end

local function fn(Sim)

	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
    
    anim:SetBank("ruinstorch")
    anim:SetBuild("ruins_torch")
    anim:PlayAnimation("idle")
    
    ---inst.AnimState:SetRayTestOnBB(true);
    inst:AddTag("campfire")
    inst:AddTag("structure")    
    
    MakeObstaclePhysics(inst, .2)    
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
    -----------------------
    inst:AddComponent("propagator")
    -----------------------
    
    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)

    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0,20,0), "fire_marker" )
    -- inst.components.burnable:MakeNotWildfireStarter()    
	inst:AddTag("wildfireprotected")
    inst:ListenForEvent("onextinguish", onextinguish)
    inst:ListenForEvent("onignite", onignite)

    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.CAMPFIRE_FUEL_MAX
    inst.components.fueled.accepting = true
    
    inst.components.fueled:SetSections(4)
    
    inst.components.fueled.ontakefuelfn = function() inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") end
    inst.components.fueled:SetUpdateFn( function()
        local rate = 1 
		-- Is this stuff even needed? These torches are only ever inside, right?
        -- if GetSeasonManager() and GetSeasonManager():IsRaining() then
            -- inst.components.fueled.rate = 1 + TUNING.FIREPIT_RAIN_RATE*GetSeasonManager():GetPrecipitationRate()
        -- end
        -- if inst:GetIsFlooded() then 
            -- rate = rate + TUNING.FIREPIT_FLOOD_RATE
        -- end 
        -- rate = rate +  GetSeasonManager():GetHurricaneWindSpeed() * TUNING.FIREPIT_WIND_RATE

        inst.components.fueled.rate = rate 
        if inst.components.burnable and inst.components.fueled then
            inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
        end
    end)
    
    inst.components.fueled:SetSectionCallback( function(section)
        if section == 0 then
            inst.components.burnable:Extinguish() 
        else
            if not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
            end
            
            inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent())
            
        end
    end)
        
    inst.components.fueled:InitializeFuelLevel(0)
    -----------------------------
    
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst)
        local sec = inst.components.fueled:GetCurrentSection()
        if sec == 0 then 
            return "OUT"
        elseif sec <= 4 then
            local t= {"EMBERS","LOW","NORMAL","HIGH"} 
            return t[sec]
        end
    end
    
    --------------------

    inst.OnSave = onsave 
    inst.OnLoad = onload 
           
    return inst
end

local function pillarfn(Sim)
    local inst = fn(Sim)
    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("ruins_torch.tex")
    return inst
end

local function wallfn(Sim)
    local inst = fn(Sim)

    local anim = inst.AnimState

    inst.AnimState:SetLayer( LAYER_BACKGROUND )
    inst.AnimState:SetSortOrder( 1 )  

    inst:AddTag("wall_torch")

    anim:SetBank("interior_wall_decals_ruins")
    anim:SetBuild("interior_wall_decals_ruins")
    anim:PlayAnimation("sconce_front")    

    return inst
end

local function sidewallfn(Sim)
    local inst = fn(Sim)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
    local anim = inst.AnimState

    inst.AnimState:SetLayer( LAYER_BACKGROUND )
    inst.AnimState:SetSortOrder( 3 )  
    -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.RotatingBillboard)       
    -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.Billboard)
    -- anim:SetOrientation(ANIM_ORIENTATION.Billboard)

    inst:SetPrefabNameOverride("pig_ruins_torch_wall")

    inst:AddTag("wall_torch")
    
    anim:SetBank("interior_wall_decals_ruins")
    anim:SetBuild("interior_wall_decals_ruins")
    anim:PlayAnimation("sconce_sidewall")

    return inst
end

local function wallbluefn(Sim)
    local inst = wallfn(Sim)
    inst:SetPrefabNameOverride("pig_ruins_torch_wall")
    inst.AnimState:SetBuild("interior_wall_decals_ruins_blue")
    return inst
end

local function sidewallbluefn(Sim)
    local inst = sidewallfn(Sim)
    inst.AnimState:SetBuild("interior_wall_decals_ruins_blue")
    return inst
end


return  Prefab( "pig_ruins_torch", pillarfn, assets, prefabs),
        Prefab( "pig_ruins_torch_wall", wallfn, assets, prefabs),
        Prefab( "pig_ruins_torch_sidewall", sidewallfn, assets, prefabs),
    
        Prefab( "pig_ruins_torch_wall_blue", wallbluefn, assets, prefabs),
        Prefab( "pig_ruins_torch_sidewall_blue", sidewallbluefn, assets, prefabs)


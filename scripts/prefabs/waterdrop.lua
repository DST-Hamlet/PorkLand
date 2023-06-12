local assets =
{
	Asset("ANIM", "anim/waterdrop.zip"),
    Asset("ANIM", "anim/lifeplant.zip"),
}

local function OnSave(inst, data)

end

local function OnLoadPostPass(inst, newents, data)

end

local function OnRemoved(inst)
    if inst.fountain and not inst.planted then
        inst.fountain.deactivate(inst.fountain)
    end
end

local function OnEaten(inst, eater)
	local health = eater.components.health
	if health ~= nil and not health:IsDead() then
		if not eater.components.oldager == nil then
			eater.components.oldager:StopDamageOverTime()
			health:DoDelta(TUNING.POCKETWATCH_HEAL_HEALING * 4, true, inst.prefab)
		end
	end
end

local function ondeploy (inst, pt) 

    local plant = SpawnPrefab("lifeplant")
    plant.Transform:SetPosition(pt:Get() )
    plant.onplanted(plant,inst.fountain)

    inst.planted = true
    inst:Remove()
end

local notags = {'NOBLOCK', 'player', 'FX'}
local function test_ground(inst, pt)
    local tiletype = GetGroundTypeAtPosition(pt)
    local ground_OK = tiletype ~= GROUND.ROCKY and tiletype ~= GROUND.ROAD and tiletype ~= GROUND.IMPASSABLE and
                        tiletype ~= GROUND.UNDERROCK and tiletype ~= GROUND.WOODFLOOR and 
                        tiletype ~= GROUND.CARPET and tiletype ~= GROUND.CHECKER and tiletype < GROUND.UNDERGROUND and not GetWorld().Map:IsWater(tiletype)
    
    if ground_OK then
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 4, nil, notags) -- or we could include a flag to the search?
        local min_spacing = inst.components.deployable.min_spacing or 2

        for k, v in pairs(ents) do
            if v ~= inst and v:IsValid() and v.entity:IsVisible() and not v.components.placer and v.parent == nil then
                if distsq( Vector3(v.Transform:GetWorldPosition()), pt) < min_spacing*min_spacing then
                    return false
                end
            end
        end
        return true
    end
    return false
end


local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle_water", "idle")
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

    inst.AnimState:SetBank("waterdrop")
    inst.AnimState:SetBuild("waterdrop")

    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("waterdrop")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "VEGGIE"    
    inst.components.edible.healthvalue = TUNING.HEALING_SUPERHUGE * 3
    inst.components.edible.hungervalue = TUNING.CALORIES_SUPERHUGE * 3
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE * 3   
	inst.components.edible:SetOnEatenFn(OnEaten) -- For Wanda stuff

    inst:AddComponent("poisonhealer")

    inst:AddComponent("inspectable")

    -- inst:AddComponent("appeasement")
    -- inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL
           
    inst.OnSave = OnSave 
    --inst.OnLoad = onload
    inst.OnLoadPostPass = OnLoadPostPass

    inst:AddComponent("inventoryitem")

    inst:ListenForEvent("onremove", OnRemoved)
    
    inst:AddComponent("deployable")
    inst.components.deployable.test = test_ground
    inst.components.deployable.ondeploy = ondeploy    

    inst:DoTaskInTime(0,function()
            for k,v in pairs(Ents) do                
                if v:HasTag("pugalisk_fountain") then
                    inst.fountain = v
                    break
                end
            end
        end)

    return inst
end

return Prefab( "waterdrop", fn, assets),
       MakePlacer( "waterdrop_placer", "lifeplant", "lifeplant", "idle_loop" )


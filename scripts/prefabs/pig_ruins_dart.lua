require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/ruins_blow_dart.zip"),  
    Asset("ANIM", "anim/interior_wall_decals_ruins.zip"), 
    Asset("ANIM", "anim/interior_wall_decals_ruins_blue.zip"), 
}

local prefabs =
{

}    

local function oncollide(inst, other)

    if other and other.prefab ~= inst.prefab then
        inst.components.combat:DoAttack(other, nil, nil, nil, nil, nil, nil) --2*25 dmg
        -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/blowdart_fire")
        local impactfx = SpawnPrefab("impact")
        
        if impactfx and inst then
          --  local follower = impactfx.entity:AddFollower()
         --   follower:FollowSymbol(other.GUID, other.components.combat.hiteffectsymbol, 0, 0, 0 )
            impactfx:FacePoint(inst.Transform:GetWorldPosition())
        end            

        local fx = SpawnPrefab("circle_puff_fx")
		if fx and inst then -- Some crash prevention. It'll work when it's made to work, this way it saves having to go back
			local x,y,z = inst.Transform:GetWorldPosition()
			fx.Transform:SetPosition(x,y,z)
		end
    end
    inst:Remove()
end

local function fn(Sim)

	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end


    MakeCharacterPhysics(inst, 10, .5)
    
    trans:SetEightFaced()


    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.PIG_RUINS_DART_DAMAGE)

    inst.Physics:SetCollisionCallback(oncollide)

    inst.entity:AddSoundEmitter()    

    anim:SetBank("dart")
    anim:SetBuild("ruins_blow_dart")
    anim:PlayAnimation("idle")
 
    inst:AddTag("projectile")

    inst:AddTag("NOCLICK")
           
    return inst
end

local function updateart(inst)    
    local anim = inst.animframe
    if not inst.components.disarmable.armed then
        anim = anim .."_disarmed"
    end
    inst.AnimState:PlayAnimation(anim)
end

local function onsave(inst, data)    
    if inst.animframe then
        data.animframe = inst.animframe
    end
end

local function onload(inst, data)
    if data.animframe then
        inst.animframe = data.animframe
    end
    inst:DoTaskInTime(0,function() updateart(inst) end)
    
end

local function launchdart(inst, angle, xmod, zmod)

        inst:DoTaskInTime( math.random()*0.6, function()
                local proj = SpawnPrefab("pig_ruins_dart")
                local x, y, z = inst.Transform:GetWorldPosition()
                proj.Transform:SetPosition(x+xmod, y, z+zmod)        
                proj.Transform:SetRotation(angle)                        
                proj.Physics:SetMotorVel(30, 0, 0)
                proj.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/blowdart_fire")

                local fx = SpawnPrefab("circle_puff_fx")
                if fx then                    
                    local follower = fx.entity:AddFollower()
                    follower:FollowSymbol(inst.GUID, "fx_marker", 0, 0, 0)                
                end                
            end)     
end

local function shoot(inst)
    if inst.components.disarmable.armed then
        if inst:HasTag("dartthrower_left") then

            launchdart(inst, -90, 0, 2)

        elseif inst:HasTag("dartthrower_right") then
            
            launchdart(inst, 90, 0, -2)
              
        elseif inst:HasTag("dartthrower") then

            launchdart(inst, 0, 2, 0)

        end       
    end
end

local function disarm(inst, doer)    
    local pt = Point(inst.Transform:GetWorldPosition())
    inst.components.lootdropper:SpawnLootPrefab("blowdart_pipe", pt)
    updateart(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_wall")
    --doer.components.inventory:GiveItem( SpawnPrefab("blowdart_pipe"))
end

local function makefn(build, bank, animframe, facing)
    local function fn(Sim)

        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
		inst.entity:AddNetwork()

        anim:SetBank(bank)
        anim:SetBuild(build)
        anim:PlayAnimation(animframe)

        inst.animframe = animframe

        inst:AddTag("dartthrower")

        if facing then        
            if facing == "left" then            
                inst.AnimState:SetScale(-1, 1, 1)                
                inst:AddTag("dartthrower_right")
            end
            if facing == "right" then
                inst:AddTag("dartthrower_left")
            end            
        end

        inst.entity:AddSoundEmitter()    
	
		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

        inst.AnimState:SetLayer( LAYER_WORLD_BACKGROUND )
        inst.AnimState:SetSortOrder( 1 )   
        inst.setbackground = 1        
        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.RotatingBillboard)
        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.Billboard)
        
        inst.Transform:SetRotation(-90)

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "pig_ruins_dart_trap"

        inst:AddComponent("disarmable")
        inst.components.disarmable.disarmfn = disarm

        inst:AddComponent("lootdropper")

        inst:AddComponent("hiddendanger")
        inst.components.hiddendanger.offset = {x=0,y=1.7,z=0}

        --------------------
        inst.OnSave = onsave 
        inst.OnLoad = onload 
        inst.shoot = shoot
               
        inst.name = STRINGS.NAMES.PIG_RUINS_DART_TRAP

        updateart(inst)

        return inst
    end
    return fn
end

local function darts(name, build, bank, anim, facing)
    return Prefab(name, makefn(build, bank, anim, facing),  assets, prefabs )
end

return  Prefab("pig_ruins_dart", fn, assets, prefabs),
        darts("pig_ruins_pigman_relief_dart1","interior_wall_decals_ruins","interior_wall_decals_ruins","relief_confused", "down"),
        darts("pig_ruins_pigman_relief_dart2","interior_wall_decals_ruins","interior_wall_decals_ruins","relief_happy", "down" ),
        darts("pig_ruins_pigman_relief_dart3","interior_wall_decals_ruins","interior_wall_decals_ruins","relief_surprise", "down" ),
        darts("pig_ruins_pigman_relief_dart4","interior_wall_decals_ruins","interior_wall_decals_ruins","relief_head", "down" ),

        darts("pig_ruins_pigman_relief_leftside_dart","interior_wall_decals_ruins","interior_wall_decals_ruins","relief_sidewall", "right" ),
        darts("pig_ruins_pigman_relief_rightside_dart","interior_wall_decals_ruins","interior_wall_decals_ruins","relief_sidewall", "left" ),

        darts("pig_ruins_pigman_relief_dart1_blue","interior_wall_decals_ruins_blue","interior_wall_decals_ruins","relief_confused", "down"),
        darts("pig_ruins_pigman_relief_dart2_blue","interior_wall_decals_ruins_blue","interior_wall_decals_ruins","relief_happy", "down" ),
        darts("pig_ruins_pigman_relief_dart3_blue","interior_wall_decals_ruins_blue","interior_wall_decals_ruins","relief_surprise", "down" ),
        darts("pig_ruins_pigman_relief_dart4_blue","interior_wall_decals_ruins_blue","interior_wall_decals_ruins","relief_head", "down" ),

        darts("pig_ruins_pigman_relief_leftside_dart_blue","interior_wall_decals_ruins_blue","interior_wall_decals_ruins","relief_sidewall", "right" ),
        darts("pig_ruins_pigman_relief_rightside_dart_blue","interior_wall_decals_ruins_blue","interior_wall_decals_ruins","relief_sidewall", "left" )        

        
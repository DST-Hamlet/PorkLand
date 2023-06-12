require "prefabutil"
require "recipes"

local assets =
{
    Asset("ANIM", "anim/pig_ruins_vines_door.zip"),   
    Asset("ANIM", "anim/pig_ruins_vines_build.zip"),       
}

local assets_wall =
{
    Asset("ANIM", "anim/pig_ruins_vines_wall.zip"),       
    Asset("ANIM", "anim/pig_ruins_vines_build.zip"),    
}

local prefabs = 
{

}

local function getanimname(inst)

    local stage_string = "_closed"    

    if inst.stage == 1 then
        stage_string = "_med"
    elseif inst.stage == 0 then
        stage_string = "_open"
    end

    return inst.facing..stage_string  
end

local function blockdoor(inst)
    -- send event to dissable the door.  the listener will respond if it's the door OR the target door
    if inst.door then
        inst.door.components.vineable:SetDoorDissabled(true)
    end
end

local function cleardoor(inst)
    -- send event to enable the door. the listener will respond if it's the door OR the target door
    if inst.door then
        inst.door.components.vineable:SetDoorDissabled(false)
    end
end

local function regrow(inst)
    -- this is just for viuals, it doesn't actually lock the assotiated door.
    if inst.stage ~= 2 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/vine_grow")
        inst.stage = 2
        inst.components.hackable.canbehacked = true
        inst.components.hackable.hacksleft = inst.components.hackable.maxhacks  
        inst:RemoveTag("NOCLICK")    
        inst.AnimState:PlayAnimation(getanimname(inst).."_pre", true)
        inst.AnimState:PushAnimation(getanimname(inst), true)       
    end
end

local function hackedopen(inst)
    -- this is just for viuals, it doesn't actually open the assotiated door.
    inst.stage = 0
    inst.components.hackable.canbehacked = false
    inst:AddTag("NOCLICK")         
    inst.AnimState:PlayAnimation(getanimname(inst), true)            
end

local function onhackedfn(inst, hacker, hacksleft)
    
    if hacksleft <= 0 then
        if inst.stage > 0 then
            inst.stage = inst.stage -1           

            if inst.stage == 0 then
                cleardoor(inst)  
                if inst.door then                    
                   --  inst.door.components.vineable:BeginRegrow()                       
                end
            else
                inst.AnimState:PlayAnimation(getanimname(inst).."_hit")
                inst.AnimState:PushAnimation(getanimname(inst), true)                
                inst.components.hackable.hacksleft = inst.components.hackable.maxhacks
            end
        end
    else
        inst.AnimState:PlayAnimation(getanimname(inst).."_hit")
        inst.AnimState:PushAnimation(getanimname(inst), true)
    end

    local fx = SpawnPrefab("hacking_fx")
    local x, y, z= inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x,y + math.random()*2,z)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")
end

local function setup(inst)
    blockdoor(inst)

    if inst.door:HasTag("door_north") then
        inst.facing = "north"
    elseif inst.door:HasTag("door_south") then
        inst.facing = "south"
    elseif inst.door:HasTag("door_east") then
        inst.facing = "east"
    elseif inst.door:HasTag("door_west") then
        inst.facing = "west"
    end
  
    if inst.facing ~= "south" then
        inst.AnimState:SetLayer( LAYER_WORLD_BACKGROUND )
        inst.AnimState:SetSortOrder( 4 ) 
    end

    inst.AnimState:PlayAnimation(getanimname(inst), true)  
end

local function makefn()

    local function fn(Sim)
    	local inst = CreateEntity()
    	local trans = inst.entity:AddTransform()
    	local anim = inst.entity:AddAnimState()
        local light = inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()
	
        anim:SetBank("pig_ruins_vines_door")
        anim:SetBuild("pig_ruins_vines_build")
		
		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.RotatingBillboard)
        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.Billboard)

        inst.facing = "north"
        inst.stage = 2
        inst.AnimState:PlayAnimation(getanimname(inst), true)

        inst:AddComponent("hackable")
        inst.components.hackable:SetUp()
        inst.components.hackable.onhackedfn = onhackedfn
        inst.components.hackable.hacksleft = TUNING.RUINS_DOOR_VINES_HACKS
        inst.components.hackable.maxhacks = TUNING.RUINS_DOOR_VINES_HACKS

        inst:AddComponent("shearable")

        inst:AddComponent("inspectable")
       -- inst.components.inspectable.getstatus = inspect

        inst.setup = setup

        inst.regrow = regrow
        inst.hackedopen = hackedopen
       
        return inst
    end
    return fn
end

local function makewallfn(facing)

    local function fn(Sim)
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        local light = inst.entity:AddLight()
        inst.entity:AddSoundEmitter()

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end
		
        inst.Transform:SetRotation(-90)
        -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.RotatingBillboard)
        inst.AnimState:SetLayer( LAYER_WORLD_BACKGROUND )
        inst.AnimState:SetSortOrder( 3 )        

        inst.facing = facing
        
        anim:SetBank("pig_ruins_vines_wall")
        anim:SetBuild("pig_ruins_vines_build")
        inst.AnimState:PlayAnimation(inst.facing..math.random(1,15), true)        
       
        return inst
    end
    return fn
end
 
return Prefab("pig_ruins_creeping_vines", makefn(), assets, prefabs ),
       Prefab("pig_ruins_wall_vines_north", makewallfn("north_"), assets_wall, prefabs ),
       Prefab("pig_ruins_wall_vines_east", makewallfn("east_"), assets_wall, prefabs ),
       Prefab("pig_ruins_wall_vines_west", makewallfn("west_"), assets_wall, prefabs )



	   



require "stategraphs/SGdungbeetle"

local assets=
{
	Asset("ANIM", "anim/dung_beetle_basic.zip"),
	Asset("ANIM", "anim/dung_beetle_build.zip"),
}

local prefabs =
{
    "dungball",
    "monstermeat",
    -- "chitin",
}


SetSharedLootTable( 'dungbeetle',
{
    {'monstermeat',  1},
    -- {'chitin',    0.5},

})

local beetlesounds = 
{
    scream = "dontstarve_DLC003/creatures/dungbeetle/scream",
    hurt = "dontstarve_DLC003/creatures/dungbeetle/hit",
}

local brain = require "brains/dungbeetlebrain"

local function OnWake(inst)

end

local function OnSleep(inst)

end

local function falloffdung(inst)
    inst:PushEvent("bumped")
end

local function OnAttacked(inst, data)
    local freezetask = inst:DoTaskInTime(1, function() 
        if inst:HasTag("hasdung") and not inst.components.freezable:IsFrozen() then
            falloffdung(inst)        
        end
    end)
end

local SHAKE_DIST = 40

local function oncollide(inst, other)

    if inst.sg:HasStateTag("running") and inst:HasTag("hasdung")  then

        if other then 
            falloffdung(inst)
        end 
    end

end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    local physics = inst.entity:AddPhysics()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
	shadow:SetSize( 2, 1.5)

    inst:AddTag("hasdung") 

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 1, 0.5)

    if TheWorld.ismastersim then
        inst.Physics:SetCollisionCallback(oncollide)
    end

    anim:SetBank("dung_beetle")
    anim:SetBuild("dung_beetle_build")
    if inst:HasTag("hasdung") then
        anim:PlayAnimation("ball_idle")
    else
        anim:PlayAnimation("idle")
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetStateGraph("SGdungbeetle")
    inst.sg:GoToState("idle")
    
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.DUNG_BEETLE_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.DUNG_BEETLE_WALK_SPEED

    inst:AddTag("animal") 
    inst:AddTag("dungbeetle") 
    
    inst:SetBrain(brain)
    
    inst.data = {}  
    
    inst:AddComponent("knownlocations")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DUNG_BEETLE_HEALTH)
    inst.components.health.murdersound = "dontstarve/rabbit/scream_short"
    
    MakeSmallBurnableCharacter(inst, "body")
    MakeTinyFreezableCharacter(inst, "body")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('dungbeetle')
    
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst, viewer)
        if not inst:HasTag("hasdung") then
            return "UNDUNGED"
        end
    end
    inst:AddComponent("sleeper")
	
	inst.OnEntityWake = OnWake
	inst.OnEntitySleep = OnSleep    
    
    inst.sounds = beetlesounds

    inst.OnSave = function(inst, data)
        if not inst:HasTag("hasdung") then
            data.lost_dung = true
        end
    end        
    
    inst.OnLoad = function(inst, data)
        if data.lost_dung then
            inst:RemoveTag("hasdung")
        end
    end
        
    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab( "dungbeetle", fn, assets, prefabs) 

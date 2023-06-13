local easing = require("easing")

local AVERAGE_WALK_SPEED = 4
local WALK_SPEED_VARIATION = 2
local SPEED_VAR_INTERVAL = .5
local ANGLE_VARIANCE = 10

local assets =
{
	Asset("ANIM", "anim/tumbleweed.zip"),
    Asset("ANIM", "anim/dungball_build.zip"),    
}

local prefabs = 
{
	"cutgrass",
	"twigs",
    "rocks",
    "flint",
    "poop",
}

local SFX_COOLDOWN = 5

local function onpickup(inst, owner)
	if owner and owner.components.inventory then
		if inst.owner and inst.owner.components.childspawner then 
			inst:PushEvent("pickedup")
		end

		local item = nil
		for i, v in ipairs(inst.loot) do

            if inst.components.lootdropper then
               inst.components.lootdropper:SpawnLootPrefab(v)
            end
    	end
    end

    inst.AnimState:PlayAnimation("break")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/dungball_break")
    inst.DynamicShadow:Enable(false)
    inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst:ListenForEvent("entitysleep", inst.Remove)
    
    return true --This makes the inventoryitem component not actually give the tumbleweed to the player
end

local function MakeLoot(inst)
    local possible_loot =
    {
        {chance = 1,   item = "cutgrass"},
        {chance = 1,   item = "twigs"},
        {chance = 10,   item = "rocks"},        
        {chance = 10,   item = "flint"},
        {chance = 1,   item = "seeds"},
        {chance = 5,   item = "poop"},
        -- {chance = 0.1, item = "relic_1"},
    }
    local totalchance = 0
    for m, n in ipairs(possible_loot) do
        totalchance = totalchance + n.chance
    end

    inst.loot = {}

    table.insert(inst.loot, "poop")

    inst.lootaggro = {}
    local next_loot = nil
    local next_aggro = nil
    local next_chance = nil
    local num_loots = 2
    while num_loots > 0 do
        next_chance = math.random()*totalchance
        next_loot = nil
        next_aggro = nil
        for m, n in ipairs(possible_loot) do
            next_chance = next_chance - n.chance
            if next_chance <= 0 then
                next_loot = n.item
                if n.aggro then next_aggro = true end
                break
            end
        end
        if next_loot ~= nil then
            table.insert(inst.loot, next_loot)
            if next_aggro then 
                table.insert(inst.lootaggro, true)
            else
                table.insert(inst.lootaggro, false)
            end
            num_loots = num_loots - 1
        end

    end
end

local function onburnt(inst)
    inst.components.pickable.canbepicked = false
    inst.components.propagator:StopSpreading()

    inst.Physics:Stop()
    inst.components.blowinwind:Stop()
    inst:RemoveEventCallback("animover", startmoving, inst)

    if inst.bouncepretask then
        inst.bouncepretask:Cancel()
        inst.bouncepretask = nil
    end
    if inst.bouncetask then
        inst.bouncetask:Cancel()
        inst.bouncetask = nil
    end
    if inst.restartmovementtask then
        inst.restartmovementtask:Cancel()
        inst.restartmovementtask = nil
    end
    if inst.bouncepst1 then
        inst.bouncepst1:Cancel()
        inst.bouncepst1 = nil
    end
    if inst.bouncepst2 then
        inst.bouncepst2:Cancel()
        inst.bouncepst2 = nil
    end

    inst.AnimState:PlayAnimation("move_pst")
    inst.AnimState:PushAnimation("idle")
    inst.bouncepst1 = inst:DoTaskInTime(4*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst1 = nil
    end)
    inst.bouncepst2 = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst2 = nil
    end)

    inst:DoTaskInTime(1.2, function(inst)
        local ash = SpawnPrefab("ash")
        ash.Transform:SetPosition(inst.Transform:GetWorldPosition())
        
        if inst.components.stackable then
            ash.components.stackable.stacksize = inst.components.stackable.stacksize
        end

        inst:Remove()
    end)
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    shadow:SetSize( 1.7, .8 )

    anim:SetBank("tumbleweed")
    anim:SetBuild("dungball_build")
    anim:PlayAnimation("idle")
    
    inst:AddTag("dungball") 

    MakeCharacterPhysics(inst, .5, 1)
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    inst.components.pickable.onpickedfn = onpickup
    inst.components.pickable.canbepicked = true
    inst.components.pickable.witherable = false

    MakeLoot(inst)

    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 5 + math.random()*3
    inst.components.propagator.propagaterange = 5

    inst:DoTaskInTime(0.03, function(x)
        x.Physics:Stop()
    end)

    return inst
end

return Prefab( "dungball", fn, assets, prefabs) 

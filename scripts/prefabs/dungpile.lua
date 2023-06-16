local assets =
{
    Asset("ANIM", "anim/dung_pile.zip"),
    Asset("MINIMAP_IMAGE", "dung_pile"), 
}

local prefabs =
{
	"dungbeetle",
    "cutgrass",
    "flint",
    "twigs",
    "boneshard",
    "rocks",
    "poop",
    "collapse_small",
}

local loots =
{
    {'poop', 1.00},
    {'rocks',   1.00},
    {'cutgrass',    0.05},
    {'boneshard', 0.2},
    {'flint', 0.05},
    {'twigs', 0.05},
}

RESETTIME = TUNING.TOTAL_DAY_TIME * 3
RANDTIME = TUNING.TOTAL_DAY_TIME 

local function spawndungball(inst)
    print("spawn dung")
    local ball = SpawnPrefab("dungball")
    ball.Transform:SetPosition(inst.Transform:GetWorldPosition())
    ball.AnimState:PlayAnimation("idle")
end


local function ondug(inst, worker)
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    local pt = Point(inst.Transform:GetWorldPosition())    
    

    if worker == ThePlayer  then
        for i=1, inst.components.pickable.cycles_left do   
            local loots = inst.components.lootdropper:GenerateLoot()
            inst.components.lootdropper:DropLoot(pt, loots)        
        end
    else
        spawndungball(inst)
    end

    inst.components.pickable:MakeBarren()    
end

local function onhit(inst)
    if not inst.playing_dead_anim then
        inst.AnimState:PlayAnimation("hit", false)
    end
end

local function OnEntityWake(inst)
    if inst.components.childspawner then
        inst.components.childspawner:StartSpawning()
    end
end

local function OnEntitySleep(inst)
end



local function makeemptyfn(inst)
    -- adjust art for empty
end

local function onpickedfn(inst, picker)
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    local loots = inst.components.lootdropper:GenerateLoot()
    local pt = Point(inst.Transform:GetWorldPosition())
    inst.components.lootdropper:DropLoot(pt, loots)

    if picker.components.sanity then
        if picker.components.talker and picker == ThePlayer then
            ThePlayer.components.talker:Say(GetString(ThePlayer.prefab, "ANNOUNCE_PICKPOOP"))
        end
        if picker:HasTag("plantkin") then
            picker.components.sanity:DoDelta(10)
        else
            picker.components.sanity:DoDelta(-10)
        end
    end

    if inst.components.pickable.cycles_left <= 0 then
        inst.components.pickable:MakeBarren()
    end
end

local function makefullfn(inst)
    if inst.components.pickable.cycles_left <= 0 then
        inst.components.workable:SetWorkLeft(1)
        inst:AddTag("dungpile")
        inst.AnimState:PlayAnimation("dead_to_idle")
        inst.AnimState:PushAnimation("idle")
    end
end

local function reset(inst)
    inst.components.workable:SetWorkLeft(1)
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
    inst.components.pickable.canbepicked = true
    inst:AddTag("dungpile")
    inst.AnimState:PlayAnimation("dead_to_idle")
    inst.AnimState:PushAnimation("idle")

    inst.task = nil
end

local function destroy(inst)
    local time_to_erode = 1
    local tick_time = TheSim:GetTickTime()

    if inst.DynamicShadow then
        inst.DynamicShadow:Enable(false)
    end

    inst:StartThread( function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            inst.AnimState:SetErosionParams( erode_amount, 0.1, 1.0 )
            ticks = ticks + 1
            Yield()
        end
        inst:Remove()
    end)
end

local function makebarrenfn(inst)
    inst.components.workable.workleft = 0
    inst.AnimState:PlayAnimation("idle_to_dead")
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    inst:RemoveTag("dungpile")

    inst.task, inst.taskinfo = inst:ResumeTask(RESETTIME + (math.random()*RANDTIME), function() reset(inst) end)
end

local function getregentimefn(inst)
    return 0
end

local function onsave(inst, data)
    if inst:HasTag("dungpile") then
        data.hasdung = true
    end
    if inst.taskinfo then
        data.timeleft = inst:TimeRemainingInTask(inst.taskinfo)
    end    
end

local function OnBurn(inst)
--    DefaultBurnFn(inst)
    if inst.flies then
        inst.flies:Remove()
        inst.flies = nil
    end   
end

local function onload(inst, data)
    if data then
        if data.hasdung then
            inst:AddTag("hasdung")
            inst.AnimState:PlayAnimation("idle")
        else
            inst:RemoveTag("hasdung")
            inst.AnimState:PlayAnimation("dead")
        end
        if data.timeleft then
            if inst.task then inst.task:Cancel() inst.task = nil end
            inst.taskinfo = nil
            inst.task, inst.taskinfo = inst:ResumeTask(data.timeleft, function() reset(inst) end)
        end        
    end
end

local function land(inst)    
    inst.AnimState:PlayAnimation("idle")
end

local function fall(inst)
    inst.AnimState:PlayAnimation("fall")
    inst:DoTaskInTime(10/30,function() inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/dung_pile") end)
    inst:DoTaskInTime(15/30,function()  TheCamera:Shake("VERTICAL", 0.3, 0.02, 0.5)  end)    
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:AddSoundEmitter()

	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "dung_pile.tex" )

	anim:SetBank("dung_pile")
	anim:SetBuild("dung_pile")
	anim:PlayAnimation("idle")

    inst:AddTag("dungpile")
    inst:AddTag("pick_digin")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(ondug)
    inst.components.workable:SetOnWorkCallback(onhit)       

    ---------------------
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"

    inst.components.pickable.getregentimefn = getregentimefn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makebarrenfn = makebarrenfn
    inst.components.pickable.makefullfn = makefullfn
    inst.components.pickable.max_cycles = 3
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
    inst.components.pickable:SetUp(nil,0)
    inst.components.pickable.transplanted = true
    -------------------
	inst:AddComponent("childspawner")
	inst.components.childspawner.childname = "dungbeetle"
	inst.components.childspawner:SetRegenPeriod(TUNING.CATCOONDEN_REGEN_TIME)
	inst.components.childspawner:SetSpawnPeriod(TUNING.CATCOONDEN_RELEASE_TIME)
	inst.components.childspawner:SetMaxChildren(1)
   -- inst.components.childspawner.canspawnfn = function(inst)
        
   -- end
 
    ---------------------
    inst:AddComponent("lootdropper")
    for i,v in pairs(loots) do
        inst.components.lootdropper:AddRandomLoot(v[1], v[2])
    end
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.speed = 2
    inst.components.lootdropper.alwaysinfront = true

    MakeMediumBurnable(inst)
    inst.components.burnable:SetOnIgniteFn(OnBurn)    
    MakeSmallPropagator(inst)

    ---------------------
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst, viewer)
        if not inst:HasTag("dungpile") then
            return "PICKED"
        end
    end

    inst:ListenForEvent("animover", function(inst, data)
        if anim:IsCurrentAnimation("idle_to_dead") then
            destroy(inst)
        end
        if anim:IsCurrentAnimation("fall") then
            land(inst)        
        end
    end)

    inst.flies = inst:SpawnChild("flies")
    inst.flies.Transform:SetScale(1.2,1.2,1.2)

    MakeSnowCovered(inst)

	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
    
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.fall = fall

	return inst
end

return Prefab( "dungpile", fn, assets, prefabs ) 


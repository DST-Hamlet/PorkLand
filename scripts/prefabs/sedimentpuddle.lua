local assets =
{
    Asset("ANIM", "anim/gold_puddle.zip"),
    Asset("MINIMAP_IMAGE", "gold_puddle"),
    Asset("ANIM", "anim/water_ring_fx.zip"),
    
}

local prefabs =
{
    "gold_dust",
}

local SAFE_EDGE_RANGE = 7
local SAFE_PUDDLE_RANGE = 7

local function getanim(inst, state)
    local size = "big"
    
    if inst.stage == 1 then
        size = "small"
    elseif inst.stage == 2 then
        size = "med"
    end

    return size .."_" .. state
end

local grow_anim_lookup_table = {"appear", "small_to_med", "med_to_big"}
local shrink_anim_lookup_table = {"disappear", "med_to_small", "big_to_med"}
local range_lookup_table = {0, 1.6, 2.6, 3.5}

local function SetStage(inst, stage, preanim)

    inst.stage = stage
    inst.components.workable:SetWorkLeft(stage)
    inst.components.ripplespawner:SetRange(range_lookup_table[stage + 1]) -- lua index starts at 1

    if stage > 0 then
        inst:Show()
        inst:RemoveTag("NOCLICK")
        inst.MiniMapEntity:SetEnabled(true)

        if preanim then
            inst.AnimState:PlayAnimation( preanim )
            inst.AnimState:PushAnimation( getanim(inst, "idle"), true )
        else		
            inst.AnimState:PlayAnimation( getanim(inst, "idle"), true )
        end	
    else
        inst.components.workable:SetWorkable(false)

        inst:AddTag("NOCLICK")
        inst.MiniMapEntity:SetEnabled(false)
        
        if preanim then
            inst.AnimState:PlayAnimation( preanim )
        else		
            inst.AnimState:PlayAnimation( getanim(inst, "idle"), true )
            inst:Hide()
        end	
    end
end

local function Grow(inst)
    if inst.pause then
        return
    end

    if inst.stage == 0 then		
        inst.water_collected = 0
    end

    inst:SetStage(inst.stage + 1, grow_anim_lookup_table[inst.stage +1])
end

local function Shrink(inst)
    if inst.stage == 1 then
        inst.water_collected = 0
    end

    inst:SetStage(inst.stage - 1, shrink_anim_lookup_table[inst.stage])
end

local function initialsetup(inst)
    if not inst.stage then
        inst:SetStage(math.random(0, 3))
    end
end

local function getnewwaterlimit(inst)
    return 36 + (math.random() * 8)  -- 36 * 5 = 180 seconds to go up one level .. 3 minutes of rain. 
end

local function collectrain(inst)
    if inst.pause then
        return
    end

    inst.water_collected = inst.water_collected + 1
    if inst.water_collected > inst.waterlimit then
        inst.water_collected = 0
        inst:Grow()
        inst.waterlimit = getnewwaterlimit(inst)
    end
end

local function generatetask(inst)
    inst.growtask = inst:DoPeriodicTask(5, function() collectrain(inst) end )
end

local function OnSave(inst, data)
    data.stage = inst.stage
    data.growing = inst.growing
    data.water_collected = inst.water_collected
    data.water_limit = inst.water_limit

    data.spawned = inst.spawned 
    data.rotation = inst.Transform:GetRotation()
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.stage = data.stage   
    inst:SetStage(inst.stage)

    inst.water_collected = data.water_collected
    inst.water_limit = data.water_limit

    inst.growing = data.growing
    if inst.growing then
        generatetask(inst)
    end

    if data.spawned then
        inst.spawned = true
    end

    if data.rotation then
        inst.Transform:SetRotation(data.rotation)
    end
end

local function startgrow(inst)
    if (inst.stage and inst.stage > 0) or math.random() < 0.2 then
        inst.growing = true
        generatetask(inst)
    end
end

local function stopgrow(inst)
    inst.growing = false
    if inst.growtask then
        inst.growtask:Cancel()
        inst.growtask = nil
    end
end


local function reposition(inst)

    local ground = GetWorld()

    local pt = Vector3(inst.Transform:GetWorldPosition())
    local tests = {}

    for i=1,8 do
        local angle = (i-1) * PI/4
        local offset = Vector3(SAFE_EDGE_RANGE * math.cos( angle ), 0, -SAFE_EDGE_RANGE * math.sin( angle ))			
        local tile = ground.Map:GetTileAtPoint(pt.x+offset.x, 0, pt.z+offset.z)
        table.insert(tests,tile)			
    end		

    local offsets = {}
    for i,tile in ipairs(tests)do
        if tile ~= GROUND.PAINTED then
            local angle = ((i -1)*PI/4) - PI
            local offset = Vector3(SAFE_EDGE_RANGE * math.cos( angle ), 0, -SAFE_EDGE_RANGE * math.sin( angle ))
            table.insert(offsets,offset)
        end
    end

    if #offsets > 0 then
        local offset = Vector3(0,0,0)
        for i,noffset in ipairs(offsets) do
            offset = offset + noffset
        end		
        offset.x = offset.x / #offsets
        offset.z = offset.z / #offsets
        
        pt.x = pt.x +offset.x					
        pt.y = pt.y +offset.y
        pt.z = pt.z +offset.z

        inst.Transform:SetPosition(pt.x,pt.y,pt.z) 			
    end

    inst.spawned = true

    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, SAFE_PUDDLE_RANGE, {"sedimentpuddle"})
     if #ents>1 then
        print("Overlapping other puddle. REMOVING")
        inst:Remove() 		
     end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("gold_puddle")
    inst.AnimState:SetBank("gold_puddle")
    inst.AnimState:PlayAnimation("big_idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.Transform:SetRotation(math.random()*360)

    inst:AddTag("sedimentpuddle")
    inst:AddTag("NOBLOCK")
    inst:AddTag("OnFloor")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.water_collected = 0
    inst.waterlimit  =  getnewwaterlimit(inst)

    inst.Shrink = shrink
    inst.Grow = grow	
    inst.SetStage = SetStage

    inst:AddComponent("lootdropper")

    inst:AddComponent("ripplespawner")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.PAN)
    inst.components.workable:SetWorkLeft(3)	
    inst.components.workable:SetOnWorkCallback(
        function(inst, worker, workleft)
            inst.components.lootdropper:SpawnLootPrefab("gold_dust")
            shrink(inst)			
        end)	

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon( "gold_puddle.png" )
    
    inst:AddComponent("inspectable")
    inst.no_wet_prefix = true

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad 

    inst:DoTaskInTime(0, function() initialsetup(inst) end) 

    inst:ListenForEvent("rainstart", function() startgrow(inst) end, GetWorld())	
    inst:ListenForEvent("rainstop", function()  stopgrow(inst) end, GetWorld())

    inst:ListenForEvent("animover", function(inst, data)
        if inst.AnimState:IsCurrentAnimation("disappear") then
            inst:Hide()
        end		
    end)

    inst:DoTaskInTime(0,function() 
            if not inst.spawned then 
                reposition(inst) 
            end 
        end)
    
    return inst
end

local function MakeRipple(speed)
    local function ripplefn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild("water_ring_fx")
        inst.AnimState:SetBank("water_ring_fx")
        inst.AnimState:PlayAnimation(speed)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetMultColour(1, 1, 1, 1)

        inst:AddTag("NOBLOCK")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end 
        
        inst.persists = false

        inst:ListenForEvent("animover", inst.Remove)
        inst:ListenForEvent("entitysleep", inst.Remove)

        return inst
    end

    return Prefab(string.format("puddle_ripple_%s_fx", speed), ripplefn, assets, prefabs)
end

return Prefab("sedimentpuddle", fn, assets, prefabs),
       MakeRipple("fast"),
       MakeRipple("slow")

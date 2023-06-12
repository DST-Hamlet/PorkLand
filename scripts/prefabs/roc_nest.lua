local assets =
{
    Asset("ANIM", "anim/roc_nest.zip"),
    Asset("ANIM", "anim/roc_junk.zip"),   
    Asset("ANIM", "anim/roc_egg_shells.zip"),    

    Asset("MINIMAP_IMAGE", "roc_junk_trunk"),    
    Asset("MINIMAP_IMAGE", "roc_junk_tree2"),    
    Asset("MINIMAP_IMAGE", "roc_junk_tree1"),    
    Asset("MINIMAP_IMAGE", "roc_junk_rusty_lamp"),    
    Asset("MINIMAP_IMAGE", "roc_junk_house"),    
    Asset("MINIMAP_IMAGE", "roc_junk_bush"),    
    Asset("MINIMAP_IMAGE", "roc_junk_branch2"),    
    Asset("MINIMAP_IMAGE", "roc_junk_branch1"),    
}

local prefabs = {
    "roc_robin_egg",
}

local rock_loot = {
    {"rocks",10},
    {"redgem",1},
    {"bluegem",1},
    {"purplegem",1},
} 

local tree_loot = {
    {"log",1}
} 
local branch_loot = {
    {"twigs",1}
}
local house_loot = {
    {"cut_stone",1},
    {"boards",1}
}
local lamp_loot = {
    {"iron",5},    
    {"transistor",1},    
}

local function onpickedfn(inst)
    inst:Remove()
end

local function onworked(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_"..inst.breaksoundsufix)
    inst:Remove()
end

local function onwork(inst, worker)
    inst.AnimState:PlayAnimation(inst.animname.."_hit")
    inst.AnimState:PushAnimation(inst.animname)

    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")  
end

local function onsave(inst, data)    
    local references = {}
    data.rotation = inst.Transform:GetRotation()
    return references
end

local function onload(inst, data)
    if data and data.rotation then
        inst.rotation = data.rotation
        inst.Transform:SetRotation(data.rotation)
    end
end

local function workable(file, anim, action, loot, lootmax, minimap, eightfaced, breaksoundsufix)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank(file)
    inst.AnimState:SetBuild(file)
    inst.AnimState:PlayAnimation(anim)

    inst.animname = anim
    inst.breaksoundsufix = breaksoundsufix or "wood"

    if minimap then
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(minimap)
    end

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    if action == ACTIONS.HAMMER or action == ACTIONS.CHOP or action == ACTIONS.MINE then
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(action)
        inst.components.workable:SetWorkLeft(3)
        inst.components.workable:SetOnFinishCallback(onworked)

        inst.components.workable:SetOnWorkCallback(onwork)
    elseif  action == ACTIONS.PICK then
        inst:AddComponent("pickable")
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"        
        inst.components.pickable:SetUp(type(loot) ~= "table" and loot or "cutgrass")
		inst.components.pickable.remove_when_picked = true
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    if loot and type(loot) == "table" then
        for i, lootset in ipairs(loot) do
            inst.components.lootdropper:AddRandomLoot(lootset[1], lootset[2])
        end
    end
    if lootmax then
        inst.components.lootdropper.numrandomloot = lootmax
    end

    if eightfaced then
        inst.Transform:SetEightFaced()

        inst:DoTaskInTime(0,function() 
            if not inst.rotation then
                local pt = Point(inst.Transform:GetWorldPosition())
                local ent = TheSim:FindFirstEntityWithTag("roc_nest")

                if ent then
                    local pt2 = Point(ent.Transform:GetWorldPosition())
                    local angle = inst:GetAngleToPoint(pt2)
                    inst.Transform:SetRotation(angle)
                end
            end
        end)     
        inst.OnSave = onsave 
        inst.OnLoad = onload
    end

    return inst
end

local function nest()  
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    inst.AnimState:SetBank("roc_nest")
    inst.AnimState:SetBuild("roc_nest")
    inst.AnimState:PlayAnimation("nest_decal")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND )
    inst.AnimState:SetSortOrder( 3 )    

    inst:AddTag("roc_nest")
    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")
    
    return inst
end

return Prefab("roc_nest", nest, assets, prefabs),
    
    Prefab("roc_nest_egg1",       function() return workable("roc_egg_shells",  "shell1", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone") end, assets, prefabs ),
    Prefab("roc_nest_egg2",       function() return workable("roc_egg_shells",  "shell2", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone") end, assets, prefabs ),
    Prefab("roc_nest_egg3",       function() return workable("roc_egg_shells",  "shell3", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone") end, assets, prefabs ),
    Prefab("roc_nest_egg4",       function() return workable("roc_egg_shells",  "shell4", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone") end, assets, prefabs ),

    Prefab("roc_nest_tree1",      function() return workable("roc_junk", "tree1",      ACTIONS.CHOP, tree_loot,    1, "roc_junk_tree1.tex"                    ) end, assets, prefabs ),
    Prefab("roc_nest_tree2",      function() return workable("roc_junk", "tree2",      ACTIONS.CHOP, tree_loot,    1, "roc_junk_tree2.tex"                    ) end, assets, prefabs ),
    Prefab("roc_nest_bush",       function() return workable("roc_junk", "bush",       ACTIONS.PICK, "cutgrass", nil, "roc_junk_bush.tex"                     ) end, assets, prefabs ),
    Prefab("roc_nest_branch1",    function() return workable("roc_junk", "branch1",    ACTIONS.CHOP, branch_loot,  1, "roc_junk_branch1.tex"                  ) end, assets, prefabs ),
    Prefab("roc_nest_branch2",    function() return workable("roc_junk", "branch2",    ACTIONS.CHOP, branch_loot,  1, "roc_junk_branch2.tex"                  ) end, assets, prefabs ),
    Prefab("roc_nest_trunk",      function() return workable("roc_junk", "trunk",      ACTIONS.CHOP, tree_loot,    1, "roc_junk_trunk.tex"                    ) end, assets, prefabs ),
    Prefab("roc_nest_house",      function() return workable("roc_junk", "house",      ACTIONS.HAMMER, house_loot, 3, "roc_junk_house.tex",      nil, "stone" ) end, assets, prefabs ),
    Prefab("roc_nest_rusty_lamp", function() return workable("roc_junk", "rusty_lamp", ACTIONS.HAMMER, lamp_loot,  2, "roc_junk_rusty_lamp.tex", nil, "metal" ) end, assets, prefabs ),

    Prefab("roc_nest_debris1",    function() return workable("roc_junk", "stick01",    ACTIONS.PICK, "twigs", 1, nil, true) end, assets, prefabs ),
    Prefab("roc_nest_debris2",    function() return workable("roc_junk", "stick02",    ACTIONS.PICK, "twigs", 1, nil, true) end, assets, prefabs ),
    Prefab("roc_nest_debris3",    function() return workable("roc_junk", "stick03",    ACTIONS.PICK, "twigs", 1, nil, true) end, assets, prefabs ),
    Prefab("roc_nest_debris4",    function() return workable("roc_junk", "stick04",    ACTIONS.PICK, "twigs", 1, nil, true) end, assets, prefabs )
 
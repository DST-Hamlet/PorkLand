local assets =
{
    Asset("ANIM", "anim/roc_nest.zip"),
    Asset("ANIM", "anim/roc_junk.zip"),
    Asset("ANIM", "anim/roc_egg_shells.zip"),
}

local prefabs = {
    "roc_robin_egg",
}

local rock_loot = {
    {"rocks", 10},
    {"redgem", 1},
    {"bluegem", 1},
    {"purplegem", 1},
}

local tree_loot = {
    {"log", 1}
}
local branch_loot = {
    {"twigs", 1}
}
local house_loot = {
    {"cut_stone", 1},
    {"boards", 1}
}
local lamp_loot = {
    {"iron", 5},
    {"transistor", 1},
}

local function onpickedfn(inst)
    inst:Remove()
end

local function OnWorkCallback(inst, worker)
    inst.AnimState:PlayAnimation(inst.animname .. "_hit")
    inst.AnimState:PushAnimation(inst.animname)

    if inst.action_type and inst.action_type == ACTIONS.CHOP then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end
end

local function OnFinishCallback(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial(inst.material or "wood")

    inst:Remove()
end

local function OnSave(inst, data)
    data.rotation = inst.Transform:GetRotation()
end

local function OnLoad(inst, data)
    if data and data.rotation then
        inst.rotation = data.rotation
        inst.Transform:SetRotation(data.rotation)
    end
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
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("roc_nest")
    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function MakeDecor(name, build, anim, action, loot, numrandomloot, minimap_icon, eight_faced, material)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        if minimap_icon then
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon(minimap_icon)
        end

        if eight_faced then
            inst.Transform:SetEightFaced()
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.action_type = action

        if action == ACTIONS.HAMMER or action == ACTIONS.CHOP or action == ACTIONS.MINE then
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(action)
            inst.components.workable:SetWorkLeft(3)
            inst.components.workable:SetOnFinishCallback(OnFinishCallback)
            inst.components.workable:SetOnWorkCallback(OnWorkCallback)
        elseif action == ACTIONS.PICK then
            inst:AddComponent("pickable")
            inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
            inst.components.pickable:SetUp(type(loot) ~= "table" and loot or "cutgrass")
            inst.components.pickable.onpickedfn = onpickedfn
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        if loot and type(loot) == "table" then
            for i, lootset in ipairs(loot) do
                inst.components.lootdropper:AddRandomLoot(lootset[1], lootset[2])
            end
        end
        if numrandomloot then
            inst.components.lootdropper.numrandomloot = numrandomloot
        end

        if eight_faced then
            -- face towards the nest
            inst:DoTaskInTime(0, function()
                if inst.rotation then
                    return
                end

                local roc_nest = TheSim:FindFirstEntityWithTag("roc_nest")

                if roc_nest then
                    local roc_nest_pos = roc_nest:GetPosition()
                    local angle = inst:GetAngleToPoint(roc_nest_pos)
                    inst.Transform:SetRotation(angle)
                end
            end)

            inst.OnSave = OnSave
            inst.OnLoad = OnLoad
        end

        inst.animname = anim
        inst.material = material or "wood"

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return Prefab("roc_nest", nest, assets, prefabs),

    MakeDecor("roc_nest_egg1", "roc_egg_shells", "shell1", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone"),
    MakeDecor("roc_nest_egg2", "roc_egg_shells", "shell2", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone"),
    MakeDecor("roc_nest_egg3", "roc_egg_shells", "shell3", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone"),
    MakeDecor("roc_nest_egg4", "roc_egg_shells", "shell4", ACTIONS.MINE, rock_loot, 3, nil, nil, "stone"),

    MakeDecor("roc_nest_tree1", "roc_junk", "tree1", ACTIONS.CHOP, tree_loot, 1, "roc_junk_tree1.tex"),
    MakeDecor("roc_nest_tree2", "roc_junk", "tree2", ACTIONS.CHOP, tree_loot, 1, "roc_junk_tree2.tex"),
    MakeDecor("roc_nest_bush", "roc_junk", "bush", ACTIONS.PICK, "cutgrass", nil, "roc_junk_bush.tex"),
    MakeDecor("roc_nest_branch1", "roc_junk", "branch1", ACTIONS.CHOP, branch_loot, 1, "roc_junk_branch1.tex"),
    MakeDecor("roc_nest_branch2", "roc_junk", "branch2", ACTIONS.CHOP, branch_loot, 1, "roc_junk_branch2.tex"),
    MakeDecor("roc_nest_trunk", "roc_junk", "trunk", ACTIONS.CHOP, tree_loot, 1, "roc_junk_trunk.tex"),
    MakeDecor("roc_nest_house", "roc_junk", "house", ACTIONS.HAMMER, house_loot, 3, "roc_junk_house.tex", nil, "stone"),
    MakeDecor("roc_nest_rusty_lamp", "roc_junk", "rusty_lamp", ACTIONS.HAMMER, lamp_loot, 2, "roc_junk_rusty_lamp.tex", nil, "metal"),

    MakeDecor("roc_nest_debris1", "roc_junk", "stick01", ACTIONS.PICK, "twigs", 1, nil, true ),
    MakeDecor("roc_nest_debris2", "roc_junk", "stick02", ACTIONS.PICK, "twigs", 1, nil, true ),
    MakeDecor("roc_nest_debris3", "roc_junk", "stick03", ACTIONS.PICK, "twigs", 1, nil, true ),
    MakeDecor("roc_nest_debris4", "roc_junk", "stick04", ACTIONS.PICK, "twigs", 1, nil, true )

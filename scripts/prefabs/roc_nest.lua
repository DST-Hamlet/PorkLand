--没有燃烧动画就不加燃烧组件
--roc_junk中的branch_stump动画需要改
local assets =
{
    Asset("ANIM", "anim/roc_nest.zip"),
    Asset("ANIM", "anim/roc_junk.zip"),
    Asset("ANIM", "anim/roc_egg_shells.zip"),
}

local prefablist = {}

local preset_data = {
    egg = {
        bank = "roc_egg_shells",
        action = "mine",
        sound = "stone",
        workanim = "_hit",
        workedanim = "",
        afterworkanim = "_broken",
        workleft = 3,

        has_second_stage = true,
        second_action = "mine",
        second_workleft = 3,
        second_loot = {
            { "rocks",     10 },
            { "redgem",    1 },
            { "bluegem",   1 },
            { "purplegem", 1 },
        },
        second_lootmax = 3,


    },

    house = {
        bank = "roc_junk",
        action = "hammer",
        sound = "wood",
        workanim = "_hit",
        workedanim = "",
        afterworkanim = "_debris",
        workleft = 3,

        has_second_stage = true,
        second_action = "hammer",
        second_workleft = 3,
        second_loot = {
            { "cutstone", 1 }, --不是cut_stone
            { "boards",   1 }
        },
        second_lootmax = 3,
        second_workanim = "",
        second_workedanim = "",
    },

    lamp = {
        bank = "roc_junk",
        action = "hammer",
        sound = "metal",
        workanim = "_hit",
        workedanim = "",
        afterworkanim = "_debris",
        workleft = 3,

        has_second_stage = true,
        second_action = "hammer",
        second_workleft = 3,
        second_loot = {
            { "iron",       5 },
            { "transistor", 1 }
        },
        second_lootmax = 2,
        second_workanim = "",
        second_workedanim = "",
    },

    bush = {
        bank = "roc_junk",
        twofaced = true,
        action = "pick",
        -- sound = "metal",
        workanim = "_hit",
        workedanim = "",
        workfx = true,
        afterworkanim = "_debris",

        loot = "cutgrass", --pick是名称，action是表,

        -- has_second_stage = true, --加上二阶段需要添加动画
        -- second_action = "dig",
        -- second_loot = {
        --     { "cutgrass", 1 }
        -- },
        -- second_lootmax = 1,
        -- second_workanim = "",
        -- second_workedanim = "",
    },

    stick = {
        bank = "roc_junk",
        eightfaced = true,
        action = "pick",
        -- sound = "metal",
        workanim = "",
        workedanim = "",
        afterworkanim = "_debris",

        loot = "twigs",

    },

    trunk = {
        bank = "roc_junk",
        action = "chop",
        -- sound = "metal",
        workanim = "_hit",
        workedanim = "",
        afterworkanim = "_debris",
        workleft = 3,

        loot = {
            { "log", 1 }
        },
        lootmax = 1,

        has_second_stage = true,
        second_action = "dig",
        second_loot = {
            { "log", 1 }
        },
        second_lootmax = 1,
        second_workanim = "",
        second_workedanim = "",
    },



    tree = {
        bank = "roc_junk",
        twofaced = true,

        action = "chop",
        -- sound = "metal",
        workanim = "_hit",
        workedanim = "_fall",
        workfx = true,
        afterworkanim = "_stump",
        workleft = 3,

        loot = {
            { "log", 1 }
        },
        lootmax = 1,

        has_second_stage = false,
        second_action = "dig",
        second_loot = {
            { "log", 1 } --没搞懂为什么会出树枝
        },
        second_lootmax = 1,
        second_workanim = "",
        second_workedanim = "",
    },

    branch = {
        bank = "roc_junk",
        twofaced = true,

        action = "chop",
        -- sound = "metal",
        workanim = "_hit",
        workedanim = "_fall",
        afterworkanim = "_stump", --这个阶段的动画需要修正，或者就需要隐藏一个部件
        workleft = 3,

        loot = {
            { "twigs", 1 }
        },
        lootmax = 1,

        has_second_stage = false,
        second_action = "dig",
        second_loot = {
            { "log", 1 }
        },
        second_lootmax = 1,
        second_workanim = "",
        second_workedanim = "",
    },
}

local function insert_indexes(tbl, vs) --这会是一个很有用的工具函数，建议加在utils里
    local tbl_new = deepcopy(tbl)
    local vs_new = deepcopy(vs)
    for i, v in pairs(vs_new) do
        tbl_new[i] = v
    end
    return tbl_new
end

local prefabdata = {
    roc_nest_egg1 = insert_indexes(preset_data.egg, { anim = "shell1" }),
    roc_nest_egg2 = insert_indexes(preset_data.egg, { anim = "shell2" }),
    roc_nest_egg3 = insert_indexes(preset_data.egg, { anim = "shell3" }),
    roc_nest_egg4 = insert_indexes(preset_data.egg, { anim = "shell4" }),
    roc_nest_house = insert_indexes(preset_data.house, { anim = "house", minimap = "roc_junk_house.tex" }),
    roc_nest_rusty_lamp = insert_indexes(preset_data.lamp, { anim = "rusty_lamp", minimap = "roc_junk_rusty_lamp.tex" }),

    roc_nest_bush = insert_indexes(preset_data.bush, { anim = "bush", minimap = "roc_junk_bush.tex" }),
    roc_nest_trunk = insert_indexes(preset_data.trunk, { anim = "trunk", minimap = "roc_junk_trunk.tex" }),
    roc_nest_debris1 = insert_indexes(preset_data.stick, { anim = "stick01" }),
    roc_nest_debris2 = insert_indexes(preset_data.stick, { anim = "stick02" }),
    roc_nest_debris3 = insert_indexes(preset_data.stick, { anim = "stick03" }),
    roc_nest_debris4 = insert_indexes(preset_data.stick, { anim = "stick04" }),
    roc_nest_tree1 = insert_indexes(preset_data.tree, { anim = "tree1", minimap = "roc_junk_tree1.tex" }),
    roc_nest_tree2 = insert_indexes(preset_data.tree, { anim = "tree2", minimap = "roc_junk_tree2.tex" }),
    roc_nest_branch1 = insert_indexes(preset_data.branch, { anim = "branch1", minimap = "roc_junk_branch1.tex" }),
    roc_nest_branch2 = insert_indexes(preset_data.branch, { anim = "branch2", minimap = "roc_junk_branch2.tex" }),
}


local function onsave(inst, data)
    data.rotation = inst.Transform:GetRotation()
    data.in_second_stage = inst.in_second_stage or nil
end


local function onload(inst, data)
    if data and data.rotation then
        inst.rotation = data.rotation
        inst.Transform:SetRotation(data.rotation)
    end

    if data and data.in_second_stage then
        inst.in_second_stage = data.in_second_stage
        inst.anim = inst.anim .. inst.afterworkanim
        inst.workanim = inst.second_workanim or ""
        inst.action = inst.second_action
        inst.loot = inst.second_loot
        inst.lootmax = inst.second_lootmax
        inst.workleft = inst.second_workleft or 1
    end
end


local workfn_list = {}
local setworkfn_list = {}


local function updatestage(inst)
    if inst.action == "pick" then
        inst.AnimState:PlayAnimation(inst.anim .. inst.workanim)
        if inst.workfx == true then --一点特效
            SpawnPrefab("tree_petal_fx_chop").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    else
        inst.AnimState:PlayAnimation(inst.anim .. inst.workedanim)
    end

    if inst.has_second_stage and not inst.in_second_stage then
        inst.AnimState:PushAnimation(inst.anim .. inst.afterworkanim)

        inst.in_second_stage = true
        inst.anim = inst.anim .. inst.afterworkanim
        inst.workanim = inst.second_workanim or ""
        inst.action = inst.second_action
        inst.loot = inst.second_loot
        inst.lootmax = inst.second_lootmax
        inst.workleft = inst.second_workleft or 1

        if inst.second_action == "pick" then
            setworkfn_list.pick(inst, inst.action)
        else
            setworkfn_list.work(inst, inst.action)
        end
    else
        inst:DoTaskInTime(0.1, function() inst:Remove() end) --0.1最佳，或者重新搓动画
    end
end


workfn_list = {
    pick = {
        onworked = function(inst)
            updatestage(inst)
        end,
    },

    work = {
        onwork = function(inst, worker)
            inst.AnimState:PlayAnimation(inst.anim .. inst.workanim)
            inst.AnimState:PushAnimation(inst.anim)
            if inst.action == "chop" then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree") --为什么只有砍树需要加声音啊。。。
                if inst.workfx == true then                                   --一点特效
                    SpawnPrefab("tree_petal_fx_chop").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end
            -- inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
        end,
        onworked = function(inst, worker)
            if inst.loot then
                inst.components.lootdropper:DropLoot()
            end

            if (inst.action == "hammer" or inst.action == "mine") and (not inst.has_second_stage or inst.in_second_stage) then
                SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
                inst.SoundEmitter:PlaySound("dontstarve/common/destroy_" .. inst.sound)
            end

            updatestage(inst)
        end,
    }
}

setworkfn_list = {
    pick = function(inst)
        if not inst.components.pickable then
            inst:AddComponent("pickable")
        end

        if inst.components.workable then
            inst:RemoveComponent("workable")
        end

        if not inst.components.lootdropper then
            inst:AddComponent("lootdropper")
        end

        -- inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
        inst.components.pickable:SetUp(inst.loot)
        inst.components.pickable.onpickedfn = workfn_list.pick.onworked
    end,

    work = function(inst)
        if inst.components.pickable then
            inst:RemoveComponent("pickable")
        end

        if not inst.components.workable then
            inst:AddComponent("workable")
        end

        if not inst.components.lootdropper then
            inst:AddComponent("lootdropper")
        end

        inst.components.workable:SetWorkAction(ACTIONS[string.upper(inst.action)])
        inst.components.workable:SetWorkLeft(inst.workleft)
        inst.components.workable:SetOnFinishCallback(workfn_list.work.onworked)
        inst.components.workable:SetOnWorkCallback(workfn_list.work.onwork)

        if inst.loot then
            for i, lootset in ipairs(inst.loot) do
                inst.components.lootdropper:AddRandomLoot(lootset[1], lootset[2])
            end
        end

        if inst.lootmax then
            inst.components.lootdropper.numrandomloot = inst.lootmax
        end
    end,

}



local function commonfn(bank, minimap)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(bank)
    -- inst.AnimState:PlayAnimation(anim)

    if minimap then
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(minimap)
    end

    inst.entity:SetPristine()
    return inst
end


--roc_nest
local function nest()
    local inst = commonfn("roc_nest")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:PlayAnimation("nest_decal")
    inst:AddTag("roc_nest")
    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")

    return inst
end


table.insert(prefablist, Prefab("roc_nest", nest, assets))


--workable items
local function workable_item(data)
    local inst = commonfn(data.bank, data.minimap)

    for i, v in pairs(data) do
        inst[i] = data[i]
    end


    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:DoTaskInTime(0, function()
        if inst.eightfaced then --就动画来看改为fourfaced比较合理
            inst.Transform:SetEightFaced()


            if not inst.rotation then
                local pt = Point(inst.Transform:GetWorldPosition())
                local ent = TheSim:FindFirstEntityWithTag("roc_nest")

                if ent then
                    local pt2 = Point(ent.Transform:GetWorldPosition())
                    local angle = inst:GetAngleToPoint(pt2)
                    inst.Transform:SetRotation(angle)
                end
            end
        elseif inst.twofaced then
            inst.Transform:SetTwoFaced()
            inst.Transform:SetRotation(inst.rotation or math.random(360)) --给一个随机角度
        end


        inst.AnimState:PlayAnimation(inst.anim)
        if inst.action == "pick" then
            setworkfn_list.pick(inst)
        else
            setworkfn_list.work(inst)
        end
    end)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

for name, data in pairs(prefabdata) do
    table.insert(prefablist, Prefab(name, function() return workable_item(prefabdata[name]) end, assets))
end




return unpack(prefablist)

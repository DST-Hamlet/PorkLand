SetSharedLootTable("ruins_artichoke", {
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"nitre",  0.25},
    {"nitre",  0.25},
    {"flint",  0.60},
    {"flint",  0.60},
    {"gold_dust",  0.60},
})

SetSharedLootTable("ruins_pig", {
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"nitre",  0.25},
    {"flint",  0.60},
    {"gold_dust",  0.60},
    {"pigghost", 0.2},
})

SetSharedLootTable("ruins_giant_head", {
    {"gold_dust", 0.2},
    {"gold_dust", 0.2},
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"nitre",  0.25},
    {"nitre",  0.25},
    {"flint",  0.60},
    {"flint",  0.60},
    {"pigghost", 0.2},
})

SetSharedLootTable("antqueen_throne", {
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},
    {"rocks", 1.0},

    {"flint",  1.0},
    {"flint",  1.0},
    {"flint",  0.8},
    {"flint",  0.8},
    {"flint",  0.8},
    {"flint",  0.8},

    {"nitre",  0.8},
    {"nitre",  0.8},
    {"nitre",  0.8},
    {"nitre",  0.8},

    {"gold_dust", 0.6},
    {"gold_dust", 0.6},

    {"goldnugget", 1.0},
    {"goldnugget", 1.0},
    {"goldnugget", 0.3},
    {"goldnugget", 0.3},

    {"bluegem", 0.5},
    {"bluegem", 0.5},
})

SetSharedLootTable("basalt",{
    {"rocks",  1.00},
    {"rocks",  1.00},
    {"rocks",  0.50},
    {"flint",  1.00},
    {"flint",  0.30},
})

local function TriggerDarts(inst)
    local pt = inst:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 40, {"dartthrower"}, {"INLIMBO"})
    for i, v in ipairs(ents) do
        if v.components.autodartthrower then
            v.components.autodartthrower:TurnOn()
        elseif v.shoot ~= nil then
            v.shoot(v)
        end
    end
end

local function DislodgeOnLoad(inst, data)
    inst.AnimState:PlayAnimation("extract_success")
    inst.components.named:SetName(STRINGS.NAMES.PIG_RUINS_EXTRACTED)
end

local function OnSave(inst, data)
    if inst:HasTag("trggerdarttraps") then
        data.trggerdarttraps = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.trggerdarttraps then
            inst:AddTag("trggerdarttraps")
        end
    end
end

local function OnDislodged(inst)
    if inst:HasTag("trggerdarttraps") then
        TriggerDarts(inst)
    end
    DislodgeOnLoad(inst)
end

local function CanBeDislodgedFn(inst)
    return inst.components.workable ~= nil and inst.components.workable.workleft >= TUNING.ROCKS_MINE*(2/3)
end

local function OnWorkCallback(inst, worker, workleft)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        if inst:HasTag("trggerdarttraps") then
            TriggerDarts(inst)
        end

        SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
        inst.components.lootdropper:DropLoot(pt)
        --[[
        if inst:HasTag("mystery") and inst.components.mystery.investigated then
            inst.components.lootdropper:SpawnLootPrefab(inst.components.mystery.reward)
            inst:RemoveTag("mystery")
        end
        ]]
        inst:Remove()
    else
        if workleft < TUNING.ROCKS_MINE*(1/3) then
            inst.AnimState:PlayAnimation("low")
        elseif workleft < TUNING.ROCKS_MINE*(2/3) then
            inst.AnimState:PlayAnimation("med")
        else
            if not inst.components.dislodgeable or inst.components.dislodgeable:CanBeDislodged() then
                inst.AnimState:PlayAnimation("full")
            else
                inst.AnimState:PlayAnimation("extract_success")
            end
        end
    end
end

local function MakeRuin(name, data)
    local assets = {
        data.assets
    }

    local prefabs = {
        "rocks",
        "nitre",
        "flint",
        "pigghost",
        "gold_dust",
    }
    if data.loot then
        table.insert(prefabs, data.loot)
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, data.rad or 1)

        if data.minimapicon then
            inst.MiniMapEntity:SetIcon(data.minimapicon .. ".tex")
        end

        inst.AnimState:SetBank(data.bank)
        inst.AnimState:SetBuild(data.build)
        inst.AnimState:PlayAnimation("full")

        MakeSnowCoveredPristine(inst)

        inst:AddTag("boulder")

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -- inst:AddComponent("mystery")
        inst:AddComponent("named")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable(data.loot_table or 'ruins_pig')

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
        inst.components.workable:SetOnWorkCallback(OnWorkCallback)

        inst:AddComponent("dislodgeable")
        inst.components.dislodgeable:SetUp(data.loot, data.loot_num)
        inst.components.dislodgeable:SetOnDislodgedFn(OnDislodged)
        inst.components.dislodgeable:SetCanBeDislodgedFn(CanBeDislodgedFn)
        inst.components.dislodgeable:SetOnLoadFn(DislodgeOnLoad)

        local color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:AddComponent("inspectable")
        -- inst.components.inspectable.nameoverride = "ROCK"

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        MakeSnowCovered(inst)
        MakeHauntable(inst)

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end
    return Prefab(name, fn, assets, prefabs)
end

local function ShineTask(inst)
       if inst.components.dislodgeable and inst.components.dislodgeable:CanBeDislodged() then
           inst.AnimState:PlayAnimation("sparkle")
           inst.AnimState:PushAnimation("full")
       end

    if inst.entity:IsAwake() then
        inst.task = inst:DoTaskInTime(4+math.random()*5, ShineTask)
    end
end

local function OnEntityWake(inst)
    if inst.task == nil then
        inst.task = inst:DoTaskInTime(4+math.random()*5, ShineTask)
    end
end

local function OnRemoveEntity(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local ruin_data = {
    pig_ruins_head = {
        assets = Asset("ANIM", "anim/ruins_giant_head.zip"),
        bank = "pig_ruins_head",
        build = "ruins_giant_head",
        minimapicon = "ruins_giant_head",
        loot = "relic_3",
        loot_table = "ruins_giant_head",
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])
        end
    },
    pig_ruins_pig = {
        assets = Asset("ANIM", "anim/statue_pig_ruins_pig.zip"),
        bank = "statue_pig_ruins_pig",
        build = "statue_pig_ruins_pig",
        minimapicon = "statue_pig_ruins_pig",
        loot = "goldnugget",
        loot_num = 2,
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_PIG"])
            inst.OnEntityWake = OnEntityWake
            inst.OnRemoveEntity = OnRemoveEntity
        end
    },
    pig_ruins_ant = {
        assets = Asset("ANIM", "anim/statue_pig_ruins_ant.zip"),
        bank = "statue_pig_ruins_ant",
        build = "statue_pig_ruins_ant",
        minimapicon = "statue_pig_ruins_ant",
        loot = "goldnugget",
        loot_num = 2,
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])
            inst.OnEntityWake = OnEntityWake
            inst.OnRemoveEntity = OnRemoveEntity
        end
    },
    pig_ruins_idol = {
        assets = Asset("ANIM", "anim/statue_pig_ruins_idol.zip"),
        rad = 0.75,
        bank = "statue_pig_ruins_idol",
        build = "statue_pig_ruins_idol",
        minimapicon = "statue_pig_ruins_idol",
        loot = "relic_1",
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_IDOL"])
        end
    },
    pig_ruins_plaque = {
        assets = Asset("ANIM", "anim/statue_pig_ruins_plaque.zip"),
        rad = 0.75,
        bank = "statue_pig_ruins_plaque",
        build = "statue_pig_ruins_plaque",
        minimapicon = "statue_pig_ruins_plaque",
        loot = "relic_2",
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_PLAQUE"])
        end
    },
    pig_ruins_artichoke = {
        assets = Asset("ANIM", "anim/ruins_artichoke.zip"),
        bank = "ruins_artichoke",
        build = "ruins_artichoke",
        minimapicon = "ruins_artichoke",
        loot_table = "ruins_artichoke",
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_ARTICHOKE"])
            inst:RemoveComponent("dislodgeable")
        end
    },
    pig_ruins_truffle = {
        assets = Asset("ANIM", "anim/statue_pig_ruins_mushroom.zip"),
        rad = 0.75,
        bank = "statue_pig_ruins_mushroom",
        build = "statue_pig_ruins_mushroom",
        minimapicon = "statue_pig_ruins_mushroom",
        loot = "relic_5",
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_MUSHROOM"])
            inst.components.inspectable.nameoverride = "PIG_RUINS_MUSHROOM"
        end
    },
    pig_ruins_sow = {
        assets = Asset("ANIM", "anim/statue_pig_ruins_idol_blue.zip"),
        rad = 0.75,
        bank = "statue_pig_ruins_idol_blue",
        build = "statue_pig_ruins_idol_blue",
        minimapicon = "statue_pig_ruins_idol_blue",
        loot = "relic_4",
        master_postinit = function(inst)
            inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_SOW"])
        end
    },
    rock_basalt = {
        assets = Asset("ANIM", "anim/rock_basalt.zip"),
        bank = "rock_basalt",
        build = "rock_basalt",
        loot_table = "basalt",
        common_postinit = function(inst)
            inst.MiniMapEntity:SetIcon("rock.png")
        end,
        master_postinit = function(inst)
            inst:RemoveComponent("dislodgeable")
            inst.components.inspectable.nameoverride = "ROCK"
        end
    },
    antqueen_throne = {
        assets = Asset("ANIM", "anim/throne.zip"),
        rad = 3.5,
        bank = "throne",
        build = "throne",
        minimapicon = "ruins_artichoke",
        loot_table = "antqueen_throne",
        common_postinit = function(inst)
            inst.Transform:SetScale(0.9, 0.9, 0.9)
        end,
        master_postinit = function(inst)
            inst:RemoveComponent("dislodgeable")
            inst.components.named:SetName(STRINGS.NAMES["ANTQUEEN_THRONE"])
            inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_GIANT)
            inst:ListenForEvent("onremove", function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, 10, {"throne_wall"})
                for _, v in pairs(ents) do
                    v:Remove()
                end
            end)
        end
    }
}

local rets = {}
for k, v in pairs(ruin_data) do
    table.insert(rets, MakeRuin(k, v))
end

return unpack(rets)

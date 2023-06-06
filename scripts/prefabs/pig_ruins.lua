local ruins_assets = {
	Asset("ANIM", "anim/ruins_giant_head.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_pig.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_ant.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_idol.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_plaque.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_mushroom.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_idol_blue.zip"),
}

local prefabs = {
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "relic_3",
    "pigghost",
}

SetSharedLootTable('ruins_pig',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'flint',  0.60},
    {'gold_dust',  0.60},
    {'pigghost', 0.2},
})

SetSharedLootTable('ruins_gianthead',
{
	{'gold_dust', 0.2},
	{'gold_dust', 0.2},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'nitre',  0.25},
    {'flint',  0.60},
    {'flint',  0.60},
    {'pigghost', 0.2},
})

-- 触发机关
local function TriggerDarts(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local MUST_TAGS = {"dartthrower"}
    local CANT_TAGS = {"INTERIOR_LIMBO"}
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, MUST_TAGS, CANT_TAGS)
    for _, ent in ipairs(ents) do
        if ent.components.autodartthrower ~= nil then
    		ent.components.autodartthrower:TurnOn()
    	elseif ent.StartShoot ~= nil then
            ent.StartShoot(ent)
        end
    end
end

local function SetDislodged(inst)
	inst.dislodged = true
	inst.AnimState:PlayAnimation("extract_success")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_EXTRACTED"])
end

-- 当物品被取下触发
local function OnDislodged(inst)
	if inst:HasTag("trggerdarttraps") then
        TriggerDarts(inst)
    end
    SetDislodged(inst)
end

local function OnSave(inst, data)
	if inst:HasTag("trggerdarttraps") then
		data.trggerdarttraps = true
	end

    data.workleft = inst.components.workable.workleft

	if inst.dislodged ~= nil then
		data.dislodged = true
	end
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.trggerdarttraps ~= nil then
			inst:AddTag("trggerdarttraps")
		end

        if data.workleft ~= nil then
            inst.components.workable:SetWorkLeft(data.workleft)
            if data.workleft < TUNING.ROCKS_MINE*(1/3) then
                inst.AnimState:PlayAnimation("low")
                inst.components.dislodgeable:SetDislodged()
            elseif data.workleft < TUNING.ROCKS_MINE*(2/3) then
                inst.AnimState:PlayAnimation("med")
                inst.components.dislodgeable:SetDislodged()
            end
        end

		if data.dislodged ~= nil then
			SetDislodged(inst)
			inst.components.dislodgeable:SetDislodged()
		end
    end
end

local function OnWorkCallback(inst, worker, workleft)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        if inst:HasTag("trggerdarttraps") then
            TriggerDarts(inst)
        end
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
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
            inst.components.dislodgeable:SetDislodged()
        elseif workleft < TUNING.ROCKS_MINE*(2/3) then
            inst.AnimState:PlayAnimation("med")
            inst.components.dislodgeable:SetDislodged()
        else
            if not inst.components.dislodgeable or inst.components.dislodgeable:CanBeDislodged() then
                inst.AnimState:PlayAnimation("full")
            else
                inst.AnimState:PlayAnimation("extract_success")
            end
        end
    end
end

local function Shine(inst)
    inst.task = nil

   	if inst.components.dislodgeable ~= nil and inst.components.dislodgeable:CanBeDislodged() then
   		inst.AnimState:PlayAnimation("sparkle")
   		inst.AnimState:PushAnimation("full")
   	end

    if inst.entity:IsAwake() then
        inst:DoTaskInTime(4 + math.random() * 5, Shine)
    end
end

local function OnEntityWake(inst)
    inst.task = inst:DoTaskInTime(4 + math.random() * 5, Shine)
end

local function MakeRuins(name, bank, build, minimap, product, num, rad, chanceloottable, nameoverride, is_shine)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, rad)

        inst.MiniMapEntity:SetIcon(minimap .. ".tex")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("full")
        local color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -- inst:AddComponent("mystery")
        -- inst:AddComponent("named")
        -- inst.components.named:SetName(STRINGS.NAMES[nameoverride])

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable(chanceloottable)

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
        inst.components.workable:SetOnWorkCallback(OnWorkCallback)

        inst:AddComponent("dislodgeable")
        inst.components.dislodgeable:SetUp(product, num)
        inst.components.dislodgeable:SetOnDislodgedFn(OnDislodged)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        if is_shine then
            inst.OnEntityWake = OnEntityWake
        end

        MakeSnowCovered(inst, .01)
        MakeHauntableWork(inst)

        return inst
    end
    return Prefab(name, fn, ruins_assets, prefabs)
end

local data = {
    pig_ruins_head = {
        bank = "pig_ruins_head",
        build = "ruins_giant_head",
        minimap = "ruins_giant_head",
        product = "relic_3",
        rad = 1,
        chanceloottable = "ruins_gianthead",
        nameoverride = "PIG_RUINS_HEAD",
    },
    pig_ruins_pig = {
        bank = "statue_pig_ruins_pig",
        build = "statue_pig_ruins_pig",
        minimap = "statue_pig_ruins_pig",
        product = "goldnugget",
        num = 2,
        rad = 1,
        chanceloottable = "ruins_pig",
        nameoverride = "PIG_RUINS_HEAD",
        is_shine = true
    },
    pig_ruins_ant = {
        bank = "statue_pig_ruins_ant",
        build = "statue_pig_ruins_ant",
        minimap = "statue_pig_ruins_ant",
        product = "goldnugget",
        num = 2,
        rad = 1,
        chanceloottable = "ruins_pig",
        nameoverride = "PIG_RUINS_HEAD",
        is_shine = true
    },
    pig_ruins_idol = {
        bank = "statue_pig_ruins_idol",
        build = "statue_pig_ruins_idol",
        minimap = "statue_pig_ruins_idol",
        product = "relic_1",
        rad = 0.75,
        chanceloottable = "ruins_pig",
        nameoverride = "PIG_RUINS_IDOL",
    },
    pig_ruins_plaque = {
        bank = "statue_pig_ruins_plaque",
        build = "statue_pig_ruins_plaque",
        minimap = "statue_pig_ruins_plaque",
        product = "relic_2",
        rad = 0.75,
        chanceloottable = "ruins_pig",
        nameoverride = "PIG_RUINS_PLAQUE",
    },
    pig_ruins_truffle = {
        bank = "statue_pig_ruins_mushroom",
        build = "statue_pig_ruins_mushroom",
        minimap = "statue_pig_ruins_mushroom",
        product = "relic_5",
        rad = 0.75,
        chanceloottable = "ruins_pig",
        nameoverride = "PIG_RUINS_MUSHROOM",
    },
    pig_ruins_sow = {
        bank = "statue_pig_ruins_idol_blue",
        build = "statue_pig_ruins_idol_blue",
        minimap = "statue_pig_ruins_idol_blue",
        product = "relic_4",
        rad = 0.75,
        chanceloottable = "ruins_pig",
        nameoverride = "PIG_RUINS_SOW",
    }
}

local pig_ruins = {}
for k, v in pairs(data) do
    table.insert(pig_ruins, MakeRuins(k, v.bank, v.build, v.minimap, v.product, v.num, v.rad, v.chanceloottable, v.nameoverride, v.is_shine))
end

return unpack(pig_ruins)

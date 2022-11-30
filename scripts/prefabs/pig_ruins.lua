local ruins_assets =
{
	Asset("ANIM", "anim/ruins_artichoke.zip"),
	Asset("ANIM", "anim/ruins_giant_head.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_pig.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_ant.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_idol.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_plaque.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_mushroom.zip"),
	Asset("ANIM", "anim/statue_pig_ruins_idol_blue.zip"),
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "relic_3",
    "pigghost",
}

SetSharedLootTable( 'ruins_artichoke',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'nitre',  0.25},
    {'flint',  0.60},
    {'flint',  0.60},
    {'gold_dust',  0.60},
})

SetSharedLootTable( 'ruins_pig',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'flint',  0.60},
    {'gold_dust',  0.60},
    {'pigghost', 0.2},
})

SetSharedLootTable( 'ruins_gianthead',
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

-- local function triggerdarts(inst)
--     print("TRIGGER DARTS!")
--     local pt = Vector3(inst.Transform:GetWorldPosition())
--     local ents = The:FindEntities(pt.x, pt.y, pt.z, 50, {"dartthrower"}, {"INTERIOR_LIMBO"})
--     for i, ent in ipairs(ents) do
--     	if ent.components.autodartthrower then
--     		ent.components.autodartthrower:TurnOn()
--     	elseif ent.shoot then
--             ent.shoot(ent)
--         end
--     end
-- end

local function setdislodged(inst)
	inst.dislodged = true
	inst.AnimState:PlayAnimation("extract_success")
    inst.components.dislodgeable:OnRemoveFromEntity()
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_EXTRACTED"])
end

local function ondislodged(inst)
	-- if inst:HasTag("trggerdarttraps") then
		-- triggerdarts(inst)
	-- end
	setdislodged(inst)
end

local function onsave(inst,data)
	if inst:HasTag("trggerdarttraps") then
		data.trggerdarttraps = true
	end
	if inst.dislodged then
		data.dislodged = true
	end
end

local function onload(inst, data)
	if data then
		if data.trggerdarttraps then
			inst:AddTag("trggerdarttraps")
		end
		if data.dislodged then
			setdislodged(inst)
			inst.components.dislodgeable:SetDislodged()
		end
	end
end

local function shine(inst)
    inst.task = nil

   	if inst.components.dislodgeable and inst.components.dislodgeable:CanBeDislodged() then
   		inst.AnimState:PlayAnimation("sparkle")
   		inst.AnimState:PushAnimation("full")
   	end

    if inst.entity:IsAwake() then
        inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
    end
end

local function onwake(inst)
    inst.task = inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
end

local function SetOnWorkCallback(inst, worker, workleft)
    local pt = inst:GetPosition()
    if workleft <= 0 then
        -- if inst:HasTag("trggerdarttraps") then
            -- triggerdarts(inst)
        -- end

        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(pt)

        inst:Remove()
        else
        if not inst.components.dislodgeable or inst.components.dislodgeable:CanBeDislodged() then
            inst.AnimState:PlayAnimation("full")
        else
            inst.AnimState:PlayAnimation("extract_success")
        end
    end
end

local function canbedislodgedfn(inst)
    if inst.components.workable and inst.components.workable.workleft < TUNING.ROCKS_MINE*(2/3) then
        return false
    end
    return true
end

local function normal_fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    inst:AddTag("dislodgeable")

	MakeObstaclePhysics(inst, 0.75)

	return inst
end

local function masterfn(inst)

	inst:AddComponent("lootdropper")

	inst:AddComponent("dislodgeable")

	inst:AddComponent("named")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
	inst.components.workable:SetOnWorkCallback(SetOnWorkCallback)

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "ROCK"

	-- inst:AddComponent("mystery")

    inst.OnSave = onsave
    inst.OnLoad = onload

    MakeHauntableWork(inst)

    return inst
end

local function pig_ruins_head()
	local inst = normal_fn()
	inst.AnimState:SetBank("pig_ruins_head")
	inst.AnimState:SetBuild("ruins_giant_head")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "ruins_giant_head.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddTag("DISLODGE_workable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])

    inst.components.lootdropper:SetChanceLootTable('ruins_gianthead')
    inst.components.inspectable.nameoverride = nil

    inst:AddComponent("dislodgeable")
    inst.components.dislodgeable:SetUp("relic_3",1)

	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn =canbedislodgedfn

	return inst
end

local function pig_ruins_pig()
	local inst = normal_fn()
	inst.AnimState:SetBank("statue_pig_ruins_pig")
	inst.AnimState:SetBuild("statue_pig_ruins_pig")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_pig.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddTag("DISLODGE_workable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')
	inst.components.inspectable.nameoverride = nil

	inst.components.dislodgeable:SetUp("goldnugget",2)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)

    inst.OnEntityWake = onwake

	inst.components.dislodgeable.canbedislodgedfn = canbedislodgedfn

	return inst
end

local function pig_ruins_ant()
	local inst = normal_fn()
	inst.AnimState:SetBank("statue_pig_ruins_ant")
	inst.AnimState:SetBuild("statue_pig_ruins_ant")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_ant.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("DISLODGE_workable")

    masterfn(inst)

	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_HEAD"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst.components.dislodgeable:SetUp("goldnugget",2)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = canbedislodgedfn
    inst.OnEntityWake = onwake

	return inst
end

local function pig_ruins_idol()
	local inst = normal_fn()
	inst.AnimState:SetBank("statue_pig_ruins_idol")
	inst.AnimState:SetBuild("statue_pig_ruins_idol")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_idol.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddTag("DISLODGE_workable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_IDOL"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst.components.dislodgeable:SetUp("relic_1",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = canbedislodgedfn

	inst.components.inspectable.nameoverride = nil

	return inst
end

local function pig_ruins_plaque()
	local inst = normal_fn()
	inst.AnimState:SetBank("statue_pig_ruins_plaque")
	inst.AnimState:SetBuild("statue_pig_ruins_plaque")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_plaque.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddTag("DISLODGE_workable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_PLAQUE"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst.components.dislodgeable:SetUp("relic_2",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn =canbedislodgedfn

	inst.components.inspectable.nameoverride = nil

	return inst
end

local function pig_ruins_truffle()
	local inst = normal_fn()
	inst.AnimState:SetBank("statue_pig_ruins_mushroom")
	inst.AnimState:SetBuild("statue_pig_ruins_mushroom")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_mushroom.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddTag("DISLODGE_workable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_MUSHROOM"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst.components.dislodgeable:SetUp("relic_5",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = canbedislodgedfn

	return inst
end

local function pig_ruins_sow()
	local inst = normal_fn()
	inst.AnimState:SetBank("statue_pig_ruins_idol_blue")
	inst.AnimState:SetBuild("statue_pig_ruins_idol_blue")
	inst.AnimState:PlayAnimation("full")
	inst.MiniMapEntity:SetIcon( "statue_pig_ruins_idol_blue.tex" )

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddTag("DISLODGE_workable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    masterfn(inst)

	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_SOW"])
	inst.components.lootdropper:SetChanceLootTable('ruins_pig')

	inst.components.dislodgeable:SetUp("relic_4",1)
	inst.components.dislodgeable:SetOnDislodgedFn(ondislodged)
	inst.components.dislodgeable.canbedislodgedfn = canbedislodgedfn

	return inst
end

return Prefab("pig_ruins_head", pig_ruins_head, ruins_assets, prefabs),
        Prefab("pig_ruins_pig", pig_ruins_pig, ruins_assets, prefabs),
        Prefab("pig_ruins_ant", pig_ruins_ant, ruins_assets, prefabs),
        Prefab("pig_ruins_idol", pig_ruins_idol, ruins_assets, prefabs),
        Prefab("pig_ruins_plaque", pig_ruins_plaque, ruins_assets, prefabs),
        Prefab("pig_ruins_truffle", pig_ruins_truffle, ruins_assets, prefabs),
        Prefab("pig_ruins_sow", pig_ruins_sow, ruins_assets, prefabs)


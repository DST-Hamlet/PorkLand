local antqueen_throne_assets =
{
	Asset("ANIM", "anim/throne.zip"),
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "gold_dust",
    "bluegem",
}

SetSharedLootTable( 'antqueen_throne',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},

    {'flint',  1.0},
    {'flint',  1.0},
    {'flint',  0.8},
    {'flint',  0.8},
    {'flint',  0.8},
    {'flint',  0.8},

    {'nitre',  0.8},
    {'nitre',  0.8},
    {'nitre',  0.8},
    {'nitre',  0.8},

    {'gold_dust', 0.6},
    {'gold_dust', 0.6},

    {'gold_nugget', 1.0},
	{'gold_nugget', 1.0},
	{'gold_nugget', 0.3},
	{'gold_nugget', 0.3},

    {'bluegem', 0.5},
    {'bluegem', 0.5},
})

local function OnWorkCallback(inst, worker, workleft)

    local pt = Point(inst.Transform:GetWorldPosition())
    if workleft <= 0 then

        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(pt)
        inst:Remove()
    else
        if workleft < TUNING.ROCKS_MINE*(1/3) then
            inst.AnimState:PlayAnimation("low")
        elseif workleft < TUNING.ROCKS_MINE*(2/3) then
            inst.AnimState:PlayAnimation("med")
        end
    end
end

local function onremove(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local ents = TheSim:FindEntities(x,y,z, 10, {"throne_wall"})
    for k,v in pairs(ents) do
        v:Remove()
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)

	inst.MiniMapEntity:SetIcon("ruins_artichoke.tex")

    inst:AddTag("throne")

	inst.AnimState:SetBank("throne")
	inst.AnimState:SetBuild("throne")
	inst.AnimState:PlayAnimation("full")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("lootdropper")

	inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["ANTQUEEN_THRONE"])
	inst.components.lootdropper:SetChanceLootTable('antqueen_throne')

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
	inst.components.workable:SetOnWorkCallback(OnWorkCallback)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_GIANT)

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "ROCK"

	-- inst:AddComponent("mystery")

	inst:ListenForEvent( "onremove", onremove, inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	MakeSnowCovered(inst, .01)
	return inst
end

return Prefab("antqueen_throne", fn, antqueen_throne_assets, prefabs)

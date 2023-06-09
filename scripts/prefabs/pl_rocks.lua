local antqueen_throne_assets = {
	Asset("ANIM", "anim/throne.zip"),
}

local basalt_assets = {
	Asset("ANIM", "anim/rock_basalt.zip"),
	-- Asset("MINIMAP_IMAGE", "rock"),
}

local ruins_artichoke_assets = {
    Asset("ANIM", "anim/ruins_artichoke.zip"),
}

local prefabs = {
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "rock_break_fx"
}

SetSharedLootTable('ruins_artichoke',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'nitre',  0.25},
    {'nitre',  0.25},
    {'flint',  0.60},
    {'flint',  0.60},
    {'gold_dust',  0.60},
})

SetSharedLootTable('antqueen_throne',
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

SetSharedLootTable('basalt',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  0.50},
    {'flint',  1.00},
    {'flint',  0.30},
})

local function OnWorkCallback(inst, worker, workleft)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
        inst.components.lootdropper:DropLoot(pt)

        inst:Remove()
    else
        inst.AnimState:PlayAnimation(
            (workleft < TUNING.ROCKS_MINE / 3 and "low") or
            (workleft < TUNING.ROCKS_MINE * 2 / 3 and "med") or
            "full"
        )
    end
end

local function OnSave(inst, data)
    data.workleft = inst.components.workable.workleft
end

local function OnLoad(inst, data)
    if data ~= nil and data.workleft then
        inst.components.workable:SetWorkLeft(data.workleft)
        inst.AnimState:PlayAnimation(
            (data.workleft < TUNING.ROCKS_MINE / 3 and "low") or
            (data.workleft < TUNING.ROCKS_MINE * 2 / 3 and "med") or
            "full"
        )
    end
end

local function MakeRock(name, assets, bank, build, rad, loottable, minimapicon, common_postinit, master_postinit)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, rad)

        inst.MiniMapEntity:SetIcon(minimapicon .. ".tex")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("full")

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -- inst:AddComponent("mystery")

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable(loottable)

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
        inst.components.workable:SetOnWorkCallback(OnWorkCallback)

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        inst.OnLoad = OnLoad
        inst.OnSave = OnSave

        MakeSnowCovered(inst, .01)
        MakeHauntableWork(inst)

        return inst
    end
    return Prefab(name, fn, assets, prefabs)
end

local function antqueen_throne_common_postinit(inst)
	inst.Transform:SetScale(0.9, 0.9, 0.9)
	MakeObstaclePhysics(inst, 3.5)
end

local function antqueen_throne_master_postinit(inst)
    -- inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["ANTQUEEN_THRONE"])

    local function fn()
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x,y,z, 10, {"throne_wall"})
        for k,v in pairs(ents) do
	        v:Remove()
	    end
    end
	inst:ListenForEvent("onremove", fn, inst)
end

local function pig_ruins_artichoke_master_postinit(inst)
	-- inst:AddComponent("named")
	-- inst.components.named:SetName(STRINGS.NAMES["PIG_RUINS_ARTICHOKE"])
end

return MakeRock("antqueen_throne", antqueen_throne_assets, "throne", "throne", 3.5, "ruins_artichoke", "antqueen_throne", antqueen_throne_common_postinit, antqueen_throne_master_postinit),
    MakeRock("rock_basalt", basalt_assets, "rock_basalt", "rock_basalt", 1,"basalt", "rock"),
    MakeRock("pig_ruins_artichoke", ruins_artichoke_assets, "ruins_artichoke", "ruins_artichoke", 1, "ruins_artichoke", "ruins_artichoke", nil, pig_ruins_artichoke_master_postinit)

local teatree_nut_assets =
{
    Asset("ANIM", "anim/teatree_nut.zip"),
}

local teatree_nut_prefabs =
{
    "twigs",
}

local burr_assets = {
    Asset("ANIM", "anim/burr.zip"),
}

local burr_prefabs = {
    "twigs",
}

local clawpalmtree_assets = {
    Asset("ANIM", "anim/clawling.zip"),
}

local clawpalmtree_prefabs = {
    "twigs",
}

local function growtree(inst)
    local tree = SpawnPrefab(inst.growprefab)
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function stopgrowing(inst)
    inst.components.timer:StopTimer("grow")
end

local function ontimerdone(inst, data)
    if data.name == "grow" then
        growtree(inst)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function burr_growprefab_fn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    if TheWorld.Map:GetTileAtPoint(x, y, z) == WORLD_TILES.GASJUNGLE then
        return "rainforesttree_rot"
    else
        return "rainforesttree"
    end
end

local function sapling_fn(build, anim, growprefab, tag, fireproof, overrideloot, override_growtime)
    local function start_growing(inst)
        if not inst.components.timer:TimerExists("grow") then
            local base_time = override_growtime and override_growtime.base or TUNING.PINECONE_GROWTIME.base
            local random_time = override_growtime and override_growtime.random or TUNING.PINECONE_GROWTIME.random
            local growtime = GetRandomWithVariance(base_time, random_time)
            inst.components.timer:StartTimer("grow", growtime)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        if not fireproof then
            inst:AddTag("plant")
        end

        if tag then
            inst:AddTag(tag)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.growprefab = growprefab
        inst.StartGrowing = start_growing

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", ontimerdone)
        start_growing(inst)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(overrideloot or {"twigs"})

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(digup)
        inst.components.workable:SetWorkLeft(1)

        if not fireproof then
            MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
            inst:ListenForEvent("onignite", stopgrowing)
            inst:ListenForEvent("onextinguish", start_growing)
            MakeSmallPropagator(inst)

            MakeHauntableIgnite(inst)
        else
            MakeHauntableWork(inst)
        end

        return inst
    end

    return fn
end

return Prefab("teatree_nut_sapling", sapling_fn("teatree_nut", "idle_planted", "teatree"), teatree_nut_assets, teatree_nut_prefabs),
       Prefab("burr_sapling", sapling_fn("burr", "idle_planted", burr_growprefab_fn, nil, nil, nil, TUNING.JUNGLETREESEED_GROWTIME), burr_assets, burr_prefabs),
       Prefab("clawpalmtree_sapling", sapling_fn("clawling", "idle_planted", "clawpalmtree", nil, nil, nil, TUNING.ACORN_GROWTIME), clawpalmtree_assets, clawpalmtree_prefabs)

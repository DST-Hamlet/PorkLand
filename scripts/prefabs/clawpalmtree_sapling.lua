require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/clawling.zip"),
}

local prefabs =
{
	"clawpalmtree_sapling",
	--"winter_clawling",
}

local function growtree(inst)
    inst.growtask = nil
    inst.growtime = nil

    local tree = SpawnPrefab("clawpalmtree")
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function stopgrowing(inst)
    if inst.growtask then
        inst.growtask:Cancel()
        inst.growtask = nil
    end
    inst.growtime = nil
end

local function restartgrowing(inst)
    if inst and not inst.growtask and not inst.components.inventoryitem then -- It won't have inventoryitem component if it's already a sapling.
        local growtime = GetRandomWithVariance(TUNING.ACORN_GROWTIME.base, TUNING.ACORN_GROWTIME.random)
        inst.growtime = GetTime() + growtime
        inst.growtask = inst:DoTaskInTime(growtime, growtree)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:SpawnLootPrefab("twigs")
    inst:Remove()
end

local function plant(inst, growtime)

    RemovePhysicsColliders(inst)
    --RemoveBlowInHurricane(inst)
    inst:RemoveComponent("inventoryitem")

    inst.growtime = GetTime() + growtime
    inst.growtask = inst:DoTaskInTime(growtime, growtree)

    inst.AnimState:PlayAnimation("idle_planted")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(digup)
    inst.components.workable:SetWorkLeft(1)
end

local LEIF_TAGS = { "leif" }
local function ondeploy(inst, pt, deployer)
    inst = inst.components.stackable:Get()
    inst.Physics:Teleport(pt:Get())
    local timeToGrow = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
    plant(inst, timeToGrow)
end

local function OnSave(inst, data)
    if inst.growtime then
        data.growtime = inst.growtime - GetTime()
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.growtime ~= nil then
		print("plant")
        plant(inst, data.growtime)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("clawling")
	inst.AnimState:SetBuild("clawling")
	inst.AnimState:PlayAnimation("idle") -- org idle_planted

	inst:AddTag("deployedplant")
	inst:AddTag("cattoy")
	inst:AddTag("treeseed")

	MakeInventoryFloatable(inst, "small", 0.05, 0.9)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("tradable")

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	inst:AddComponent("inventoryitem")

	MakeHauntableLaunchAndIgnite(inst)

	inst:AddComponent("deployable")
	inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
	inst.components.deployable.ondeploy = ondeploy

	inst:AddComponent("forcecompostable")
	inst.components.forcecompostable.brown = true

	-- for winters feast event to plant in winter_treestand
	-- inst:AddComponent("winter_treeseed")
	-- inst.components.winter_treeseed:SetTree("winter_clawling")
	
	inst:ListenForEvent("onignite", stopgrowing)
    inst:ListenForEvent("onextinguish", startgrowing)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("clawpalmtree_sapling", fn, assets, prefabs),
MakePlacer("clawpalmtree_sapling_placer", "clawling", "clawling", "idle_planted")
require "prefabutil"

local assets = {
    Asset("ANIM", "anim/clawling.zip"),
}

local prefabs = {}

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
    inst.AnimState:SetScale(1, 1, 1)

    RemovePhysicsColliders(inst)
    RemoveBlowInHurricane(inst)
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

local function ondeploy(inst, pt) 
    inst = inst.components.stackable:Get()

    if inst.components.inventoryitem then
        inst.components.inventoryitem:OnRemoved()
    end
    
    inst.Transform:SetPosition(pt:Get())

    local growtime = GetRandomWithVariance(TUNING.ACORN_GROWTIME.base, TUNING.ACORN_GROWTIME.random)
    plant(inst, growtime)
end

local notags = {'NOBLOCK', 'player', 'FX'}
local function test_ground(inst, pt)
    local ground_OK = inst:GetIsOnLand(pt.x, pt.y, pt.z)
    local tiletype = GetGroundTypeAtPosition(pt)

    local ground_OK = ground_OK and 
        tiletype ~= GROUND.INTERIOR and tiletype ~= GROUND.GASJUNGLE and 
        tiletype ~= GROUND.COBBLEROAD and tiletype ~= GROUND.FOUNDATION and 
        tiletype ~= GROUND.ROCKY and tiletype ~= GROUND.ROAD and tiletype ~= GROUND.IMPASSABLE and
        tiletype ~= GROUND.UNDERROCK and tiletype ~= GROUND.WOODFLOOR and 
        tiletype ~= GROUND.CARPET and tiletype ~= GROUND.CHECKER and tiletype < GROUND.UNDERGROUND

    if ground_OK then
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 4, nil, notags) -- or we could include a flag to the search?
        local min_spacing = 2

        for k, v in pairs(ents) do
            if v ~= inst and v:IsValid() and v.entity:IsVisible() and not v.components.placer and v.parent == nil then
                if distsq( Vector3(v.Transform:GetWorldPosition()), pt) < min_spacing*min_spacing then
                    return false
                end
            end
        end
        return true
    end
    return false
end

local function OnSave(inst, data)
    if inst.growtime then
        data.growtime = inst.growtime - GetTime()
    end
end

local function OnLoad(inst, data)
    if data and data.growtime then
        plant(inst, data.growtime)
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

    inst.AnimState:SetBank("clawling")
    inst.AnimState:SetBuild("clawling")
    inst.AnimState:PlayAnimation("idle_planted")

    inst.AnimState:SetScale(.7, .7, .7)
    
    --MakeInventoryFloatable(inst, "idle_water", "idle")

    inst:AddTag("plant")
    inst:AddTag("cattoy")
    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
    
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    inst:AddComponent("appeasement")
    inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL
    
	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    inst.components.burnable:MakeDragonflyBait(3)

	inst:ListenForEvent("onignite", stopgrowing)
    inst:ListenForEvent("onextinguish", restartgrowing)
    
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("deployable")
    inst.components.deployable.test = test_ground
    inst.components.deployable.ondeploy = ondeploy

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return
    Prefab( "common/inventory/clawpalmtree_sapling", fn, assets, prefabs),
    MakePlacer( "common/clawpalmtree_sapling_placer", "clawling", "clawling", "idle_planted")


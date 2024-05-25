local assets =
{
    Asset("ANIM", "anim/lily_pad.zip"),
}

local prefabs =
{
    "frog_poison",
    "mosquito",
}

local SIZES = {
    small = 2,
    med = 3,
    big = 5.2,
}

local function MakeLilypadPhysics(inst, rad)
    inst:AddTag("blocker")

    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCapsule(rad, 0.01)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.WORLD)
end

local function RefreshBuild(inst)
    inst.AnimState:PlayAnimation(inst.size .. "_idle", true)
    inst.Transform:SetRotation(inst.rotation)

    inst.Physics:SetCapsule(SIZES[inst.size], 0.01)
end

local function ReturnChildren(inst)
    for _, child in pairs(inst.components.childspawner.childrenoutside) do
        if child.components.homeseeker then
            child.components.homeseeker:GoHome()
        end
        child:PushEvent("gohome")
    end
end

local MAX_RANGE = 15
local function OverlapCheck(inst)
    if inst.spawned then
        return
    end

    local x, _, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, MAX_RANGE, {"lilypad"})

    if #ents > 1 then
        table.sort(ents, function(a, b) return SIZES[a.size] > SIZES[b.size] end)
        local biggest = table.remove(ents, 1)

        for _, ent in ipairs(ents) do
            local safe_dist = SIZES[biggest.size] + SIZES[ent.size]
            local safe_dist_sq = safe_dist * safe_dist
            if biggest:GetDistanceSqToInst(ent) <= safe_dist_sq then
                print("remove overlap lilypad!")
                ent:Remove()
            end
        end
    end

    inst.spawned = true
end

local function OnSave(inst, data)
    data.size = inst.size
    data.spawned = inst.spawned
    data.rotation = inst.rotation
end

local function OnLoad(inst, data, newents)
    if data then
        if data.size then
            inst.size = data.size
        end
        if data.rotaion then
            inst.rotation = data.rotation
        end
        inst.spawned = data.spawned
    end

    RefreshBuild(inst)
end

local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeLilypadPhysics(inst, 2)

    inst.AnimState:SetBuild("lily_pad")
    inst.AnimState:SetBank("lily_pad")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("lily_pad.tex")

    inst:AddTag("lilypad")
    inst:AddTag("waveobstacle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.spawned = false
    inst.no_wet_prefix = true
    inst.rotation = math.random(360)

    inst.size = "small"

    local random = math.random()
    if random < 0.33 then
        inst.size = "med"
    elseif random < 0.66 then
        inst.size = "big"
    end

    RefreshBuild(inst)

    inst:AddComponent("inspectable")

    -- inst:AddComponent("waveobstacle") -- This component is for mangroves

    inst:AddComponent("childspawner")
    inst.components.childspawner.allowwater = true
    inst.components.childspawner.spawnonwateroffset = 1
    inst.components.childspawner:StartRegen()

    inst:DoTaskInTime(0, OverlapCheck)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function OnSpawnedFrog(inst, child)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/water/small_submerge")
    child.sg:GoToState("submerge")
end

local function FrogPoisonOnPhaseChange(inst, phase)
    if phase == "day" then
        inst.components.childspawner:StartSpawning()
    else
        inst.components.childspawner:StopSpawning()
        ReturnChildren(inst)
    end
end

local function FrogPoisonOnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.FROG_POISON_LILYPAD_RELEASE_TIME, TUNING.FROG_POISON_LILYPAD_REGEN_TIME)
end

local function frog_poison_lilypad()
    local inst = common()

    inst:SetPrefabNameOverride("lilypad")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.childspawner.childname = "frog_poison"
    inst.components.childspawner:SetSpawnedFn(OnSpawnedFrog)
    inst.components.childspawner:SetSpawnPeriod(TUNING.FROG_POISON_LILYPAD_RELEASE_TIME)
    inst.components.childspawner:SetRegenPeriod(TUNING.FROG_POISON_LILYPAD_REGEN_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.FROG_POISON_LILYPAD_MAX_SPAWN)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.FROG_POISON_LILYPAD_RELEASE_TIME, TUNING.FROG_POISON_LILYPAD_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.FROG_POISON_LILYPAD_REGEN_TIME, TUNING.FROG_POISON_LILYPAD_ENABLED)
    if not TUNING.FROG_POISON_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst:WatchWorldState("phase", FrogPoisonOnPhaseChange)
    FrogPoisonOnPhaseChange(inst, TheWorld.state.phase)

    inst.OnPreLoad = FrogPoisonOnPreLoad

    return inst
end

local function MosquitoLilypadOnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.MOSQUITO_LILYPAD_RELEASE_TIME, TUNING.MOSQUITO_LILYPAD_REGEN_TIME)
end

local function MosquitoOnPhaseChange(inst, phase)
    if phase == "day" then
        inst.components.childspawner:StopSpawning()
        ReturnChildren(inst)
    else
        inst.components.childspawner:StartSpawning()
    end
end

local function mosquito_lilypad()
    local inst = common()

    inst:SetPrefabNameOverride("lilypad")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.childspawner.childname = "mosquito"
    inst.components.childspawner:SetSpawnPeriod(TUNING.MOSQUITO_LILYPAD_RELEASE_TIME)
    inst.components.childspawner:SetRegenPeriod(TUNING.MOSQUITO_LILYPAD_REGEN_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.MOSQUITO_LILYPAD_MAX_SPAWN)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.MOSQUITO_LILYPAD_RELEASE_TIME, TUNING.MOSQUITO_LILYPAD_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.MOSQUITO_LILYPAD_REGEN_TIME, TUNING.MOSQUITO_LILYPAD_ENABLED)
    if not TUNING.MOSQUITO_LILYPAD_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst:WatchWorldState("phase", MosquitoOnPhaseChange)
    MosquitoOnPhaseChange(inst, TheWorld.state.phase)

    inst.OnPreLoad = MosquitoLilypadOnPreLoad

    return inst
end

return Prefab("frog_poison_lilypad", frog_poison_lilypad, assets, prefabs),
    Prefab("mosquito_lilypad", mosquito_lilypad, assets, prefabs)

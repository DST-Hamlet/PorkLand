local assets =
{
    Asset("ANIM", "anim/lily_pad.zip"),
    -- Asset("ANIM", "anim/splash.zip"),
    -- Asset("MINIMAP_IMAGE", "lily_pad"),
}

local prefabs =
{
    "frog_poison",
    "mosquito",
}

function MakeLilypadPhysics(inst, rad)
    inst:AddTag("blocker")

    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCapsule(rad,0.01)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.WAVES)
    inst.Physics:CollidesWith(COLLISION.WORLD)
end

local SIZES = {
    small = 2,
    med = 3,
    big = 4.2,
}
local function RefreshBuild(inst)
    inst.AnimState:PlayAnimation(inst.size .. "_idle", true)
    inst.Transform:SetRotation(inst.rotation)

    MakeLilypadPhysics(inst, SIZES[inst.size or "small"])
end

local function ReturnChildren(inst)
    for k,child in pairs(inst.components.childspawner.childrenoutside) do
        if child.components.homeseeker then
            child.components.homeseeker:GoHome()
        end
        child:PushEvent("gohome")
    end
end

local function OnSpawned(inst, child)
    if inst.components.childspawner.childname == "frog_poison" then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/water/small_submerge")
        child.sg:GoToState("submerge")
    end
end

local function OnPhaseChange(inst, phase)
    if inst.components.childspawner.childname == "frog_poison" then
        if phase == "day" then
            inst.components.childspawner:StartSpawning()
        elseif phase == "night" then
            inst.components.childspawner:StopSpawning()
            ReturnChildren(inst)
        end
    end

    if inst.components.childspawner.childname == "mosquito" then
        if phase == "day" then
            inst.components.childspawner:StopSpawning()
            ReturnChildren(inst)
        elseif phase == "dusk" then
            inst.components.childspawner:StartSpawning()
        end
    end
end

local function OnSave(inst, data)
    data.size = inst.size
    data.rotation = inst.rotation
    data.childname = inst.components.childspawner.childname
end

local function OnLoad(inst, data, newents)
    if data then
        if data.size then
            inst.size = data.size
        end
        if data.childname then
            inst.components.childspawner.childname = data.childname
        end
    end

    RefreshBuild(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("lily_pad")
    inst.AnimState:SetBank("lily_pad")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("lily_pad.tex")

    inst.no_wet_prefix = true
    inst.rotation = math.random(360)
    inst.size = "small"
    if math.random() < 0.66 then
        if math.random() < 0.33 then
            inst.size = "med"
        else
            inst.size = "big"
        end
    end

    RefreshBuild(inst)

    inst:AddTag("lilypad")
    inst:AddTag("waveobstacle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- inst:AddComponent("waveobstacle") -- This component was only ever on mangroves

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetMaxChildren(math.random(1, 2))
    inst.components.childspawner:SetSpawnedFn(OnSpawned)
    inst.components.childspawner.allowwater = true
    inst.components.childspawner.spawnonwateroffset = 1
    inst.components.childspawner:StartRegen()

    if math.random() < 0.5 then
        inst.components.childspawner.childname = "mosquito"
        inst.components.childspawner:SetRegenPeriod(TUNING.MOSQUITO_REGEN_TIME)
        inst.components.childspawner:SetMaxChildren(TUNING.MOSQUITO_MAX_SPAWN)
    else
        inst.components.childspawner.childname = "frog_poison"
        inst.components.childspawner:SetRegenPeriod(TUNING.FROG_POISON_REGEN_TIME)
        inst.components.childspawner:SetMaxChildren(TUNING.FROG_POISON_MAX_SPAWN)
    end

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("lilypad", fn, assets, prefabs)

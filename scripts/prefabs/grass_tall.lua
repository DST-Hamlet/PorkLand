local assets =
{
    Asset("ANIM", "anim/grass_tall.zip", 1),
}

local prefabs =
{
    "weevole",
    "cutgrass",
    "dug_grass",
    "hacking_tall_grass_fx",
}

local function GetStatus(inst, viewer)
    return not (inst.components.burnable and inst.components.burnable:IsBurning()) and
            inst.components.hackable and not inst.components.hackable:CanBeHacked() and "PICKED"
            or nil
end

local function DigUp(inst, target)
    if inst.components.hackable and inst.components.hackable:CanBeHacked() then
        inst.components.lootdropper:SpawnLootPrefab("cutgrass")
    end
    if inst:HasTag("weevole_infested")then
        inst.components.childspawner:ReleaseAllChildren(target)
    end

    inst.components.lootdropper:SpawnLootPrefab("dug_grass")
    inst:Remove()
end

local function StartSpawning(inst, isdusk)
    if inst.components.childspawner and inst.components.hackable:CanBeHacked() then
        local frozen = (inst.components.freezable and inst.components.freezable:IsFrozen())
        if not frozen and not TheWorld.state.isday then
            inst.components.childspawner:StartSpawning()
        end
    end
end

local function StopSpawning(inst, isday)
    if inst.components.childspawner and isday then
        inst.components.childspawner:StopSpawning()
    end
end

local function MakeWeevoleden(inst)
    inst:AddTag("weevole_infested")
    inst:WatchWorldState("isdusk", StartSpawning)
    inst:WatchWorldState("isday", StopSpawning)
end

local function RemoveWeevoleden(inst)
    inst:RemoveTag("weevole_infested")
    StopSpawning(inst, true)
    inst:StopWatchingWorldState("isdusk", StartSpawning)
    inst:StopWatchingWorldState("isday", StopSpawning)
end

local function WeevoleNestTest(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 12, {"grass_tall"})
    local weevole_ents = TheSim:FindEntities(x, y, z, 12, {"weevole_infested"})

    if #weevole_ents < 1 and math.random() < #ents / 100 then
        local ent = ents[math.random(#ents)]
        MakeWeevoleden(ent)
    end
end

local function SpawnWeevole(inst, target)
    local weevole = inst.components.childspawner:SpawnChild()
    if weevole then
        local spawnpos = inst:GetPosition()
        spawnpos = spawnpos
        weevole.Transform:SetPosition(spawnpos:Get())
        if weevole and target and weevole.components.combat then
            weevole.components.combat:SetTarget(target)
        end
    end
end

local function OnHack(inst, target, hacksleft, from_shears)
    local fx = SpawnPrefab("hacking_tall_grass_fx")
    local x, y, z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + math.random() * 2, z)

    if inst:HasTag("weevole_infested") then
        SpawnWeevole(inst, target)
    end

    if inst.components.hackable and inst.components.hackable.hacksleft <= 0 then
        if inst:HasTag("weevole_infested")then
            inst.components.childspawner:ReleaseAllChildren(target)
            RemoveWeevoleden(inst)
        end
        inst.AnimState:PlayAnimation("fall")
        inst.AnimState:PushAnimation("picked", true)
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_drop")
    else
        inst.AnimState:PlayAnimation("chop")
        inst.AnimState:PushAnimation("idle", true)
    end

    if not from_shears then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/grass_tall/machete")
    end
end

local function OnRegen(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    if not NUTRIENT_TILES[tile] then
        local cycles_left = inst.components.hackable.cycles_left
        local shortgrass = ReplacePrefab(inst, "grass")
        shortgrass.components.pickable.transplanted = true
        shortgrass.components.pickable.cycles_left = cycles_left
        shortgrass.components.pickable.onregenfn(shortgrass)
        return
    end
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    inst.components.hackable.hacksleft = inst.components.hackable.maxhacks
    WeevoleNestTest(inst)
end

local function MakeBarren(inst)
    inst.AnimState:PlayAnimation("picked",true)
    inst.components.hackable.hacksleft = 0
    inst.components.childspawner:StopSpawning()
end

local function MakeEmpty(inst)
    inst.AnimState:PlayAnimation("picked",true)
    inst.components.hackable.hacksleft = 0
    inst.components.childspawner:StopSpawning()
end

local function OnSpawnWeevole(inst, weevole)
    if inst:IsValid() then
        if inst.components.hackable and inst.components.hackable:CanBeHacked() then
            inst.AnimState:PlayAnimation("rustle", false)
            inst.AnimState:PushAnimation("idle", true)
        end
    end
    if weevole and weevole:IsValid() then
        weevole.sg:GoToState("emerge")
        print("weevole.sg:GoToState(emerge)")
    end
end

local function OnNear(inst)
    if not inst.near then
        if inst.components.hackable and inst.components.hackable:CanBeHacked() then
            inst.AnimState:PlayAnimation("rustle")
            inst.AnimState:PushAnimation("idle", true)
        end
    end
    inst.near = true
end

local function OnFar(inst)
    inst.near = false
end

local function OnSave(inst, data)
    data.weevoleinfested = inst:HasTag("weevole_infested")
end

local function OnLoad(inst, data)
    if data and data.weevoleinfested then
        MakeWeevoleden(inst)
    end
end

local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.WEEVOLEDEN_RELEASE_TIME, TUNING.WEEVOLEDEN_REGEN_TIME)
end

local function grass_tall()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local color = 0.75 + math.random() * 0.25

    inst.AnimState:SetBank("grass_tall")
    inst.AnimState:SetBuild("grass_tall")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetTime(math.random() * 2)
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("grass.png")

    inst:AddTag("gustable")
    inst:AddTag("grass_tall")
    inst:AddTag("plant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(DigUp)
    inst.components.workable:SetWorkLeft(1)

    inst:AddComponent("hackable")
    inst.components.hackable.max_cycles = TUNING.GRASS_CYCLES
    inst.components.hackable.cycles_left = TUNING.GRASS_CYCLES
    inst.components.hackable.hacksleft = 2.5
    inst.components.hackable.maxhacks = 2.5
    inst.components.hackable:SetUp("cutgrass", TUNING.VINE_REGROW_TIME)
    inst.components.hackable:SetOnHackedFn(OnHack)
    inst.components.hackable:SetOnRegenFn(OnRegen)
    inst.components.hackable:SetMakeBarrenFn(MakeBarren)
    inst.components.hackable:SetMakeEmptyFn(MakeEmpty)

    inst:AddComponent("shearable")
    inst.components.shearable:SetUp("cutgrass", 2)

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "weevole"
    inst.components.childspawner:SetRegenPeriod(TUNING.WEEVOLEDEN_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.WEEVOLEDEN_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.WEEVOLEDEN_MAX_WEEVOLES)
    inst.components.childspawner:SetSpawnedFn(OnSpawnWeevole)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.WEEVOLEDEN_RELEASE_TIME, TUNING.WEEVOLE_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.WEEVOLEDEN_REGEN_TIME, TUNING.WEEVOLE_ENABLED)
    if not TUNING.WEEVOLE_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst:AddComponent("creatureprox")
    inst.components.creatureprox:SetOnNear(OnNear)
    inst.components.creatureprox:SetOnFar(OnFar)
    inst.components.creatureprox:SetDist(0.75, 1)

    MakeHackableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, 0)
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
    -- inst.components.burnable:MakeDragonflyBait(1)  -- dst don't use

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnPreLoad = OnPreLoad

    return inst
end

local function OnInit(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst:Remove()
    local grass_tall_infected = SpawnPrefab("grass_tall")
    grass_tall_infected.Transform:SetPosition(x, y, z)
    MakeWeevoleden(grass_tall_infected)
end

local function grass_tall_bunche_patch()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    inst:DoTaskInTime(0, OnInit)

    --[[Non-networked entity]]

    return inst
end

return Prefab("grass_tall", grass_tall, assets, prefabs),
    Prefab("grass_tall_bunche_patch", grass_tall_bunche_patch, assets, prefabs)

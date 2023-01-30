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

local function get_status(inst, viewer)
    return not (inst.components.burnable and inst.components.burnable:IsBurning()) and
            inst.components.hackable and not inst.components.hackable:CanBeHacked() and "PICKED"
            or nil
end

local function dig_up(inst, chopper)
    if inst.components.hackable and inst.components.hackable:CanBeHacked() then
        inst.components.lootdropper:SpawnLootPrefab("cutgrass")
    end

    inst.components.lootdropper:SpawnLootPrefab("dug_grass")
    inst:Remove()
end

local function start_spawning(inst, isdusk)
    if inst.components.childspawner and inst.components.hackable:CanBeHacked() then
        local frozen = (inst.components.freezable and inst.components.freezable:IsFrozen())
        if not frozen and not TheWorld.state.isday then
            inst.components.childspawner:StartSpawning()
        end
    end
end

local function stop_spawning(inst, isday)
    if inst.components.childspawner and isday then
        inst.components.childspawner:StopSpawning()
    end
end

local function make_weevoleden(inst)
    inst:AddTag("weevole_infested")
    inst:WatchWorldState("isdusk", start_spawning)
    inst:WatchWorldState("isday", stop_spawning)
end

local function remove_weevoleden(inst)
    inst:RemoveTag("weevole_infested")
    inst:StopWatchingWorldState("isdusk", start_spawning)
    inst:StopWatchingWorldState("isday", stop_spawning)
end

local function weevole_nest_test(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 12, {"grass_tall"})
    local weevole_ents = TheSim:FindEntities(x, y, z, 12, {"weevole_infested"})

    if #weevole_ents < 1 and math.random() < #ents / 100 then
        local ent = ents[math.random(#ents)]
        make_weevoleden(ent)
    end
end

local function spawn_weevole(inst, target)
    local weevole = inst.components.childspawner:SpawnChild()
    if weevole then
        local spawnpos = inst:GetPosition()
        spawnpos = spawnpos + TheCamera:GetDownVec()
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
        spawn_weevole(inst, target)
    end

    if inst.components.hackable and inst.components.hackable.hacksleft <= 0 then
        inst.AnimState:PlayAnimation("fall")
        inst.AnimState:PushAnimation("picked", true)
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_drop")
        if inst:HasTag("weevole_infested")then
            remove_weevoleden(inst)
        end
    else
        inst.AnimState:PlayAnimation("chop")
        inst.AnimState:PushAnimation("idle",true)
    end

    if inst.components.pickable then
        inst.components.pickable:MakeEmpty()
    end

    if not from_shears then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/grass_tall/machete")
    end
end

local function OnRegen(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    inst.components.hackable.hacksleft = inst.components.hackable.maxhacks
    weevole_nest_test(inst)
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

local function OnSpawnWeevole(inst)
    if inst:IsValid() then
        if inst.components.hackable and inst.components.hackable:CanBeHacked() then
            inst.AnimState:PlayAnimation("rustle", false)
            inst.AnimState:PushAnimation("idle", true)
        end
    end
end

local function OnPlayerNear(inst)
    if not inst.playernear then
        if inst.components.hackable and inst.components.hackable:CanBeHacked() then
            inst.AnimState:PlayAnimation("rustle")
            inst.AnimState:PushAnimation("idle", true)
        end
    end
    inst.playernear = true
end

local function OnPlayerFar(inst)
    inst.playernear = false
end

local function OnSave(inst, data)
    data.weevoleinfested = inst:HasTag("weevole_infested")
end

local function OnLoad(inst, data)
    if data and data.weevoleinfested then
        make_weevoleden(inst)
    end
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
    inst.MiniMapEntity:SetIcon("grass.tex")

    inst:AddTag("gustable")
    inst:AddTag("grass_tall")
    inst:AddTag("plant")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = get_status

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)

    inst:AddComponent("hackable")
    inst.components.hackable.max_cycles = 20
    inst.components.hackable.cycles_left = 20
    inst.components.hackable.hacksleft = 2.5
    inst.components.hackable.maxhacks = 2.5
    inst.components.hackable:SetUp("cutgrass", TUNING.VINE_REGROW_TIME)
    inst.components.hackable:SetOnHackedFn(OnHack)
    inst.components.hackable:SetOnRegenFn(OnRegen)
    inst.components.hackable:SetMakeBarrenFn(MakeBarren)
    inst.components.hackable:SetMakeEmptyFn(MakeEmpty)

    inst:AddComponent("shearable")
    inst.components.shearable:SetProduct("cutgrass", 2)

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "weevole"
    inst.components.childspawner:SetRegenPeriod(TUNING.WEEVOLEDEN_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.WEEVOLEDEN_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.WEEVOLEDEN_MAX_WEEVOLES)
    inst.components.childspawner:SetSpawnedFn(OnSpawnWeevole)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(OnPlayerNear)
    inst.components.playerprox:SetOnPlayerFar(OnPlayerFar)
    inst.components.playerprox:SetDist(0.75, 1)

    MakeHackableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, 0)
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
    -- inst.components.burnable:MakeDragonflyBait(1)  -- dst don't use

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function grass_tall_patch()
    local inst = grass_tall()

    inst:SetPrefabName("grass_tall")

    if not TheWorld.ismastersim then
        return inst
    end

    make_weevoleden(inst)

    return inst
end

return Prefab("forest/objects/grass_tall", grass_tall, assets, prefabs),
    Prefab("forest/objects/grass_tall_patch", grass_tall_patch, assets, prefabs)

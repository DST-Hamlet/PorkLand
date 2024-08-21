local assets =
{
    Asset("ANIM", "anim/bramble.zip"),
    Asset("ANIM", "anim/bramble1_build.zip"),
    Asset("ANIM", "anim/bramble_core.zip"),
}

local prefabs =
{
    "bramble_bulb",
}

SetSharedLootTable("bramble",
{
    {"bramble_bulb",    1.00},
    {"vine",            1.00},
    {"vine",            1.00},
    {"vine",            0.25},
    {"vine",            0.25},
})

local function PropegateHedge(inst)
    if inst.spike_spawned then
        return
    end

    if not TheWorld.state.season == SEASONS.LUSH then
        return
    end

    if inst.core and inst.core.sustainable_hedges > 0 then
        if inst.coredistance % 20 == 0 then -- split at 0, 20, 40, ...
            inst.components.bramblechain:SpawnChain(inst.Transform:GetRotation() + (PI/3))
            inst.components.bramblechain:SpawnChain(inst.Transform:GetRotation() - (PI/3))
        else
            inst.components.bramblechain:SpawnChain(inst.Transform:GetRotation())
        end
    end

    inst.spike_spawned = true
end

local function KillHedge(inst)
    if inst.components.lootdropper then
        inst.components.lootdropper:SetChanceLootTable()
    end
    inst.components.health:Kill()
end

local function OnDeath(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/attack") -- shouldn't this be in the hit state?
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/wither")

    inst.components.bramblechain:OnDeath()
end

local function OnseasonChange(inst, season)
    if season == SEASONS.LUSH  then
        return
    end

    if inst.kill_task then
        return
    end

    local time =  math.random() * TUNING.TOTAL_DAY_TIME * 2
    if inst:HasTag("bramble_core") then
        time = time / 4
    end

    inst.kill_task, inst.kill_task_info = inst:ResumeTask(time, function()
        KillHedge(inst)
    end)
end

local function OnAttacked(inst, data)
    if (data.weapon == nil or (not data.weapon:HasTag("projectile") and data.weapon.projectile == nil))
        and data.attacker and data.attacker.components.combat and data.stimuli ~= "thorns" and not data.attacker:HasTag("thorny")
        and (data.attacker.components.combat == nil or (data.attacker.components.combat.defaultdamage > 0))
        and not (data.attacker.components.inventory ~= nil and data.attacker.components.inventory:EquipHasTag("bramble_resistant")) then

        data.attacker.components.combat:GetAttacked(inst, TUNING.BRAMBLE_THORN_DAMAGE, nil, "thorns")

        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/armour/cactus")
    end
end

local function OnSave(inst, data)
    if inst.kill_task_info then
        data.kill_task = inst:TimeRemainingInTask(inst.kill_task_info)
    end

    if inst.coredistance then
        data.coredistance = inst.coredistance
    end

    if inst.spike_spawned then
        data.spike_spawned = inst.spike_spawned
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.kill_task then
        if inst.kill_task then
            inst.kill_task:Cancel()
            inst.kill_task = nil
        end

        inst.kill_task_info = nil
        inst.kill_task, inst.kill_task_info = inst:ResumeTask(data.kill_task, function() KillHedge(inst) end)
    end

    if data.coredistance then
        inst.coredistance = data.coredistance
    end

    if data.spike_spawned then
        inst.spike_spawned = data.spike_spawned
    end
end

local function spikefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("bramble_" .. math.random(1, 3))
    inst.AnimState:SetBuild("bramble1_build")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetRotation(math.random() * 360)
    inst.Transform:SetTwoFaced()

    inst:AddTag("hostile")
    inst:AddTag("bramble")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("bramblechain")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "hedge_segment"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BRAMBLE_THORN_HEALTH)

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")

    inst:SetStateGraph("SGbramble")
    inst.sg:GoToState("grow")

    MakeHauntable(inst)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)

    inst:DoTaskInTime((math.random() * 0.5) + 0.3, function()
        if not inst.spike_spawned then
            PropegateHedge(inst)
        end
    end)

    inst:WatchWorldState("season", OnseasonChange)
    OnseasonChange(inst, TheWorld.state.season)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function OnseasonChange_Main(inst, season)
    if season ~= SEASONS.LUSH then
        inst:Remove()
    end
end

local function OnSaveMain(inst, data)
    if inst.spawned then
        data.spawned = inst.spawned
    end
end

local function OnLoadMain(inst, data)
    if data and data.spawned then
       inst.spawned = data.spawned
    end
end

local function SpawnBrambles(inst)
    if inst.spawned then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = 0
    local dist = 2

    for i = 1, 4 do
        local new_spike = SpawnPrefab("bramblespike")

        local sx = x + dist * math.cos(angle)
        local sz = z + dist * math.sin(angle)

        new_spike.Transform:SetRotation(angle)
        new_spike.Transform:SetPosition(sx, 0, sz)
        new_spike.coredistance = 0
        new_spike.core = inst

        angle = angle + PI / 2
    end

    local new_spike = SpawnPrefab("bramblespike")
    new_spike.Transform:SetPosition(x, y, z)
    new_spike.coredistance = 0
    new_spike.core = inst

    local core = SpawnPrefab("bramble_core")
    core.Transform:SetPosition(x, y, z)
    core.AnimState:PlayAnimation("grow")
    core.AnimState:PushAnimation("idle")

    inst.spawned = true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sustainable_hedges = 1000 -- this is too high tbh

    inst:DoTaskInTime(0, SpawnBrambles)

    inst:WatchWorldState("season", OnseasonChange_Main)
    OnseasonChange_Main(inst, TheWorld.state.season)

    inst.OnSave = OnSaveMain
    inst.OnLoad = OnLoadMain

    return inst
end

-- dummy prefab used to register bramble spots
local function sitefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function()
        TheWorld.components.bramblemanager:RegisterBramble(inst)
    end)

    return inst
end

local function corefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("bramble_core")
    inst.AnimState:SetBuild("bramble_core")
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("bramble_core.tex")

    inst:AddTag("hostile")
    inst:AddTag("bramble")
    inst:AddTag("bramble_core")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("bramblechain")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "stalk01"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BRAMBLE_CORE_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("bramble")

    inst:AddComponent("inspectable")

    inst:SetStateGraph("SGbramble")

    MakeHauntable(inst)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)

    inst:WatchWorldState("season", OnseasonChange)
    OnseasonChange(inst, TheWorld.state.season)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return  Prefab("bramble", fn, assets, prefabs),
        Prefab("bramblespike", spikefn, assets, prefabs),
        Prefab("bramblesite", sitefn, assets, prefabs),
        Prefab("bramble_core", corefn, assets, prefabs)

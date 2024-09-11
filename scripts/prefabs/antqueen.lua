local assets =
{
    Asset("ANIM", "anim/crickant_queen_basics.zip"),
}

local prefabs =
{
    "antman_warrior",
    "antman_warrior_egg",
    "warningshadow",
    "throne_wall_large",
    "throne_wall",
}

local loot = {
    "pigcrownhat",
    "monstermeat",
    "monstermeat",
    "monstermeat",
    "monstermeat",
    "monstermeat",
    "chitin",
    "chitin",
    "chitin",
    "chitin",
    "honey",
    "honey",
    "honey",
    "honey",
    "honey",
    "bundlewrap_blueprint",
}

local spawn_positions =
{
    {x = 6, z = -6},
    {x = 6, z = 6 },
    {x = 6, z = 0 },
}

local function start_shrinking(shadow, queen)
    shadow.AnimState:SetMultColour(1, 1, 1, 0.33)
    shadow.Transform:SetScale(1.5, 1.5, 1.5)

    if queen and queen.SoundEmitter then
        queen.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")
    end

    shadow:AddComponent("colourtweener")
    shadow:AddComponent("sizetweener")

    shadow.components.colourtweener:StartTween({1, 1, 1, 0.75}, 1.5)
    shadow.components.sizetweener:StartTween(0.5, 1.5, shadow.Remove)
end

local function SpawnWarrior(inst)

    local x, y, z = inst.Transform:GetWorldPosition()
    local random_offset = spawn_positions[math.random(1, #spawn_positions)]

    local tx = x + random_offset.x + math.random(-1.5, 1.5)
    local ty = 0
    local tz = z + random_offset.z + math.random(-1.5, 1.5)

    local egg = SpawnPrefab("antman_warrior_egg")
    egg.queen = inst

    egg.components.throwable:Throw(Vector3(tx, 0, tz), inst)

    local shadow = SpawnPrefab("warningshadow")
    shadow.Transform:SetPosition(tx, 0.1, tz)
    start_shrinking(shadow, inst)

    inst.warrior_count = inst.warrior_count + 1
end

local function WarriorKilled(inst)
    if not inst:IsValid() then
        return
    end
    inst.warrior_count = inst.warrior_count - 1
    if inst.warrior_count <= 0 then
        inst.components.combat.canattack = true
        inst.warrior_count = 0
    end
end

local function UpdatePhase(inst)
    local health_percent = inst.components.health:GetPercent()

    if health_percent <= 0.75 and health_percent > 0.5 then
        inst.summon_count = 4
        inst.min_combat_cooldown = 7
        inst.max_combat_cooldown = 9
    elseif health_percent <= 0.5 and health_percent > 0.25 then
        inst.max_sanity_attack_count = 3
        inst.max_jump_attack_count = 3
        inst.min_combat_cooldown = 7
        inst.max_combat_cooldown = 7
    elseif health_percent <= 0.25 then
        inst.min_combat_cooldown = 5
        inst.max_combat_cooldown = 5
    end
end

local function OnLoad(inst, data)
    if data.currentstate then
        inst.sg:GoToState(data.currentstate)
    end

    inst.warrior_count = data.warrior_count

    UpdatePhase(inst)
end

local function OnSave(inst, data)
    data.currentstate = inst.sg.currentstate.name
    data.warrior_count = inst.warrior_count or 0
end

local brain = require("brains/antqueenbrain")

local function queen_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 2)

    inst.AnimState:SetBank ("crick_crickantqueen")
    inst.AnimState:SetBuild("crickant_queen_basics")
    inst.AnimState:AddOverrideBuild("throne")

    inst.Transform:SetScale(0.9, 0.9, 0.9)

    inst:AddTag("antqueen")
    inst:AddTag("epic")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor")

    inst:AddComponent("sleeper")
    inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("combat")
    inst.components.combat.canattack = false
    inst.components.combat.debris_immune = true
    inst.components.combat:SetOnHit(UpdatePhase)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANTQUEEN_HEALTH)
    inst.components.health:StartRegen(1, 4)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)
    inst.components.lootdropper.alwaysinfront = true
    inst.components.lootdropper.speed = 3

    inst:SetBrain(brain)
    inst:SetStateGraph("SGantqueen")

    MakeLargeFreezableCharacter(inst, "crick_ab")
    MakePoisonableCharacter(inst, "crick_torso")

    -- Used in SGantqueen
    inst.jump_attack_count = 0
    inst.max_jump_attack_count = 999999 -- 一阶段没有sanity_attack，因此只会一直使用跳跃攻击

    inst.sanity_attack_count = 0
    inst.max_sanity_attack_count = 2

    inst.summon_count = 3
    inst.current_summon_count = 0

    inst.min_combat_cooldown = 13
    inst.max_combat_cooldown = 13

    inst.warrior_count = 0

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.SpawnWarrior = SpawnWarrior
    inst.WarriorKilled = WarriorKilled

    inst.OnEntitySleep = function(inst)
        inst.sg:GoToState("sleep")
        inst.components.combat.target = nil
        inst.chamber_exit_time = GetTime()
    end

    inst.OnEntityWake = function(inst)
        if inst.last_attack_time and inst.chamber_exit_time then
            inst.last_attack_time = GetTime() - (inst.chamber_exit_time - inst.last_attack_time)
        end
    end

    inst:ListenForEvent("attacked", function()
        if inst.sg.currentstate.name == "sleeping" or inst.sg.currentstate.name == "sleep" then
            if inst.components.combat.target == nil then
                inst.components.combat:SetTarget(FindClosestPlayerToInst(inst, 50, true))
                inst.sg:GoToState("wake")
            end
        end
    end)

    return inst
end

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
            inst._pfpos = inst:GetPosition()
            TheWorld.Pathfinder:AddWall(inst._pfpos:Get())
        end
    elseif inst._pfpos ~= nil then
        TheWorld.Pathfinder:RemoveWall(inst._pfpos:Get())
        inst._pfpos = nil
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function MakeObstacle(inst)
    inst.Physics:SetActive(true)
    inst._ispathfinding:set(true)
end

-- These "thrones" are just entities used to properly create queens physics
-- Maybe we should build custom collision mesh
local function MakeThrone(name, physics_size)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, physics_size)

        inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
        MakeObstacle(inst)
        -- Delay this because makeobstacle sets pathfinding on by default
        -- but we don't to handle it until after our position is set
        inst:DoTaskInTime(0, InitializePathFinding)

        inst:AddTag("throne_wall")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return Prefab("antqueen", queen_fn, assets, prefabs),
       MakeThrone("throne_wall", 0.25),
       MakeThrone("throne_wall_large", 0.5)

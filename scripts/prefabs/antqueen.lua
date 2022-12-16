require "brains/antqueenbrain"
require "stategraphs/SGantqueen"

local assets=
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

local loot =
{
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

local function SpawnWarrior(inst)

    local x, y, z = inst.Transform:GetWorldPosition()
    local random_offset = spawn_positions[math.random(1, #spawn_positions)]

    x = x + random_offset.x + math.random(-1.5, 1.5)
    y = 35
    z = z + random_offset.z + math.random(-1.5, 1.5)

    local egg = SpawnPrefab("antman_warrior_egg")
    egg.queen = inst
    egg.Physics:Teleport(x, y, z)

    egg.start_grounddetection(egg)

    local shadow = SpawnPrefab("warningshadow")
    shadow.Transform:SetPosition(x, 0.2, z)
    shadow:shrink(1.5, 1.5, 0.25)

    inst.warrior_count = inst.warrior_count + 1
end

local function WarriorKilled(inst)
    inst.warrior_count = inst.warrior_count - 1
    if inst.warrior_count == 0 and inst.components.combat then
        inst.warrior_count = 0
    end
end

local function OnHit(inst)

    local health_percent = inst.components.health:GetPercent()

    if health_percent <= 0.75 and health_percent > 0.5 then
        inst.summon_count = 4
        inst.min_combat_cooldown = 3
        inst.max_combat_cooldown = 5
    elseif health_percent <= 0.5 and health_percent > 0.25 then
        inst.max_sanity_attack_count = 3
        inst.max_jump_attack_count = 3
        inst.min_combat_cooldown = 1
        inst.max_combat_cooldown = 3
    elseif health_percent <= 0.25 then
        inst.min_combat_cooldown = 1
        inst.max_combat_cooldown = 1
    end

end

-- local function exitinterior(inst,world, data)
    -- if data.to_target.prefab and data.to_target:HasTag("anthill_outside") then
        -- inst.sg:GoToState("sleep")
        -- inst.components.combat.target = nil
    -- end
-- end

-- local function doorused(data, inst)
--     if data.from_door.components.door.target_interior == "FINAL_QUEEN_CHAMBER" then
--         if inst.last_attack_time and inst.chamber_exit_time then
--             inst.last_attack_time = GetTime() - (inst.chamber_exit_time - inst.last_attack_time)
--         end
--     else
--         inst.chamber_exit_time = GetTime()
--     end
-- end

local function OnAttacked(inst, data)
if inst.sg.currentstate.name == "sleeping" or inst.sg.currentstate.name == "sleep" then
    if inst.components.combat.target == nil then
            inst.components.combat:SetTarget(data.attacker)
            inst.sg:GoToState("wake")
        end
    end
end

--死亡时判断生成次数是否小于2
local function ondeath(inst)
    inst:DoTaskInTime(2, function()
    local pigcrownhat = SpawnPrefab("pigcrownhat")
    local x,y,z = inst.Transform:GetWorldPosition()

        if spawn_count < 2 then
            pigcrownhat.Transform:SetPosition(x,y,z)
        end
    end)
end

local function onload(inst, data)
    if data.currentstate then
        inst.sg:GoToState(data.currentstate)
    end

    inst.warrior_count = data.warrior_count
end

local function onsave(inst, data)
    data.currentstate = inst.sg.currentstate.name
    data.warrior_count = inst.warrior_count or 0
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetScale(0.9, 0.9, 0.9)

    MakeObstaclePhysics(inst, 2)

    inst.AnimState:SetBank ("crick_crickantqueen")
    inst.AnimState:SetBuild("crickant_queen_basics")
    inst.AnimState:AddOverrideBuild("throne")

    inst:AddTag("antqueen")
    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")

    inst:AddComponent("sleeper")
    -- inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("combat")
    inst.components.combat.debris_immune = true
    inst.components.combat:SetOnHit(OnHit)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ANTQUEEN_HEALTH)
    inst.components.health:StartRegen(1, 4)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("inspectable")

    local brain = require "brains/antqueenbrain"
    inst:SetBrain(brain)
    inst:SetStateGraph("SGantqueen")

    -- Used in SGantqueen
    inst.jump_count = 1
    inst.jump_attack_count = 0
    inst.max_jump_attack_count = 3

    inst.sanity_attack_count = 0
    inst.max_sanity_attack_count = 2

    inst.summon_count = 3
    inst.current_summon_count = 0

    inst.min_combat_cooldown = 5
    inst.max_combat_cooldown = 7

    MakeLargeFreezableCharacter(inst, "pig_torso")
    MakePoisonableCharacter(inst)

    inst.warrior_count = 0
    inst.SpawnWarrior = SpawnWarrior
    inst.WarriorKilled = function () WarriorKilled(inst) end

    -- TheWorld:ListenForEvent("exitinterior", exitinterior)
    -- TheWorld:ListenForEvent("doorused", doorused)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", ondeath)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

local function make_throne_fn(size)

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()

        inst:AddTag("throne_wall")
        MakeObstaclePhysics(inst, size)

        return inst
    end

    return fn
end

local function makethronewall(name, physics_size, assets, prefabs)
    return Prefab("common/objects/" .. name, make_throne_fn(physics_size), assets, prefabs )
end

return Prefab("antqueen", fn, assets, prefabs),
       makethronewall("throne_wall",       0.25, assets, prefabs),
       makethronewall("throne_wall_large", 0.5,  assets, prefabs)

require("stategraphs/commonstates")
local easing = require("easing")
local AncientHulkUtil = require("prefabs/ancient_hulk_util")

local SpawnBarrier = AncientHulkUtil.SpawnBarrier
local DropAncientRobots = AncientHulkUtil.DropAncientRobots
local ShootProjectile = AncientHulkUtil.ShootProjectile
local DoSectorAOE = AncientHulkUtil.DoSectorAOE

local SHAKE_DIST = 40
local BEAM_RADIUS = 7

local function Teleport(inst)
    local target = inst.components.combat.target or inst
    local target_position = target:GetPosition()

    local theta = math.random() * 2 * PI

    local offset, radius
    while not offset do
        radius = 12 + math.random() * 5
        offset = FindWalkableOffset(target_position, theta, radius, 12, true)
    end

    inst.Physics:SetActive(true)
    inst.Transform:SetPosition(target_position.x + offset.x, 0, target_position.z + offset.z)
    inst.sg:GoToState("telportin")
end

local function LaunchProjectile(inst, direction)
    local x, y, z = inst.Transform:GetWorldPosition()
    local theta = direction - PI / 6 + math.random() * PI / 3
    local radius = 6 + math.random() * 6

    local offset = FindWalkableOffset(Vector3(x, y, z), theta, radius, 12, true)

    if offset then
        local spawn_point = Vector3(x, y, z) + offset
        local dx = spawn_point.x - x
        local dz = spawn_point.z - z
        local rangesq = dx * dx + dz * dz
        local max_range = TUNING.FIRE_DETECTOR_RANGE
        local speed = easing.linear(rangesq, 15, 3, max_range * max_range)

        local projectile = SpawnPrefab("ancient_hulk_mine")
        projectile.AnimState:PlayAnimation("spin_loop",true)
        projectile.Transform:SetPosition(x, 1, z)
        projectile.components.complexprojectile:SetHorizontalSpeed(speed)
        projectile.components.complexprojectile:SetGravity(-25)
        projectile.components.complexprojectile:Launch(spawn_point, inst, inst)
        projectile.owner = inst
    end
end

local function SpawnBurns(inst, radius, start_angle, end_angle)
    start_angle = start_angle * DEGREES
    end_angle = end_angle * DEGREES

    local num_burns = 5
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local down = TheCamera:GetDownVec()
    local angle = math.atan2(down.z, down.x) + start_angle
    local angle_difference = (end_angle - start_angle) / num_burns
    for _ = 1, num_burns do
        local offset = Vector3(math.cos(angle), 0, math.sin(angle)) * radius
        local burns_position = pt + offset
        SpawnPrefab("ancient_hulk_laser").Transform:SetPosition(burns_position.x, burns_position.y, burns_position.z)
        SpawnPrefab("ancient_hulk_laserscorch").Transform:SetPosition(burns_position.x, burns_position.y, burns_position.z)
        angle = angle + angle_difference
    end
end

local function DoFootstep(inst)
    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/step", {intensity = math.random()})
end

local actionhandlers =
{

}

local events =
{
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),

    EventHandler("activate", function(inst) inst.sg:GoToState("activate") end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
        end,

        timeline =
        {
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.2) end),
            TimeEvent(46 * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.5) end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "activate",
        tags = {"busy"},

        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/gears_LP", "gears")
        end,

        timeline =
        {
            TimeEvent(46  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/start") end),

            TimeEvent(0   * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.2) end),
            TimeEvent(25  * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.3) end),
            TimeEvent(50  * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.4) end),
            TimeEvent(75  * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 1.0) end),
            TimeEvent(100 * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.7) end),

            TimeEvent(1   * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(4   * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(24  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(27  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(36  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(39  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(42  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(65  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(83  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(86  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(103 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(106 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.25) end),
            TimeEvent(113 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.25) end),

            TimeEvent(6   * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(10  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(12  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active", nil, 0.5) end),
            TimeEvent(20  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(40  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/active") end),
            TimeEvent(44  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/active") end),
            TimeEvent(54  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(56  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(58  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(60  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),

            TimeEvent(37  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step") end),
            TimeEvent(101 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step") end),

            TimeEvent(28  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
            TimeEvent(46  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
            TimeEvent(64  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
            TimeEvent(84  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
            TimeEvent(128 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),

            TimeEvent(106 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/taunt") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hit",
        tags = {"hit"},

        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/hit")
            inst.AnimState:PlayAnimation("hit")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy", "canrotate"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_chomp")
        end,

        timeline =
        {
            TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/dig") end),
            TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/drag") end),
            TimeEvent(15 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy", "death"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("death_explode")
            RemovePhysicsColliders(inst)
        end,

        timeline =
        {
            TimeEvent(2  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.2}) end),
            TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.3}) end),
            TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.4}) end),
            TimeEvent(26 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.6}) end),
            TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.8}) end),
            TimeEvent(36 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 1.0}) end),

            TimeEvent(17 * FRAMES, function (inst) inst.SoundEmitter:KillSound("gears") end),

            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/death") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/death_taunt") end),

            TimeEvent(61 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.5) end),
            TimeEvent(67 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.6) end),
            TimeEvent(77 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.7) end),
            TimeEvent(79 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.6) end),
            TimeEvent(82 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode") end),

            TimeEvent(81 * FRAMES, function(inst)
                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, 2, inst, SHAKE_DIST)

                local x,y,z = inst.Transform:GetWorldPosition()
                for i = -1, 1 do
                    for j = -1, 1 do
                        SpawnPrefab("ancient_hulk_laserscorch").Transform:SetPosition(x + i, 0, z + j)
                    end
                end

                inst:DoTaskInTime(2, function()
                    local head = SpawnPrefab("ancient_robot_head")
                    head.spawntask:Cancel()
                    head.spawntask = nil
                    head.spawned = true
                    head:AddTag("dormant")
                    head.Transform:SetPosition(x, y + 8, z)
                    head.sg:GoToState("fall")
                end)

                DoSectorAOE(inst, 6)
                inst.components.lootdropper:DropLoot()
                DropAncientRobots(inst)
            end),
        },
    },

    State{
        name = "telportout_pre",
        tags = {"busy", "teleport"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("telportout") end ),
        },

        timeline =
        {
            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/teleport_out") end),

            TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.25) end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.25) end),
        },
    },

    State{
        name = "telportout",
        tags = {"busy", "teleport"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:Hide()
                inst:DoTaskInTime(0.5, Teleport)
            end ),
        },

        timeline =
        {
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),

            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.15) end),
            TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.25) end),
            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/step", nil, 0.25) end),
            TimeEvent(39 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step") end),

            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.2) end),

            TimeEvent(5 * FRAMES, function(inst) DoSectorAOE(inst, 4) end),
            TimeEvent(10 * FRAMES, function(inst)
                inst.Physics:SetActive(false)
                inst.DynamicShadow:Enable(false)
                DoSectorAOE(inst, 5)
            end),
            TimeEvent(15 * FRAMES, function(inst) DoSectorAOE(inst, 5) end),
            TimeEvent(20 * FRAMES, function(inst) DoSectorAOE(inst, 4) end),
        },
    },

    State{
        name = "telportin",
        tags = {"busy", "teleport"},

        onenter = function(inst)
            inst:Show()
            inst.DynamicShadow:Enable(true)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_in")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
                inst.components.timer:StartTimer("teleport_cd", TUNING.ANCIENT_HULK_TELEPORT_CD)
            end ),
        },

        timeline =
        {
            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/teleport_in") end),

            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),
            TimeEvent(16 * FRAMES, function(inst) TheMixer:PushMix("boom") end),
            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound") end),
            TimeEvent(17 * FRAMES, function(inst)
                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, 2, inst, SHAKE_DIST)
                inst.components.groundpounder:GroundPound()
            end),
            TimeEvent(19 * FRAMES, function(inst) TheMixer:PopMix("boom") end),
        },
    },

    State{
        name = "bomb_pre",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("bomb")
            end),
        },

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),
            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),
            TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),

            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),

            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
            TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro", nil, 0.5) end),
        },
    },

    State{
        name = "bomb",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_loop")
        end,

        timeline =
        {
            TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),

            TimeEvent(1  * FRAMES, function(inst) LaunchProjectile(inst, 0) end),
            TimeEvent(6  * FRAMES, function(inst) LaunchProjectile(inst, PI * 0.5) end),
            TimeEvent(11 * FRAMES, function(inst) LaunchProjectile(inst, PI) end),
            TimeEvent(16 * FRAMES, function(inst) LaunchProjectile(inst, PI * 1.5) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("bomb_pst")
            end),
        },
    },

    State{
        name = "bomb_pst",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        timeline =
        {
            TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),
            TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),
            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust", nil, 0.5) end),

            TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),

            TimeEvent(11 * FRAMES, function(inst)inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
        },
    },

    State{
        name = "lob",
        tags = {"busy", "canrotate"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_lob")
        end,

        timeline =
        {
            TimeEvent(30 * FRAMES, function(inst)
                local lob_position
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    lob_position = inst.components.combat.target:GetPosition()
                else
                    local radius = 15
                    local angle = inst.Transform:GetRotation() * DEGREES
                    local offset = Vector3(math.cos(angle), 0, math.sin(-angle)) * radius
                    local x, y, z = inst.Transform:GetWorldPosition()
                    lob_position = Vector3(x + offset.x, y + offset.y, z + offset.z)
                end

                inst.orbs = inst.orbs -1
                if inst.orbs <= 0 then
                    inst:DoTaskInTime(10, function() inst.orbs = 2 end)
                end
                ShootProjectile(inst, lob_position)
            end),

            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser_pre") end),
            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = math.random()}) end),
        },

        onupdate = function(inst)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(Vector3(inst.components.combat.target.Transform:GetWorldPosition()))
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },

    State{
        name = "spin",
        tags = {"busy"},

        onenter = function(inst)
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_circle")
            inst.components.combat.playerdamagepercent = 1
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step", nil, 0.5) end),
            TimeEvent(68 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),
            TimeEvent(70 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),
            TimeEvent(82 * FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step", nil, 0.5) end),
            TimeEvent(90 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),

            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
            TimeEvent(62 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),

            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(26 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),

            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/spin") end),
            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/burn_LP", "laserburn") end),
            TimeEvent(49 * FRAMES, function(inst) inst.SoundEmitter:KillSound("laserburn") end),

            TimeEvent(49 * FRAMES, function(inst) TheMixer:PushMix("boom") end),
            TimeEvent(51 * FRAMES, function(inst) TheMixer:PopMix("boom") end),

            TimeEvent(37 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 0, 45)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0})
                SpawnBurns(inst, BEAM_RADIUS, 0, 45)
            end),
            TimeEvent(39 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 45, 90)
                SpawnBurns(inst, BEAM_RADIUS, 45, 90)
            end),
            TimeEvent(40 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 90, 135)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.3})
                SpawnBurns(inst, BEAM_RADIUS, 90, 135)
            end),
            TimeEvent(41 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 135, 180)
                SpawnBurns(inst, BEAM_RADIUS, 135, 180)
            end),
            TimeEvent(42 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 180, 225)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.5})
                SpawnBurns(inst, BEAM_RADIUS, 180, 225)
            end),
            TimeEvent(45 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 225, 270)
                SpawnBurns(inst, BEAM_RADIUS, 225, 270)
            end),
            TimeEvent(47 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 270, 315)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.7})
                SpawnBurns(inst, BEAM_RADIUS, 270, 315)
            end),
            TimeEvent(48 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 315, 360)
                SpawnBurns(inst, BEAM_RADIUS, 315, 360)
            end),
            TimeEvent(50 * FRAMES, function(inst)
                DoSectorAOE(inst, BEAM_RADIUS, 0, 45)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 1})
                SpawnBurns(inst, BEAM_RADIUS, 0, 45)
            end),
        },

        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.components.timer:StartTimer("spin_cd", TUNING.ANCIENT_HULK_SPIN_CD)
            inst.components.combat.playerdamagepercent = 0.5
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },

    State{
        name = "barrier",
        tags = {"busy"},

        onenter = function(inst)
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_barrier")
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step") end),
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/barrier") end),
            TimeEvent(67 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")end),
            TimeEvent(67 * FRAMES, function(inst) TheMixer:PushMix("boom")end),
            TimeEvent(90 * FRAMES, function(inst) TheMixer:PopMix("boom")end),
            TimeEvent(64 * FRAMES, function(inst)
                inst.components.groundpounder.damageRings = 4
                inst.components.groundpounder.destructionRings = 4
                inst.components.groundpounder.numRings = 4
                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, 2, inst, SHAKE_DIST)
                inst.components.groundpounder:GroundPound()

                local pt = Vector3(inst.Transform:GetWorldPosition())
                inst:DoTaskInTime(0.6, SpawnBarrier, pt)

                local fx = SpawnPrefab("metal_hulk_ring_fx")
                fx.Transform:SetPosition(pt.x, pt.y, pt.z)
            end),
        },

        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.components.timer:StartTimer("barrier_cd", TUNING.ANCIENT_HULK_BARRIER_CD)
            inst.components.groundpounder.damageRings = 2
            inst.components.groundpounder.destructionRings = 3
            inst.components.groundpounder.numRings = 3
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(12 * FRAMES, function(inst) DoFootstep(inst) end),
        TimeEvent(16 * FRAMES, function(inst) DoFootstep(inst) end),
        TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/step", {intensity = math.random()}) end),
        TimeEvent(3  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
    },
}, nil, nil, true, {endonenter = DoFootstep})

CommonStates.AddRunStates(states, nil,
{
    startrun = "charge_pre",
    run = "charge_roar_loop",
    stoprun = "charge_pst",
}, false, false)

return StateGraph("ancient_hulk", states, events, "idle", actionhandlers)

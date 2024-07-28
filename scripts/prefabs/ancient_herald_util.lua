local function GetRandomOffset(pt, radius, offset_y)
    local theta = math.random() * TWOPI
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)

    if offset then
        if offset_y then
            offset.y = offset.y + offset_y
        end
        return pt + offset
    end
end

local function DoSpawnObject(player, spawn_pt, prefab, prefab_postinit)
    local inst = SpawnPrefab(prefab)

    if inst.Physics then
        inst.Physics:Teleport(spawn_pt:Get())
    else
        inst.Transform:SetPosition(spawn_pt.x, spawn_pt.y, spawn_pt.z)
    end

    inst:AddTag("aporkalypse_cleanup")

    if inst.components.combat then
        inst.components.combat:SuggestTarget(player)
    end

    if prefab_postinit then
        prefab_postinit(inst)
    end
end

local function SpawnRandomInRange(player, prefab, min_count, max_count, radius, offset_y, prefab_postinit)
    if not player or player.components.health:IsDead() then
        return
    end

    local pt = player:GetPosition()
    offset_y = offset_y or 0

    local count = math.random(min_count, max_count)
    for i = 1, count do
        local spawn_point = GetRandomOffset(pt, radius, offset_y)
        if spawn_point then
            DoSpawnObject(player, spawn_point, prefab, prefab_postinit)
        end
    end
end

local function NightmarePostInit(nightmare)
    nightmare:WatchWorldState("isaporkalypse", function(inst, isaporkalypse)
        if not isaporkalypse and nightmare:HasTag("aporkalypse_cleanup") then
            nightmare:Remove()
        end
    end)
end

local function SpawnNightmares(player, inst)
    SpawnRandomInRange(player, GetRandomItem({"nightmarebeak", "crawlingnightmare"}), 2, 4, 10, nil, NightmarePostInit)
end

local function SpawnGhosts(player, inst)
    SpawnRandomInRange(player, "pigghost", 4, 6, 10)
end

local function CancelFrogRain(inst)
    if inst._frog_rain_task then
        inst._frog_rain_task:Cancel()
        inst._frog_rain_task = nil
    end
end

local function SpawnFrogRain(player, inst)
    CancelFrogRain(inst)

    local count = 0
    local max = 5

    inst._frog_rain_task = inst:DoPeriodicTask(0.2, function()
        SpawnRandomInRange(player, "frog_poison", 1, 4, 8, 35, function(frog)
            print(frog.GUID, frog.sg.currentstate.name)
            frog.sg:GoToState("fall")
            print(frog.GUID, frog.sg.currentstate.name)
        end)

        count = count + 1
        if count >= max then
            CancelFrogRain(inst)
        end
    end)
end

local function SpawnFireRain(player, inst)
    SpawnRandomInRange(player, "firerain", 1, 4, 6, nil, function(firerain) firerain:StartStepWithDelay(math.random() * 2) end)
end

local function SpawnHerald(player, inst)
    if not player or player.components.health:IsDead() then
        return
    end

    local herald = GetClosestInstWithTag("ancient_herald", player, 20)

    if herald == nil then
        if not player:HasTag("inside_interior") then
            SpawnRandomInRange(player, "ancient_herald", 1, 1, 10, nil, function(herald) herald.sg:GoToState("appear") end)
        end
    else
        herald.components.combat:SuggestTarget(player)
    end
end

return {
    CancelFrogRain = CancelFrogRain,
    SpawnFireRain = SpawnFireRain,
    SpawnFrogRain = SpawnFrogRain,
    SpawnGhosts = SpawnGhosts,
    SpawnHerald = SpawnHerald,
    SpawnNightmares = SpawnNightmares,
}

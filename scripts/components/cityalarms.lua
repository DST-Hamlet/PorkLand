local STATUS = {
    CALM = 1,
    ALARMED = 2,
}

local PIG_SIGHT_RANGE = TUNING.CITY_PIG_GUARD_TARGET_DIST
-- local PIG_CITY_LIMITS = 30
local TOWER_SIGHT_RANGE = 30

local Cityalarms = Class(function(self, inst)
    self.inst = inst

    self.cities = {}
end)

local function spawn_guard_pig_from_offscreen(inst, city, threat)
    local SCREENDIST = 35
    local pos = threat:GetPosition()
    for i = 1, 50 do
        local start_angle = math.random() * TWOPI
        local offset = FindWalkableOffset(pos, start_angle, SCREENDIST, 8, false)
        if offset == nil then
            -- well it's gotta go somewhere!
            pos = pos + Vector3(SCREENDIST * math.cos(start_angle), 0, SCREENDIST * math.sin(start_angle))
        else
            pos = pos + offset
        end
        if threat:GetDistanceSqToPoint(pos) >= SCREENDIST * SCREENDIST then
            inst:DoTaskInTime(0, function()
                local prefab = city == 2 and "pigman_royalguard_2" or "pigman_royalguard"
                local guard = SpawnPrefab(prefab)
                if guard.Physics then
                    guard.Physics:Teleport(pos:Get())
                else
                    guard.Transform:SetPosition(pos:Get())
                end
                guard.components.citypossession:SetCity(city)
                guard.components.knownlocations:RememberLocation("home", pos)
                guard:PushEvent("attacked", {
                    attacker = threat,
                    damage = 0,
                    weapon = nil,
                })
            end)
            break
        end
    end
end

local function spawn_guard_pig_from_tower(inst, city, tower, threat)
    local guard = SpawnPrefab(tower.components.spawner:GetChildName())
    local rad = 0.5
    if tower.Physics then
        local prad = tower.Physics:GetRadius() or 0
        rad = rad + prad
    end

    if guard.Physics then
        local prad = guard.Physics:GetRadius() or 0
        rad = rad + prad
    end

    local pos = tower:GetPosition()
    local start_angle = math.random() * TWOPI

    local offset = FindWalkableOffset(pos, start_angle, rad, 8, false)
    if offset == nil then
        -- well it's gotta go somewhere!
        pos = pos + Vector3(rad * math.cos(start_angle), 0, rad * math.sin(start_angle))
    else
        pos = pos + offset
    end
    if guard.Physics then
        guard.Physics:Teleport(pos:Get())
    else
        guard.Transform:SetPosition(pos:Get())
    end
    tower:onvacate()
    if guard.components.knownlocations then
        guard.components.knownlocations:RememberLocation("home", pos)
    end
    guard.components.citypossession:SetCity(city)
    guard:PushEvent("attacked", {
        attacker = threat,
        damage = 0,
        weapon = nil,
    })
end

function Cityalarms:OnSave()
    local data = {}
    data.cities = {}

    local refs = {}

    for c, city in ipairs(self.cities) do
        data.cities[c] = {}
        data.cities[c].threats = {}
        for i, threat in ipairs(city.threats) do
            table.insert(data.cities[c].threats, threat.GUID)
            table.insert(refs, threat.GUID)
        end
        data.cities[c].guards = city.guards
        data.cities[c].min_guard_response = city.min_guard_response
        data.cities[c].guard_ready_time = TUNING.SEG_TIME * 2
        data.cities[c].status = city.status

        if self.cities[c].watch_threat_task then
            data.cities[c].watch_threat_task = true
        end
    end
    return data, refs
end

function Cityalarms:OnLoad(data)
    self.cities = {}
    for c, city in ipairs(data.cities) do
        self.cities[c] = {
            guards = city.guards,
            min_guard_response = city.min_guard_response,
            guard_ready_time = city.guard_ready_time,
            status = city.status,
            threats = {},
        }
    end
end

function Cityalarms:LoadPostPass(newents, data)
    for c, city in ipairs(self.cities) do
        for _, threat in ipairs(data.cities[c].threats) do
            local child = newents[threat]
            if child then
                table.insert(self.cities[c].threats, child.entity)
            end
        end
    end
end

function Cityalarms:ReleaseGuards(city, threat)
    local x, y, z = threat.Transform:GetWorldPosition()

    for i = 1, self.cities[city].guards do
        -- GRAB GUARD PIGS IN RANGE
        local guards = TheSim:FindEntities(x, y, z, 30, {"guard"})
        local guard_assigned = false

        for _, guard in ipairs(guards) do
            if guard.components.combat.target == nil and not guard:HasTag("alarmed_picked") then
                guard:AddTag("alarmed_picked")
                guard:DoTaskInTime(math.random(), function()
                    guard:RemoveTag("alarmed_picked")
                    guard:PushEvent("attacked", {
                        attacker = threat,
                        damage = 0,
                        weapon = nil,
                    })
                end)
                guard_assigned = true
                break
            end
        end

        -- FIND A TOWER TO SPAWN PIGS IN RANGE
        if not guard_assigned then
            local towers = TheSim:FindEntities(x, y, z, 30, {"guard_tower"})
            local tower = nil
            if #towers > 0 then
                local closest_distance = nil
                for _, tower in ipairs(towers) do
                    local distance = tower:GetDistanceSqToInst(threat)
                    if not closest_distance or distance < closest_distance then
                        tower = tower
                        closest_distance = distance
                    end
                end
            end

            if tower then
                self.inst:DoTaskInTime(math.random(), function()
                    spawn_guard_pig_from_tower(self.inst, city, tower, threat)
                end)
            else
                spawn_guard_pig_from_offscreen(self.inst, city, threat)
            end
        end

        self.cities[city].guards = self.cities[city].guards - 1
    end
end

function Cityalarms:ReadyGuard(city)
    if self.cities[city].guards < self.cities[city].min_guard_response then
        self.cities[city].guards = self.cities[city].guards + 1
    end
    if self.cities[city].guards >= self.cities[city].min_guard_response and self.cities[city].status == STATUS.ALAMED then
        self:ReleaseGuards(city, self.cities[city].threats[#self.cities[city].threats])
    end
    if self.cities[city].task then
        self.cities[city].task:Cancel()
        self.cities[city].task = nil
    end
    self.cities[city].task = self.inst:DoTaskInTime(self.cities[city].guard_ready_time, function()
        self:ReadyGuard(city)
    end)
end

-- function Cityalarms:isThreat(target)
--     for _, city in ipairs(self.cities) do
--         for _, threat in ipairs(city.threats) do
--             if target == threat then
--                 return true
--             end
--         end
--     end
--     return false
-- end

-- Modified from ChangeStatus, ignore_royal_status is currently unused
function Cityalarms:TriggerAlarm(city, threat, ignore_royal_status)
    -- threat can be interiorspawner's destroyer which doesn't have Transform
    if not (threat:IsValid() and threat.Transform) then
        return
    end

    -- print("&&&&&&&&&&&&&&&&&&&&", threat.prefab)

    if threat.components.combat then
        while threat.components.combat.proxy do
            threat = threat.components.combat.proxy
        end
    end

    if not threat:HasTag("pigroyalty") or ignore_royal_status then
        local x, y, z = threat.Transform:GetWorldPosition()

        local range = PIG_SIGHT_RANGE

        if threat:HasTag("sneaky") then
            range = TUNING.SNEAK_SIGHTDISTANCE
        end

        local playmusic = false
        local pigs = TheSim:FindEntities(x, y, z, range, {"city_pig"})
        for _, pig in ipairs(pigs) do
            if pig.components.combat.target == nil then
                -- print("ALERTING FROM WITNESS")
                pig:DoTaskInTime(math.random(), function()
                    pig:PushEvent("attacked", {
                        attacker = threat,
                        damage = 0,
                        weapon = nil,
                    })
                end)
                playmusic = true
            end
        end

        local tower_range = threat:HasTag("sneaky") and TUNING.SNEAK_SIGHTDISTANCE or TOWER_SIGHT_RANGE
        local towers = TheSim:FindEntities(x, y, z, tower_range, {"guard_tower"})
        for _, tower in ipairs(towers) do
            tower:CallGuards(threat)
            playmusic = true
        end

        if threat:HasTag("player") and playmusic then
            -- TODO: Add danger music
            -- GetPlayer().components.dynamicmusic:OnStartDanger()
        end
    end
end

function Cityalarms:AddCity(idx)
    local citydata = {
        guards = 3,
        min_guard_response = 3,
        guard_ready_time = TUNING.SEG_TIME * 2,
        status = STATUS.CALM,
        threats = {},
    }

    self.cities[idx] = citydata
    -- self.cities[idx].task = self.inst:DoTaskInTime(self.cities[idx].guard_ready_time, function() self:ReadyGuard(idx) end)
end

-- function Cityalarms:OnUpdate(dt)
-- end

function Cityalarms:LongUpdate(dt)
    for c, city in ipairs(self.cities) do
        for i = 1, math.floor(dt / self.cities[c].guard_ready_time) do
            self:ReadyGuard(c)
        end
        -- local newtime = dt % self.cities[c].guard_ready_time
        if self.cities[c].task then
            self.cities[c].task:Cancel()
            self.cities[c].task = nil
        end
        -- self.cities[c].task = self.inst:DoTaskInTime(self.cities[c].guard_ready_time, function() self:ReadyGuard(c) end)
    end
end

return Cityalarms

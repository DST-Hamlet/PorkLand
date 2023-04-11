return Class(function(self, inst)

    assert(TheWorld.ismastersim, "GlowflyCocoonSpawner should not exist on client")

    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    local SPAWN_CHANCE = 0.4

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    self.inst = inst

    -- Private
    local _world = TheWorld

    local _waitforspawn = false
    local _spawntask
    local _spawntaskinfo

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function TrySpawnCocoons(inst)
        if inst:IsAsleep() then
            return false
        end

        local pt = inst:GetPosition()
        local radius = 5 + math.random() * 10
        local start_angle = math.random() * 2 * PI
        local offset = FindWalkableOffset(pt, start_angle, radius, 10)

        if offset ~= nil then
            local newpoint = pt + offset
            for i = 1, math.random(6, 10) do
                radius = math.random() * 8
                start_angle = math.random() * 2 * PI
                local suboffset = FindWalkableOffset(newpoint, radius, start_angle, 10)
                if suboffset ~= nil then
                    local spawnpt = newpoint + suboffset
                    if IsSurroundedByLand(spawnpt, nil, nil, 3) then
                        local cocoon = SpawnPrefab("glowfly_cocoon")
                        cocoon.Physics:Teleport(spawnpt:Get())
                    end
                end
            end
        end

        return true
    end

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnEntitySleep(inst)
        if _waitforspawn then
            _spawntask, _spawntaskinfo = nil, nil
            _waitforspawn = not TrySpawnCocoons(inst)
        end
    end

    local function OnSpawnCocoons(src)
        if math.random() < SPAWN_CHANCE then
            if inst:IsAsleep() then
                _spawntask, _spawntaskinfo = inst:ResumeTask(math.random(1, 29), TrySpawnCocoons)
            else
                _waitforspawn = true
            end
        end
    end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    -- Register events
    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("spawncocoons", OnSpawnCocoons, _world)

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    function self:OnSave()
        local data = {waitforspawn = _waitforspawn}

        if _spawntaskinfo ~= nil then
            data.spawntasktime = inst:TimeRemainingInTask(_spawntaskinfo)
        end

        return data
    end

    function self:OnLoad(data)
        if data ~= nil then
            _waitforspawn = data.waitforspawn

            if data.spawntasktime then
                _spawntask, _spawntaskinfo = inst:ResumeTask(data.spawntasktime, TrySpawnCocoons)
            end
        end

        OnEntitySleep(inst)
    end
end)

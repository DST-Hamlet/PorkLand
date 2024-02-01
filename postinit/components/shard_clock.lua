local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function MakeShardClock(self, clocktype)
    assert(clocktype, "Invalid clocktype for new network")

    --------------------------------------------------------------------------
    --[[ Shard_Clock ]]
    --------------------------------------------------------------------------

    assert(TheWorld.ismastersim, "Shard_Clock_[" .. clocktype .. "] should not exist on client")

    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    local NUM_PHASES = 3 --keep in sync with clock.lua PHASE_NAMES table

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    local inst = self.inst

    -- Private
    local _world = TheWorld
    local _ismastershard = _world.ismastershard

    -- Network
    local _segs = {}
    for i = 1, NUM_PHASES do
        table.insert(_segs, net_smallbyte(inst.GUID, "shard_clock_" .. clocktype .. ".segs["..tostring(i).."]"))
    end
    local _cycles = net_ushortint(inst.GUID, "shard_clock_" .. clocktype .. "._cycles", "clockdirty_" .. clocktype)
    local _phase = net_tinybyte(inst.GUID, "shard_clock_" .. clocktype .. "._phase", "clockdirty_" .. clocktype)
    local _moonphase = net_tinybyte(inst.GUID, "shard_clock_" .. clocktype .. "._moonphase", "clockdirty_" .. clocktype)
    local _mooniswaxing = net_bool(inst.GUID, "shard_clock_" .. clocktype .. "._mooniswaxing", "clockdirty_" .. clocktype)
    local _totaltimeinphase = net_float(inst.GUID, "shard_clock_" .. clocktype .. "._totaltimeinphase", "clockdirty_" .. clocktype)
    local _remainingtimeinphase = net_float(inst.GUID, "shard_clock_" .. clocktype .. "._remainingtimeinphase", "clockdirty_" .. clocktype)

    --------------------------------------------------------------------------
    --[[ Private event listeners ]]
    --------------------------------------------------------------------------

    local OnClockUpdate = _ismastershard and function(src, data)
        local dirty = false

        for i, v in ipairs(_segs) do
            if v:value() ~= data.segs[i] then
                v:set(data.segs[i])
                dirty = true
            end
        end

        if _cycles:value() ~= data.cycles then
            _cycles:set(data.cycles)
            dirty = true
        end

        if _phase:value() ~= data.phase then
            _phase:set(data.phase)
            dirty = true
        end

        if _moonphase:value() ~= data.moonphase then
            _moonphase:set(data.moonphase)
            dirty = true
        end

        if _mooniswaxing:value() ~= data.mooniswaxing then
            _mooniswaxing:set(data.mooniswaxing)
            dirty = true
        end

        if _totaltimeinphase:value() ~= data.totaltimeinphase then
            _totaltimeinphase:set(data.totaltimeinphase)
            dirty = true
        end

        if dirty then
            _remainingtimeinphase:set(data.remainingtimeinphase)
        else
            _remainingtimeinphase:set_local(data.remainingtimeinphase)
        end
    end or nil

    local OnForceSync = _ismastershard and function()
        _remainingtimeinphase:set_local(_remainingtimeinphase:value())
        _remainingtimeinphase:set(_remainingtimeinphase:value())
    end or nil

    local OnClockDirty = not _ismastershard and function()
        local data =
        {
            segs = {},
            cycles = _cycles:value(),
            moonphase = _moonphase:value(),
            mooniswaxing = _mooniswaxing:value(),
            phase = _phase:value(),
            totaltimeinphase = _totaltimeinphase:value(),
            remainingtimeinphase = _remainingtimeinphase:value(),
        }
        for i, v in ipairs(_segs) do
            table.insert(data.segs, v:value())
        end

        _world:PushEvent("secondary_clockupdate_" .. clocktype, data)
    end or nil

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    if _ismastershard then
        -- Register master shard events
        inst:ListenForEvent("forcesyncclock", OnForceSync, _world)
        inst:ListenForEvent("master_clockupdate_" .. clocktype, OnClockUpdate, _world)
    else
        -- Register network variable sync events
        inst:ListenForEvent("clockdirty_" .. clocktype, OnClockDirty)
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end

AddComponentPostInit("shard_clock", function(self, inst)
    local _world = TheWorld

    if not IA_ENABLED then
        if _world.ismastershard then
            local OnClockUpdate = inst:GetEventCallbacks("master_clockupdate", _world, "scripts/components/shard_clock.lua")
            local _remainingtimeinphase = ToolUtil.GetUpvalue(OnClockUpdate, "_remainingtimeinphase")

            local OnForceSync = function()
                _remainingtimeinphase:set_local(_remainingtimeinphase:value())
                _remainingtimeinphase:set(_remainingtimeinphase:value())
            end

            inst:ListenForEvent("forcesyncclock", OnForceSync, _world)
        end

        self.MakeShardClock = MakeShardClock
    end

    self:MakeShardClock("plateau")
end)

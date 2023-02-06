local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)


local function GetElapsedTime(cycles, phase, segs, remainingtimeinphase)
    local NUM_SEGS = 16
    local PHASES = {day = 1, dusk = 2, night = 3}

    if type(phase) == "string" then
        phase = PHASES[phase]
    end

    for i, seg in pairs(segs) do
        if type(i) == "string" then
            segs[PHASES[i]] = seg
        end
    end

    local elapsedtime = cycles * NUM_SEGS * TUNING.SEG_TIME
    for i = 1, phase do
        if i < phase then
            elapsedtime = elapsedtime + (segs[i] or 0) * TUNING.SEG_TIME
        else
            elapsedtime = elapsedtime + segs[i] * TUNING.SEG_TIME - remainingtimeinphase
        end
    end

    return elapsedtime
end

local function MakeDefaultClock(self, inst)
    if self.clocks["default"] then
        return
    end

    self.clocks["default"] = {}

    local _world = TheWorld
    if _world.ismastersim then
        self.clocks["default"]["ms_setclocksegs"] = inst:GetEventCallbacks("ms_setclocksegs", _world, "scripts/components/clock.lua")
        self.clocks["default"]["ms_setphase"] = inst:GetEventCallbacks("ms_setphase", _world, "scripts/components/clock.lua")
        self.clocks["default"]["ms_nextphase"] = inst:GetEventCallbacks("ms_nextphase", _world, "scripts/components/clock.lua")
        self.clocks["default"]["ms_nextcycle"] = inst:GetEventCallbacks("ms_nextcycle", _world, "scripts/components/clock.lua")
        self.clocks["default"]["ms_setmoonphase"] = inst:GetEventCallbacks("ms_setmoonphase", _world, "scripts/components/clock.lua")
        self.clocks["default"]["ms_lockmoonphase"] = inst:GetEventCallbacks("ms_lockmoonphase", _world, "scripts/components/clock.lua")
        self.clocks["default"]["ms_setmoonphasestyle"] = inst:GetEventCallbacks("ms_setmoonphasestyle",_world, "scripts/components/clock.lua")
        self.clocks["default"]["ms_simunpaused"] = inst:GetEventCallbacks("ms_simunpaused", _world, "scripts/components/clock.lua")
    end

    self["GetTimeUntilPhase_default"] = self.GetTimeUntilPhase
    self["AddMoonPhaseStyle_default"] = self.AddMoonPhaseStyle

    local _OnUpdate = self.OnUpdate
    self["OnUpdate_default"] = function(self, dt, data)
        if data and _world.ismastershard then
            local _data = self:OnSave()
            local _elapsedtime = GetElapsedTime(_data.cycles, _data.phase, _data.segs, _data.remainingtimeinphase)  -- tihs clock time
            local elapsedtime = GetElapsedTime(data.cycles, data.phase, data.segs, data.remainingtimeinphase)

            dt = elapsedtime - _elapsedtime

            if dt >= TUNING.SEG_TIME then
                _world:DoTaskInTime(0, _world.PushEvent, "forcesyncclock")
            end
        end

        local __OnUpdate = self.OnUpdate
        self.OnUpdate = _OnUpdate
        _OnUpdate(self, dt)  -- Prevent calling OnUpdate of other clocks
        self.OnUpdate = __OnUpdate
    end
end

local function MakeClock(self, clocktype)
    assert(clocktype, "Invalid clocktype for new network")

    if self.clocks[clocktype] then
        return
    end

    self.clocks[clocktype] = {}

    --------------------------------------------------------------------------
    --[[ Clock ]]
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    local NUM_SEGS = 16

    local PHASE_NAMES = -- keep in sync with shard_clock.lua NUM_PHASES
    {
        "day",
        "dusk",
        "night",
    }
    local PHASES = table.invert(PHASE_NAMES)

    local MOON_PHASE_NAMES =
    {
        "new",
        "quarter",
        "half",
        "threequarter",
        "full",
    }
    local MOON_PHASES = table.invert(MOON_PHASE_NAMES)
    local MOON_PHASE_LENGTHS =
    {
        [MOON_PHASES.new] =             1,
        [MOON_PHASES.quarter] =         3,
        [MOON_PHASES.half] =            3,
        [MOON_PHASES.threequarter] =    3,
        [MOON_PHASES.full] =            1,
    }
    local MOON_PHASE_CYCLES = {}
    -- Waxing (1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5)
    for i = 1, #MOON_PHASE_NAMES do
        for x = 1, MOON_PHASE_LENGTHS[i] do
            table.insert(MOON_PHASE_CYCLES, i)
        end
    end
    -- Waning (4, 4, 4, 3, 3, 3, 2, 2, 2)
    for i = #MOON_PHASE_NAMES - 1, 2, -1 do
        for x = 1, MOON_PHASE_LENGTHS[i] do
            table.insert(MOON_PHASE_CYCLES, i)
        end
    end
    MOON_PHASE_LENGTHS = nil

    -- if you add to this, you'll need to update uiclock._moon_builds for it to mean anything
    local MOON_PHASE_STYLE_NAMES =
    {
        "default", --"moon_phases",
        "alter_active", -- "moonalter_phases",
        "glassed_default",
        "glassed_alter_active",
    }
    local MOON_PHASE_STYLES = table.invert(MOON_PHASE_STYLE_NAMES)

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    local inst = self.inst

    -- Private
    local _world = TheWorld
    local _ismastersim = _world.ismastersim
    local _ismastershard = _world.ismastershard
    local _mooomphasecycle = 1
    local _moonphaselocked = false -- Note: This does not save/load

    local _segsdirty = true
    local _cyclesdirty = true
    local _phasedirty = true
    local _moonphasedirty = true
    local _moonphasestyledirty = true

    -- Network
    local _segs = {}
    for i, v in ipairs(PHASE_NAMES) do
        _segs[i] = net_smallbyte(inst.GUID, "clock_" .. clocktype .. "._segs." .. v, "segsdirty_" .. clocktype)
    end
    local _cycles = net_ushortint(inst.GUID, "clock_" .. clocktype .. "._cycles", "cyclesdirty_" .. clocktype)
    local _phase = net_tinybyte(inst.GUID, "clock_" .. clocktype .. "._phase", "phasedirty_" .. clocktype)
    local _moonphase = net_tinybyte(inst.GUID, "clock_" .. clocktype .. "._moonphase", "moonphasedirty_" .. clocktype)
    local _mooniswaxing = net_bool(inst.GUID, "clock_" .. clocktype .. "._mooniswaxing", "moonphasedirty_" .. clocktype)
    local _totaltimeinphase = net_float(inst.GUID, "clock_" .. clocktype .. "._totaltimeinphase")
    local _remainingtimeinphase = net_float(inst.GUID, "clock_" .. clocktype .. "._remainingtimeinphase")
    local _moonphasestyle = net_tinybyte(inst.GUID, "clock_" .. clocktype .. "._moonphasestyle", "moonphasestyledirty_" .. clocktype)

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    self["GetTimeUntilPhase_" .. clocktype] = function(self, phase)
        local target_phase = nil
        for i, p in pairs(PHASE_NAMES) do
            if p == phase then
                target_phase = i
                break
            end
        end
        local cur_phase = _phase:value()
        if target_phase ~= nil and target_phase ~= cur_phase then
            local time = _remainingtimeinphase:value()

            cur_phase = (cur_phase % #PHASE_NAMES) + 1
            while (cur_phase ~= target_phase) do
                time = time + (_segs[cur_phase]:value() * TUNING.SEG_TIME)
                cur_phase = (cur_phase % #PHASE_NAMES) + 1
            end

            return time
        end

        return 0
    end

    self["AddMoonPhaseStyle_" .. clocktype] = function(self, style)
        table.insert(MOON_PHASE_STYLE_NAMES, style)
        MOON_PHASE_STYLES[style] = #MOON_PHASE_STYLE_NAMES
    end

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function SetDefaultSegs()
        local totalsegs = 0
        for i, v in ipairs(_segs) do
            v:set(TUNING[string.upper(PHASE_NAMES[i]) .. "_SEGS_DEFAULT"] or 0)
            totalsegs = totalsegs + v:value()
        end

        if totalsegs ~= NUM_SEGS then
            for i, v in ipairs(_segs) do
                v:set(0)
            end
            _segs[PHASES.day]:set(NUM_SEGS)
        end
    end

    local function GetMoonPhase()
        local waxing = _mooomphasecycle < #MOON_PHASE_CYCLES / 2
        return MOON_PHASE_CYCLES[_mooomphasecycle], waxing
    end

    local CalcTimeOfDay = _ismastersim and function()
        local time_of_day = _totaltimeinphase:value() - _remainingtimeinphase:value()
        for i = 1, _phase:value()-1 do
            time_of_day = time_of_day + _segs[i]:value()*TUNING.SEG_TIME
        end
        return time_of_day
    end or nil

    local ForceResync = _ismastersim and function(netvar)
        netvar:set_local(netvar:value())
        netvar:set(netvar:value())
    end or nil

    --------------------------------------------------------------------------
    --[[ Private event listeners ]]
    --------------------------------------------------------------------------

    local function OnPlayerActivated()
        _segsdirty = true
        _cyclesdirty = true
        _phasedirty = true
        _moonphasedirty = true
        _moonphasestyledirty = true
    end

    local OnSetClockSegs = _ismastersim and function(src, segs)
        -- cache the current time of day so we can restore it after the segs change
        local time_of_day = CalcTimeOfDay()

        -- change the segs to the new setup
        if segs then
            local totalsegs = 0
            for i, v in ipairs(_segs) do
                v:set(segs[PHASE_NAMES[i]] or 0)
                totalsegs = totalsegs + v:value()
            end
            assert(totalsegs == NUM_SEGS, "Invalid number of time segs")
        else
            SetDefaultSegs()
        end

        local new_phase, new_remainingtimeinphase
        for i, seg in ipairs(_segs) do
            local phase_time = seg:value()*TUNING.SEG_TIME
            if time_of_day <= phase_time then
                new_phase = i
                new_remainingtimeinphase = phase_time - time_of_day
                break
            else
                time_of_day = time_of_day - phase_time
            end
        end

        _phase:set(new_phase)
        _totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
        _remainingtimeinphase:set(new_remainingtimeinphase)
    end or nil

    local OnSetPhase = _ismastersim and function(src, phase)
        phase = PHASES[phase]
        if phase then
            _phase:set(phase)
            _totaltimeinphase:set(_segs[phase]:value() * TUNING.SEG_TIME)
            _remainingtimeinphase:set(_totaltimeinphase:value())
        end
        self:LongUpdate(0)
    end or nil

    local OnNextPhase = _ismastersim and function()
        _remainingtimeinphase:set(0)
        self:LongUpdate(0)
    end or nil

    local OnNextCycle = _ismastersim and function()
        _phase:set(#PHASE_NAMES)
        _remainingtimeinphase:set(0)
        self:LongUpdate(0)
    end or nil

    local OnSetMoonPhase = _ismastersim and function(world, data)
        local phase_num = MOON_PHASES[data.moonphase]
        for i = (data.iswaxing and 1 or #MOON_PHASE_CYCLES/2), #MOON_PHASE_CYCLES do
            if MOON_PHASE_CYCLES[i] == phase_num then
                _mooomphasecycle = i
                break
            end
        end

        local moonphase, waxing = GetMoonPhase()
        _moonphase:set(moonphase)
        _mooniswaxing:set(waxing)
    end or nil

    local OnLockMoonPhase = _ismastersim and function(world, data)
        _moonphaselocked = data ~= nil and data.lock
    end or nil

    local OnSetMoonPhaseStyle = _ismastersim and function(world, data)
        _moonphasestyle:set(((data ~= nil and data.style ~= nil) and MOON_PHASE_STYLES[data.style] or MOON_PHASE_STYLES.default) - 1)
    end or nil

    local OnSimUnpaused = _ismastersim and function()
        --Force resync values that client may have simulated locally
        ForceResync(_remainingtimeinphase)
    end or nil

    local OnClockUpdate = _ismastersim and not _ismastershard and function(src, data)
        for i, v in ipairs(_segs) do
            v:set(data.segs[i])
        end
        _cycles:set(data.cycles)
        _phase:set(data.phase)
        _moonphase:set(data.moonphase)
        _mooniswaxing:set(data.mooniswaxing)
        _totaltimeinphase:set(data.totaltimeinphase)
        _remainingtimeinphase:set(data.remainingtimeinphase)
        self:LongUpdate(0)
    end or nil

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    -- Initialize network variables
    SetDefaultSegs()
    _cycles:set(0)
    _phase:set(PHASES.day)
    _moonphase:set(1)
    _mooniswaxing:set(true)
    _moonphasestyle:set(0)
    _totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
    _remainingtimeinphase:set(_totaltimeinphase:value())

    -- Register network variable sync events
    inst:ListenForEvent("segsdirty_" .. clocktype, function() _segsdirty = true end)
    inst:ListenForEvent("cyclesdirty_" .. clocktype, function() _cyclesdirty = true end)
    inst:ListenForEvent("phasedirty_" .. clocktype, function() _phasedirty = true end)
    inst:ListenForEvent("moonphasedirty_" .. clocktype, function() _moonphasedirty = true end)
    inst:ListenForEvent("moonphasestyledirty_" .. clocktype, function() _moonphasestyledirty = true end)
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)

    if _ismastersim then
        -- Register master simulation events
        self.clocks[clocktype]["ms_setclocksegs"] = OnSetClockSegs
        self.clocks[clocktype]["ms_setphase"] = OnSetPhase
        self.clocks[clocktype]["ms_nextphase"] = OnNextPhase
        self.clocks[clocktype]["ms_nextcycle"] = OnNextCycle
        self.clocks[clocktype]["ms_setmoonphase"] = OnSetMoonPhase
        self.clocks[clocktype]["ms_lockmoonphase"] = OnLockMoonPhase
        self.clocks[clocktype]["ms_setmoonphasestyle"] = OnSetMoonPhaseStyle
        self.clocks[clocktype]["ms_simunpaused"] = OnSimUnpaused

        inst:ListenForEvent("ms_setclocksegs_" .. clocktype, OnSetClockSegs, _world)
        inst:ListenForEvent("ms_setmoonphase", OnSetMoonPhase, _world)
        inst:ListenForEvent("ms_lockmoonphase", OnLockMoonPhase, _world)
        inst:ListenForEvent("ms_setmoonphasestyle", OnSetMoonPhaseStyle, _world)

        if not _ismastershard then
            -- Register secondary shard events
            inst:ListenForEvent("secondary_clockupdate_" .. clocktype, OnClockUpdate, _world)
        end
    end

    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------

    --[[
        Client updates time on its own, while server force syncs to correct it
        at the end of each segment.  Client cannot change segments on its own,
        and must wait for a server sync to change segments.
    --]]
    local function OnUpdate(self, dt, data)
        if data and _ismastershard then
            local segs = {}
            for i, v in ipairs(_segs) do
                segs[i] = v:value()
            end

            local _elapsedtime = GetElapsedTime(_cycles:value(), _phase:value(), segs, _remainingtimeinphase:value())  -- tihs clock time
            local elapsedtime = GetElapsedTime(data.cycles, data.phase, data.segs, data.remainingtimeinphase)

            dt = elapsedtime - _elapsedtime

            if dt >= TUNING.SEG_TIME then
                _world:DoTaskInTime(0, _world.PushEvent, "forcesyncclock")
            end
        end

        local remainingtimeinphase = _remainingtimeinphase:value() - dt

        if remainingtimeinphase > 0 then
            --Advance time in current phase
            local numsegsinphase = _segs[_phase:value()]:value()
            local prevseg = numsegsinphase > 0 and math.ceil(_remainingtimeinphase:value() / _totaltimeinphase:value() * numsegsinphase) or 0
            local nextseg = numsegsinphase > 0 and math.ceil(remainingtimeinphase / _totaltimeinphase:value() * numsegsinphase) or 0

            if prevseg == nextseg then
                --Client and server tick independently within current segment
                _remainingtimeinphase:set_local(remainingtimeinphase)
            elseif _ismastersim then
                --Server sync to client when segment changes
                _remainingtimeinphase:set(remainingtimeinphase)
            else
                --Client must wait at end of segment for a server sync
                remainingtimeinphase = numsegsinphase > 0 and nextseg / numsegsinphase * _totaltimeinphase:value() or 0
                _remainingtimeinphase:set_local(math.min(remainingtimeinphase + .001, _remainingtimeinphase:value()))
            end
        elseif _ismastershard then
            --Advance to next phase
            _remainingtimeinphase:set_local(0)

            while _remainingtimeinphase:value() <= 0 do
                _phase:set((_phase:value() % #PHASE_NAMES) + 1)
                _totaltimeinphase:set(_segs[_phase:value()]:value() * TUNING.SEG_TIME)
                _remainingtimeinphase:set(_totaltimeinphase:value())

                if _phase:value() == 1 then
                    --Advance to next cycle
                    _cycles:set(_cycles:value() + 1)
                    _world:PushEvent("ms_cyclecomplete_" .. clocktype, _cycles:value())
                    -- Note: It is the seasons component that handles adjusting the number of day/dusk/night segments

                    if not _moonphaselocked then
                        _mooomphasecycle = (_mooomphasecycle % #MOON_PHASE_CYCLES) + 1
                    end

                    --Advance to next moon phase. After waxing/waning changes, moon phase is now advanced at the beginning of each day.
                    local moonphase, waxing = GetMoonPhase()
                    if moonphase ~= _moonphase:value() then
                        _moonphase:set(moonphase)
                    end
                    if waxing ~= _mooniswaxing:value() then
                        _mooniswaxing:set(waxing)
                    end
                end
            end

            if remainingtimeinphase < 0 then
                OnUpdate(self, -remainingtimeinphase)
                return
            end
        else
            --Clients and secondary shards must wait at end of phase for a server sync
            _remainingtimeinphase:set_local(math.min(.001, _remainingtimeinphase:value()))
        end

        if _segsdirty then
            local data = {}
            for i, v in ipairs(_segs) do
                data[PHASE_NAMES[i]] = v:value()
            end
            _world:PushEvent("clocksegschanged_" .. clocktype, data)
            _segsdirty = false
        end

        if _cyclesdirty then
            _world:PushEvent("cycleschanged_" .. clocktype, _cycles:value())
            _cyclesdirty = false
        end

        if _phasedirty then
            _world:PushEvent("phasechanged_" .. clocktype, PHASE_NAMES[_phase:value()])
            _phasedirty = false
        end

        if _moonphasedirty then
            --"moonphasechanged" deprecated, still pushing for old mods
            _world:PushEvent("moonphasechanged_" .. clocktype, MOON_PHASE_NAMES[_moonphase:value()])
            _world:PushEvent("moonphasechanged2_" .. clocktype, { moonphase = MOON_PHASE_NAMES[_moonphase:value()], waxing = _mooniswaxing:value() })
            _moonphasedirty = false
        end

        if _moonphasestyledirty then
            _world:PushEvent("moonphasestylechanged_" .. clocktype, { style = MOON_PHASE_STYLE_NAMES[_moonphasestyle:value() + 1] })
            _moonphasestyledirty = false
        end

        local elapsedsegs = 0
        local normtimeinphase = 0
        for i, v in ipairs(_segs) do
            if _phase:value() == i then
                normtimeinphase = 1 - (_totaltimeinphase:value() > 0 and _remainingtimeinphase:value() / _totaltimeinphase:value() or 0)
                elapsedsegs = elapsedsegs + v:value() * normtimeinphase
                break
            end
            elapsedsegs = elapsedsegs + v:value()
        end
        _world:PushEvent("clocktick_" .. clocktype, { phase = PHASE_NAMES[_phase:value()], timeinphase = normtimeinphase, time = elapsedsegs / NUM_SEGS })

        if _ismastershard then
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
            _world:PushEvent("master_clockupdate_" .. clocktype, data)
        end
    end

    self["OnUpdate_" .. clocktype] = OnUpdate

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    if _ismastersim then
        local _OnSave = self.OnSave
        function self:OnSave(...)
            local data = _OnSave(self, ...)
            data["segs" .. clocktype] = {}
            data["cycles" .. clocktype] = _cycles:value()
            data["phase" .. clocktype] = PHASE_NAMES[_phase:value()]
            data["mooomphasecycle" .. clocktype] = _mooomphasecycle
            data["totaltimeinphase" .. clocktype] = _totaltimeinphase:value()
            data["remainingtimeinphase" .. clocktype] = _remainingtimeinphase:value()

            for i, v in ipairs(_segs) do
                data["segs" .. clocktype][PHASE_NAMES[i]] = v:value()
            end

            return data
        end

        local _OnLoad = self.OnLoad
        function self:OnLoad(data, ...)
            if not data["cycles" .. clocktype] and data.cycles then
                inst:DoTaskInTime(0, function()
                    local segs = NUM_SEGS * data.cycles
                    local phasenum = PHASES[data.phase] - 1
                    while phasenum > 0 do
                        if PHASE_NAMES[phasenum] then
                            segs = segs + data.segs[PHASE_NAMES[phasenum]]
                        end
                        phasenum = phasenum - 1
                    end
                    OnUpdate(self, (TUNING.SEG_TIME * segs) + data.remainingtimeinphase)
                    self["Dump_" .. clocktype]()
                    print('"Retrofit" complete')
                end)
            else
                local totalsegs = 0
                for i, v in ipairs(_segs) do
                    v:set(data["segs" .. clocktype] and data["segs" .. clocktype][PHASE_NAMES[i]] or 0)
                    totalsegs = totalsegs + v:value()
                end

                if totalsegs ~= NUM_SEGS then
                    SetDefaultSegs()
                end

                _cycles:set(data["cycles" .. clocktype] or 0)

                if PHASES[data["phase" .. clocktype]] then
                    _phase:set(PHASES[data["phase" .. clocktype]])
                else
                    for i, v in ipairs(_segs) do
                        if v:value() > 0 then
                            _phase:set(i)
                            break
                        end
                    end
                end

                if data["mooomphasecycle" .. clocktype] ~= nil then
                    _mooomphasecycle = data["mooomphasecycle" .. clocktype]
                else
                    --retorifitting old saves
                    _mooomphasecycle = (_cycles:value() % #MOON_PHASE_CYCLES) + 1
                end

                local moonphase, waxing = GetMoonPhase()
                _moonphase:set(moonphase)
                _mooniswaxing:set(waxing)

                _totaltimeinphase:set(data["totaltimeinphase" .. clocktype] or _segs[_phase:value()]:value() * TUNING.SEG_TIME)
                _remainingtimeinphase:set(math.min(data["remainingtimeinphase" .. clocktype] or _totaltimeinphase:value(), _totaltimeinphase:value()))
            end

            return _OnLoad(self, data, ...)
        end
    end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------

    --NOTE: dont wrap debugs to allow mods easier access to upvalues
    self["Dump_" .. clocktype] = function()
        print(clocktype .. " Time of Day:", CalcTimeOfDay())

        print(clocktype .. " segs in day   ",  _segs[1]:value())
        print(clocktype .. " segs in dusk  ",  _segs[2]:value())
        print(clocktype .. " segs in night ",  _segs[3]:value())

        print(clocktype .. " cycles ",  _cycles:value())
        print(clocktype .. " phase ",  PHASE_NAMES[_phase:value()])
        print(clocktype .. " moonphase2 ",  MOON_PHASE_NAMES[_moonphase:value()])
        print(clocktype .. " moonwaxing ",  _mooniswaxing:value())

        print(clocktype .. " totaltimeinphase ",  _totaltimeinphase:value())
        print(clocktype .. " remainingtimeinphase ",  _remainingtimeinphase:value())
        print(clocktype .. " total segs phase ",  _totaltimeinphase:value()/TUNING.SEG_TIME)
        print(clocktype .. " remaining segs inphase ",  _remainingtimeinphase:value()/TUNING.SEG_TIME)

        local to_night =  _remainingtimeinphase:value() + (PHASE_NAMES[_phase:value()] == "day" and _segs[2]:value() or 0) * TUNING.SEG_TIME
        print(clocktype .. " Time Until Night:", to_night, to_night/TUNING.SEG_TIME)
    end

    self["GetDebugString_" .. clocktype] = function()
        return string.format(clocktype .. " %d %s: %2.2f : %2.2f (moon cycle: %d)", _cycles:value() + 1, PHASE_NAMES[_phase:value()], _remainingtimeinphase:value(), _segs[_phase:value()]:value(), _mooomphasecycle)
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end

local function SetClock(self, clocktype)
    local events = {"clocksegschanged", "cycleschanged", "phasechanged", "moonphasestylechanged", "moonphasechanged", "moonphasechanged2", "clocktick"}
    local master_events = {"ms_setphase", "ms_nextphase", "ms_nextcycle", "ms_simunpaused"}

    if clocktype ~= "default" and not self.clocks[clocktype] then
        self:MakeClock(clocktype)
    end

    self.current_clock = clocktype

    local inst = self.inst
    local _world = TheWorld

    if _world.ismastersim then
        for _clocktype, data in pairs(self.clocks) do
            for _, event in ipairs(master_events) do
                inst:RemoveEventCallback(event, data[event], _world)

                if self.current_clock == _clocktype then
                    inst:ListenForEvent(event, data[event], _world)
                end
            end

            local suffix = _clocktype == "default" and "" or ("_" .. _clocktype)
            if _world.ismastershard then
                inst:RemoveEventCallback("master_clockupdate" .. suffix, self.OnClockUpdate, _world)

                if self.current_clock == _clocktype then
                    inst:ListenForEvent("master_clockupdate" .. suffix, self.OnClockUpdate, _world)
                end
            end
        end
    end

    local suffix = self.current_clock == "default" and "" or ("_" .. self.current_clock)
    for _, event in ipairs(events) do
        for _clocktype in pairs(self.clocks) do
            local suffix = _clocktype == "default" and "" or ("_" .. _clocktype)
            _world:AddPushEventPostFn(event .. suffix, SilenceEvent)
        end
        _world:AddPushEventPostFn(event .. suffix, function() return event end)
    end
end

local function GetTimeUntilPhase(self, phase, ...)
    return self["GetTimeUntilPhase_" .. self.current_clock](self, phase)
end

local function AddMoonPhaseStyle(self, style, ...)
    for clocktype in pairs(self.clocks) do
        self["AddMoonPhaseStyle_" .. clocktype](style, ...)
    end
end

local function OnUpdate(self, dt, ...)
    self["OnUpdate_" .. self.current_clock](self, dt, ...)
end

AddComponentPostInit("clock", function(self, inst)
    local _world = TheWorld
    local _ismastershard = _world.ismastershard

    if not IA_ENABLED then
        self.current_clock = "default"
        self.clocks = {}

        MakeDefaultClock(self, inst)
        self.MakeClock = MakeClock
        self.SetClock = SetClock
        self.GetTimeUntilPhase = GetTimeUntilPhase
        self.AddMoonPhaseStyle = AddMoonPhaseStyle

        self.OnUpdate = OnUpdate
        self.OnStaticUpdate = self.OnUpdate
        self.LongUpdate = self.OnUpdate

        self.OnClockUpdate = _ismastershard and function (src, data)
            for clocktype in pairs(self.clocks) do
                if clocktype ~= self.current_clock then
                    self["OnUpdate_" .. clocktype](self, 0, data)
                end
            end
        end or nil
    end

    local _clocktype = _world.topology.pl_worldgen_version and _world.topology and _world.topology.overrides and _world.topology.overrides.pl_clocktype or "default"
    self:MakeClock("plateau")
    self:SetClock(_clocktype)
end)

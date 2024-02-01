local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")

local function MakeSeasons(self, clock_type, seasons_data)
    assert(clock_type, "Invalid clock_type for new network")

    if self.clocks[clock_type] then
        return
    end

    self.clocks[clock_type] = true
    seasons_data = seasons_data or {}

    --------------------------------------------------------------------------
    -- [[ Seasons class definition ]]
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- [[ Constants ]]
    --------------------------------------------------------------------------

    local SEASON_NAMES = seasons_data.names or
    {
        "autumn",
        "winter",
        "spring",
        "summer",
    }
    local SEASONS = table.invert(SEASON_NAMES)

    local MODE_NAMES =
    {
        "cycle",
        "endless",
        "always",
    }
    local MODES = table.invert(MODE_NAMES)

    local NUM_CLOCK_SEGS = 16
    local DEFAULT_CLOCK_SEGS = seasons_data.segs or
    {
        autumn = {day = 8, dusk = 6, night = 2},
        winter = {day = 5, dusk = 5, night = 6},
        spring = {day = 5, dusk = 8, night = 3},
        summer = {day = 11, dusk = 1, night = 4},
    }

    local ENDLESS_PRE_DAYS = 10
    local ENDLESS_RAMP_DAYS = 10
    local ENDLESS_DAYS = 10000

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    local inst = self.inst

    -- Private
    local _world = TheWorld
    local _ismastersim = _world.ismastersim
    local _ismastershard = _world.ismastershard
    local _isplateau = clock_type == "plateau"

    -- Master simulation
    local _mode
    local _premode
    local _segs
    local _segmod
    local _preaporkalypseseasondata = {}
    local _israndom = {}

    -- Network
    local _season = net_tinybyte(inst.GUID, "seasons_" .. clock_type .. "._season", "seasondirty_" .. clock_type)
    local _totaldaysinseason = net_byte(inst.GUID, "seasons_" .. clock_type .. "._totaldaysinseason", "seasondirty_" .. clock_type)
    local _elapseddaysinseason = net_ushortint(inst.GUID, "seasons_" .. clock_type .. "._elapseddaysinseason", "seasondirty_" .. clock_type)
    local _remainingdaysinseason = net_byte(inst.GUID, "seasons_" .. clock_type .. "._remainingdaysinseason", "seasondirty_" .. clock_type)
    local _endlessdaysinseason = net_bool(inst.GUID, "seasons_" .. clock_type .. "._endlessdaysinseason", "seasondirty_" .. clock_type)

    local _preaporkalypseseason
    local _preaporkalypseseasonprogress
    if _isplateau then
        _preaporkalypseseason = net_tinybyte(inst.GUID, "seasons_" .. clock_type .. "._preaporkalypseseason", "seasondirty_" .. clock_type)
        _preaporkalypseseasonprogress = net_float(inst.GUID, "seasons_" .. clock_type .. "._preaporkalypseseasonprogress", "seasondirty_" .. clock_type)
    end

    local _lengths = {}
    for i, v in ipairs(SEASON_NAMES) do
        _lengths[i] = net_byte(inst.GUID, "seasons_" .. clock_type .. "._lengths." .. v, "lengthsdirty_" .. clock_type)
    end

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local GetPrevSeason = _ismastersim and function()
        if _premode or _mode == MODES.always then
            return _season:value()
        end

        local season = _season:value()

        if SEASON_NAMES[season] == "aporkalypse" then
            return season
        end

        while true do
            season = season > 1 and season - 1 or #SEASON_NAMES
            if _lengths[season]:value() > 0 or season == _season:value() then
                return season
            end
        end

        return season
    end or nil

    local GetNextSeason = _ismastersim and function()
        if not _premode and (_mode == MODES.endless or _mode == MODES.always) then
            return _season:value()
        end

        local season = _season:value()

        if SEASON_NAMES[season] == "aporkalypse" then
            return season
        end

        while true do
            season = (season % #SEASON_NAMES) + 1
            if _lengths[season]:value() > 0 or season == _season:value() then
                return season
            end
        end

        return season
    end or nil

    local GetModifiedSegs = _ismastersim and function(segs, mod)
        local importance = {"day", "dusk", "night"}
        table.sort(importance, function(a,b) return mod[a] < mod[b] end)

        local retsegs = {}
        for k,v in pairs(segs) do
            retsegs[k] = math.ceil(math.clamp(v * mod[k], 0, 16))
        end

        local total = retsegs.day + retsegs.dusk + retsegs.night
        while total ~= 16 do
            for i=1, #importance do
                if total >= 16 and retsegs[importance[i]] > 1 then
                    retsegs[importance[i]] = retsegs[importance[i]] - 1
                elseif total < 16 and retsegs[importance[i]] > 0 then
                    retsegs[importance[i]] = retsegs[importance[i]] + 1
                end
                total = retsegs.day + retsegs.dusk + retsegs.night
                if total == 16 then
                    break
                end
            end
        end

        return retsegs
    end or nil

    local PushSeasonClockSegs = _ismastersim and function()
        if not _ismastershard then
            return  -- mastershard pushes its seg data to the clock, which pushes it to the secondary shards
        end

        local p = 1 - (_totaldaysinseason:value() > 0 and _remainingdaysinseason:value() / _totaldaysinseason:value() or 0)
        local toseason = p < .5 and GetPrevSeason() or GetNextSeason()
        local tosegs = _segs[toseason]
        local segs = tosegs

        if _season:value() ~= toseason then
            local fromsegs = _segs[_season:value()]
            p = .5 - math.sin(PI * p) * .5
            segs =
            {
                day = math.floor(easing.linear(p, fromsegs.day, tosegs.day - fromsegs.day, 1) + .5),
                night = math.floor(easing.linear(p, fromsegs.night, tosegs.night - fromsegs.night, 1) + .5),
            }
            segs.dusk = NUM_CLOCK_SEGS - segs.day - segs.night
        end

        segs = GetModifiedSegs(segs, _segmod)

        _world:PushEvent("ms_setclocksegs_" .. clock_type, segs)
    end or nil

    local UpdateSeasonMode = _ismastersim and function(modified_season)

        local numactiveseasons = 0
        local allowedseason = nil
        for i, length in ipairs(_lengths) do
            if length:value() > 0 then
                numactiveseasons = numactiveseasons + 1
                allowedseason = i
            end
        end

        if numactiveseasons == 1 then
            if allowedseason == _season:value() then
                _mode = MODES.always
            else
                _mode = MODES.endless
            end
        else
            _mode = MODES.cycle
        end

        if _mode == MODES.endless then
            _premode = true
            _totaldaysinseason:set(ENDLESS_PRE_DAYS * 2)
            _remainingdaysinseason:set(ENDLESS_PRE_DAYS)
            _endlessdaysinseason:set(false)
        elseif _mode == MODES.always then
            _premode = false
            _totaldaysinseason:set(2)
            _remainingdaysinseason:set(1)
            _endlessdaysinseason:set(true)
        elseif modified_season == nil or modified_season == _season:value() then
            if _lengths[_season:value()]:value() == 0 then
                -- We can have a cycle that doesn't include the starting season (a "cycle pre" if you will)
                _premode = true
                _totaldaysinseason:set(ENDLESS_PRE_DAYS * 2)
                _remainingdaysinseason:set(ENDLESS_PRE_DAYS)
                _endlessdaysinseason:set(false)
            else
                if _season:value() == SEASONS.summer or _season:value() == SEASONS.winter or _season:value() == SEASONS.temperate then
                    _totaldaysinseason:set(_lengths[_season:value()]:value())
                    _remainingdaysinseason:set(math.ceil(_totaldaysinseason:value()))
                else
                    -- For spring and autumn, we artificially start "in the middle" for temperature, precip, etc. to prevent weird starts
                    _totaldaysinseason:set(_lengths[_season:value()]:value() * 2)
                    _remainingdaysinseason:set(_lengths[_season:value()]:value())
                end
                _premode = false
                _endlessdaysinseason:set(false)
            end

        end

    end or nil

    local PushMasterSeasonData = _ismastershard and function()
        local data =
        {
            season = _season:value(),
            totaldaysinseason = _totaldaysinseason:value(),
            remainingdaysinseason = _remainingdaysinseason:value(),
            elapseddaysinseason = _elapseddaysinseason:value(),
            endlessdaysinseason = _endlessdaysinseason:value(),
            lengths = {}
        }
        for i,v in ipairs(_lengths) do
            data.lengths[i] = v:value()
        end
        _world:PushEvent("master_seasonsupdate_" .. clock_type, data)
    end or nil

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnSeasonDirty()
        local data = {
            season = SEASON_NAMES[_season:value()],
            progress = 1 - (_totaldaysinseason:value() > 0 and _remainingdaysinseason:value() / _totaldaysinseason:value() or 0),
            elapseddaysinseason = _elapseddaysinseason:value(),
            remainingdaysinseason = _endlessdaysinseason:value() and ENDLESS_DAYS or _remainingdaysinseason:value(),
        }

        if _isplateau then
            data.preaporkalypseseason = SEASON_NAMES[_preaporkalypseseason:value()]
            data.preaporkalypseseasonprogress = _preaporkalypseseasonprogress:value()
        end

        _world:PushEvent("seasontick_" .. clock_type, data)

        if _ismastershard then
            PushMasterSeasonData()
        end
    end

    local function OnLengthsDirty()
        local data = {}
        for i, v in ipairs(_lengths) do
            data[SEASON_NAMES[i]] = v:value()
        end
        _world:PushEvent("seasonlengthschanged_" .. clock_type, data)

        if _ismastershard then
            PushMasterSeasonData()
        end
    end

    local OnAdvanceSeason = _ismastersim and function()
        _elapseddaysinseason:set(_elapseddaysinseason:value() + 1)

        if _mode == MODES.cycle then
            if _remainingdaysinseason:value() > 1 then
                -- Progress current season
                _remainingdaysinseason:set(_remainingdaysinseason:value() - 1)
            else
                -- Advance to next season
                if SEASON_NAMES[_season:value()] == "aporkalypse" then
                    _world:PushEvent("ms_stopaporkalypse")
                else
                    _season:set(GetNextSeason())
                    _totaldaysinseason:set(_lengths[_season:value()]:value())
                    _elapseddaysinseason:set(0)
                    _remainingdaysinseason:set(_totaldaysinseason:value())
                    _premode = false
                end
            end
        elseif _mode == MODES.endless then
            if _premode then
                if _remainingdaysinseason:value() > 1 then
                    -- Progress pre endless season
                    _remainingdaysinseason:set(_remainingdaysinseason:value() - 1)
                else
                    -- Advance to endless season
                    _season:set(GetNextSeason())
                    _totaldaysinseason:set(ENDLESS_RAMP_DAYS * 2)
                    _elapseddaysinseason:set(0)
                    _remainingdaysinseason:set(_totaldaysinseason:value())
                    _endlessdaysinseason:set(true)
                    _premode = false
                end
            elseif _remainingdaysinseason:value() > ENDLESS_RAMP_DAYS then
                -- Progress to peak of endless season
                _remainingdaysinseason:set(math.max(_remainingdaysinseason:value() - 1, ENDLESS_RAMP_DAYS))
            end
        else
            -- we always need to refersh the clock incase something else changed the segs
            -- return
        end

        PushSeasonClockSegs()
    end or nil

    local OnRetreatSeason = _ismastersim and function()
        if _elapseddaysinseason:value() > 0 then
            _elapseddaysinseason:set(_elapseddaysinseason:value() - 1)
        end

        if _mode == MODES.cycle then
            if _remainingdaysinseason:value() < _totaldaysinseason:value() then
                -- Regress current season
                _remainingdaysinseason:set(_remainingdaysinseason:value() + 1)
            else
                if SEASON_NAMES[_season:value()] == "aporkalypse" then
                    _world:PushEvent("ms_stopaporkalypse")
                else
                    -- Retreat to previous season
                    _season:set(GetPrevSeason())
                    _totaldaysinseason:set(_lengths[_season:value()]:value())
                    _elapseddaysinseason:set(math.max(_totaldaysinseason:value() - 1, 0))
                    _remainingdaysinseason:set(1)
                end
            end
        elseif _mode == MODES.endless then
            if not _premode then
                if _remainingdaysinseason:value() < _totaldaysinseason:value() then
                    -- Regress endless season
                    _remainingdaysinseason:set(_remainingdaysinseason:value() + 1)
                else
                    -- Retreat to pre endless season
                    _season:set(GetPrevSeason())
                    _totaldaysinseason:set(ENDLESS_PRE_DAYS * 2)
                    _elapseddaysinseason:set(math.max(ENDLESS_PRE_DAYS - 1, 0))
                    _remainingdaysinseason:set(1)
                    _endlessdaysinseason:set(false)
                    _premode = true
                end
            elseif _remainingdaysinseason:value() < ENDLESS_PRE_DAYS then
                -- Regress to peak of pre endless season
                _remainingdaysinseason:set(_remainingdaysinseason:value() + 1)
            end
        else
            return
        end

        PushSeasonClockSegs()
    end or nil

    local OnSetSeason = _ismastersim and function(src, season)
        assert(_ismastersim, "Invalid permissions")

        season = SEASONS[season]
        if season == nil then
            return
        end

        if _season:value() ~= season then
            _season:set(season)
            _elapseddaysinseason:set(0)
        end

        UpdateSeasonMode()

        PushSeasonClockSegs()
    end or nil

    local OnSetSeasonClockSegs = _ismastershard and function(src, segs)
        local default = nil
        for k, v in pairs(segs) do
            default = v
            break
        end

        if default == nil then
            if segs ~= DEFAULT_CLOCK_SEGS then
                OnSetSeasonClockSegs(DEFAULT_CLOCK_SEGS)
            end
            return
        end

        for i, v in ipairs(SEASON_NAMES) do
            _segs[i] = segs[v] or default
        end

        PushSeasonClockSegs()
    end or nil

    local OnSetSeasonLength = _ismastersim and function(src, data)
        local season = SEASONS[data.season]
        local length = data.length

        if data.random == true and _israndom[data.season] == true then
            return
        end
        _israndom[data.season] = data.random == true

        assert(season, "Tried setting the length of an invalid season.")
        if _lengths[season]:value() == length then return end  -- no change
        _lengths[season]:set(length or 0)

        local p
        if _season:value() == season then
            p = 1
            if _totaldaysinseason:value() > 0 then
                p = _remainingdaysinseason:value() / _totaldaysinseason:value()
            end
        end

        UpdateSeasonMode(season)

        if _season:value() == season and _mode ~= MODES.endless and _mode ~= MODES.always then
            _remainingdaysinseason:set(math.ceil(_totaldaysinseason:value() * p))

            PushSeasonClockSegs()
        end
    end or nil

    local OnSetSeasonSegModifier = _ismastershard and function(src, mod)
        _segmod = mod
        PushSeasonClockSegs()
    end or nil

    local OnSeasonsUpdate = _ismastersim and not _ismastershard and function(src, data)
        for i,v in ipairs(_lengths) do
            v:set(data.lengths[i])
        end
        _season:set(data.season)
        _totaldaysinseason:set(data.totaldaysinseason)
        _remainingdaysinseason:set(data.remainingdaysinseason)
        _elapseddaysinseason:set(data.elapseddaysinseason)
        _endlessdaysinseason:set(data.endlessdaysinseason)
    end or nil

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    if _ismastersim and _isplateau then function self:BeginAporkalypse(first_aporkalypse)
        if SEASON_NAMES[_season:value()] == "aporkalypse" then
            return
        end

        _preaporkalypseseasondata = self:OnSave_plateau()

        local totaldaysinseason = _preaporkalypseseasondata.totaldaysinseason or 0
        local remainingdaysinseason = _preaporkalypseseasondata.remainingdaysinseason or 0
        _preaporkalypseseasondata.preseasonprogress = 1 - (totaldaysinseason > 0 and remainingdaysinseason / totaldaysinseason or 0)

        _preaporkalypseseason:set(SEASONS[_preaporkalypseseasondata.season])
        _preaporkalypseseasonprogress:set(_preaporkalypseseasondata.preseasonprogress)

        local season = SEASONS["aporkalypse"]
        _lengths[season]:set(TUNING.APORKALYPSE_LENGTH)
        _season:set_local(season)
        _season:set(season)

        if first_aporkalypse then
            _mode = MODES.always
            _premode = false
            _totaldaysinseason:set(2)
            _remainingdaysinseason:set(1)
            _endlessdaysinseason:set(true)
        else
            _totaldaysinseason:set(_lengths[_season:value()]:value())
            _elapseddaysinseason:set(0)
            _remainingdaysinseason:set(_totaldaysinseason:value())
            _premode = false
        end

        PushSeasonClockSegs()
    end end

    if _ismastersim and _isplateau then function self:EndAporkalypse()
        if SEASON_NAMES[_season:value()] ~= "aporkalypse" then
            return
        end

        self:OnLoad_plateau(_preaporkalypseseasondata)
    end end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    -- Initialize network variables
    _season:set(SEASONS[SEASON_NAMES[1]])
    _totaldaysinseason:set(TUNING.SEASON_LENGTH_FRIENDLY_DEFAULT * 2)
    _remainingdaysinseason:set(TUNING.SEASON_LENGTH_FRIENDLY_DEFAULT)
    _elapseddaysinseason:set(0)
    _endlessdaysinseason:set(false)

    if _isplateau then
        _preaporkalypseseason:set(SEASONS[SEASON_NAMES[1]])
        _preaporkalypseseasonprogress:set(0)
    end

    for i, v in ipairs(_lengths) do
        v:set((seasons_data.lengths and seasons_data.lengths[SEASON_NAMES[i]]) or TUNING[string.upper(SEASON_NAMES[i]) .. "_LENGTH"] or 0)
    end

    -- Register network variable sync events
    inst:ListenForEvent("seasondirty_" .. clock_type, OnSeasonDirty)
    inst:ListenForEvent("lengthsdirty_" .. clock_type, OnLengthsDirty)

    if _ismastersim then
        _mode = MODES.cycle
        _premode = false
        _segs = {}

        for i, v in ipairs(SEASON_NAMES) do
            _segs[i] = DEFAULT_CLOCK_SEGS[v]
        end

        _segmod = {day = 1, dusk = 1, night = 1}

        PushSeasonClockSegs()

        -- Register master simulation events
        inst:ListenForEvent("ms_cyclecomplete_" .. clock_type, OnAdvanceSeason, _world)
        inst:ListenForEvent("ms_advanceseason", OnAdvanceSeason, _world)
        inst:ListenForEvent("ms_retreatseason", OnRetreatSeason, _world)
        inst:ListenForEvent("ms_setseason_" .. clock_type, OnSetSeason, _world)
        inst:ListenForEvent("ms_setseasonlength_" .. clock_type, OnSetSeasonLength, _world)
        inst:ListenForEvent("ms_setseasonclocksegs_" .. clock_type, OnSetSeasonClockSegs, _world)
        inst:ListenForEvent("ms_setseasonsegmodifier", OnSetSeasonSegModifier, _world)
        if not _ismastershard then
            -- Register secondary shard events
            inst:ListenForEvent("secondary_seasonsupdate_" .. clock_type, OnSeasonsUpdate, _world)
        end
    end

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    self["OnSave_" .. clock_type] = _ismastersim and function(self)
        local data = {
            mode = MODE_NAMES[_mode],
            premode = _premode,
            israndom = _israndom,
            segs = {},
            season = SEASON_NAMES[_season:value()],
            totaldaysinseason = _totaldaysinseason:value(),
            elapseddaysinseason = _elapseddaysinseason:value(),
            remainingdaysinseason = _remainingdaysinseason:value(),
            lengths = {},
        }

        for i, v in ipairs(SEASON_NAMES) do
            data.segs[v] = {}
            for k, v1 in pairs(_segs[i]) do
                data.segs[v][k] = v1
            end
            data.lengths[v] = _lengths[i]:value()
        end

        return data
    end or nil

    self["OnLoad_" .. clock_type] = _ismastersim and function(self, data)
        for i, v in ipairs(SEASON_NAMES) do
            local segs = {}
            local totalsegs = 0

            for k, v1 in pairs(_segs[i]) do
                segs[k] = data.segs and data.segs[v] and data.segs[v][k] or 0
                totalsegs = totalsegs + segs[k]
            end

            if totalsegs == NUM_CLOCK_SEGS then
                _segs[i] = segs
            else
                _segs[i] = DEFAULT_CLOCK_SEGS[v]
            end

            _lengths[i]:set(data.lengths and data.lengths[v] or TUNING[string.upper(v) .. "_LENGTH"] or 0)

            _israndom[v] = data.israndom and data.israndom[v] == true
        end

        _premode = data.premode == true
        _mode = MODES[data.mode] or MODES.cycle
        _season:set(SEASONS[data.season] or SEASONS[SEASON_NAMES[1]])
        _totaldaysinseason:set(data.totaldaysinseason or _lengths[_season:value()]:value())
        _elapseddaysinseason:set(data.elapseddaysinseason or 0)
        _remainingdaysinseason:set(math.min(data.remainingdaysinseason or _totaldaysinseason:value(), _totaldaysinseason:value()))
        _endlessdaysinseason:set(not _premode and _mode ~= MODES.cycle)

        PushSeasonClockSegs()
    end or nil

    if _ismastersim then
        local _OnSave = self.OnSave
        function self:OnSave(...)
            local data = _OnSave(self, ...)

            data["mode" .. clock_type] = MODE_NAMES[_mode]
            data["premode" .. clock_type] = _premode
            data["israndom" .. clock_type] = _israndom
            data["segs" .. clock_type] = {}
            data["season" .. clock_type] = SEASON_NAMES[_season:value()]
            data["totaldaysinseason" .. clock_type] = _totaldaysinseason:value()
            data["elapseddaysinseason" .. clock_type] = _elapseddaysinseason:value()
            data["remainingdaysinseason" .. clock_type] = _remainingdaysinseason:value()
            data["lengths" .. clock_type] = {}
            data["preaporkalypseseasondata"] = _preaporkalypseseasondata

            for i, v in ipairs(SEASON_NAMES) do
                data["segs" .. clock_type][v] = {}
                for k, v1 in pairs(_segs[i]) do
                    data["segs" .. clock_type][v][k] = v1
                end
                data["lengths" .. clock_type][v] = _lengths[i]:value()
            end

            return data
        end
    end

    if _ismastersim then
        local _OnLoad = self.OnLoad
        function self:OnLoad(data, ...)
            _preaporkalypseseasondata = data["preaporkalypseseasondata"] or {}
            if _isplateau then
                _preaporkalypseseason:set(SEASONS[_preaporkalypseseasondata.season] or SEASONS[SEASON_NAMES[1]])
                _preaporkalypseseasonprogress:set(_preaporkalypseseasondata.preseasonprogress or 0)
            end

            for i, v in ipairs(SEASON_NAMES) do
                local segs = {}
                local totalsegs = 0

                for k, v1 in pairs(_segs[i]) do
                    segs[k] = data["segs" .. clock_type] and data["segs" .. clock_type][v] and data["segs" .. clock_type][v][k] or 0
                    totalsegs = totalsegs + segs[k]
                end

                if totalsegs == NUM_CLOCK_SEGS then
                    _segs[i] = segs
                else
                    _segs[i] = DEFAULT_CLOCK_SEGS[v]
                end

                _lengths[i]:set(data["lengths" .. clock_type] and data["lengths" .. clock_type][v] or (seasons_data.lengths and seasons_data.lengths[SEASON_NAMES[i]]) or TUNING[string.upper(v) .. "_LENGTH"] or 0)

                _israndom[v] = data["israndom" .. clock_type] and data["israndom" .. clock_type][v] == true
            end

            _premode = data["premode" .. clock_type] == true
            _mode = MODES[data["mode" .. clock_type]] or MODES.cycle
            _season:set(SEASONS[data["season" .. clock_type]] or SEASONS[SEASON_NAMES[1]])
            _totaldaysinseason:set(data["totaldaysinseason" .. clock_type] or _lengths[_season:value()]:value())
            _elapseddaysinseason:set(data["elapseddaysinseason" .. clock_type] or 0)
            _remainingdaysinseason:set(math.min(data["remainingdaysinseason" .. clock_type] or _totaldaysinseason:value(), _totaldaysinseason:value()))
            _endlessdaysinseason:set(not _premode and _mode ~= MODES.cycle)

            PushSeasonClockSegs()

            return _OnLoad(self, data, ...)
        end
    end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------

    -- NOTE: dont wrap debugs to allow mods easier access to upvalues
    self["GetDebugString_" .. clock_type] = function()
        return string.format(clock_type .. " %s %d -> %d days (%.0f %%) %s %s", SEASON_NAMES[_season:value()], _elapseddaysinseason:value(), _endlessdaysinseason:value() and ENDLESS_DAYS or _remainingdaysinseason:value(), 100-100*(_remainingdaysinseason:value() / _totaldaysinseason:value()), MODE_NAMES[_mode] or "", _premode and "(PRE)" or "")
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
end

local events = {"seasonlengthschanged", "seasontick"}
local function SetSeasons(self, clock_type, seasons_data)
    if clock_type ~= "default" and not self.clocks then
        self:MakeSeasons(clock_type, seasons_data)
    end

    self.current_clock = clock_type

    for _, event in ipairs(events) do
        for clock in pairs(self.clocks) do
            local suffix = clock == "default" and "" or ("_" .. self.current_clock)
            if clock ~= self.current_clock then
                TheWorld:AddPushEventPostFn(event .. suffix, SilenceEvent)
            else
                TheWorld:AddPushEventPostFn(event .. suffix, function() return event end)
            end
        end
    end
end

AddComponentPostInit("seasons", function(self)
    local _world = TheWorld

    self.current_clock = "default"
    self.clocks = {["default"] = true}

    self.SetSeasons = SetSeasons
    self.MakeSeasons = MakeSeasons

    self:MakeSeasons("plateau", {
        names = {
            "temperate",
            "humid",
            "lush",
            "aporkalypse",
        },
        segs = {
            temperate = {day = 10, dusk = 4, night = 2},
            humid = {day = 8, dusk = 5, night = 3},
            lush = {day = 8, dusk = 4, night = 4},
            aporkalypse = {day = 0, dusk = 0, night = 16}
        },
        lengths = {
            temperate = TUNING.TEMPERATE_LENGTH,
            humid = TUNING.HUMID_LENGTH,
            lush = TUNING.LUSH_LENGTH,
            aporkalypse = 0  -- change whit start
        }
    })

    if TheWorld:HasTag("porkland") then
        self:SetSeasons("plateau")
    end
end)

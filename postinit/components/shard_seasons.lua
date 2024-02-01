local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function MakeShardSeasons(self, clock_type)
    assert(clock_type, "Invalid clock_type for new network")
    --------------------------------------------------------------------------
    --[[ Shard_Seasons ]]
    --------------------------------------------------------------------------

    assert(TheWorld.ismastersim, "Shard_Seasons_[" .. clock_type .. "] should not exist on client")

    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    local NUM_SEASONS = 4 -- keep in sync with seasons.lua SEASON_NAMES table

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    local inst = self.inst

    -- Private
    local _world = TheWorld
    local _ismastershard = _world.ismastershard

    -- Network
    local _lengths = {}
    for i = 1, NUM_SEASONS do
        table.insert(_lengths, net_byte(inst.GUID, "shard_seasons_" .. clock_type .. ".lengths[" .. tostring(i) .. "]"))
    end
    local _season = net_tinybyte(inst.GUID, "shard_seasons_" .. clock_type .. "._season", "seasonsdirty_" .. clock_type)
    local _totaldaysinseason = net_byte(inst.GUID, "shard_seasons_" .. clock_type .. "._totaldaysinseason", "seasonsdirty_" .. clock_type)
    local _remainingdaysinseason = net_byte(inst.GUID, "shard_seasons_" .. clock_type .. "._remainingdaysinseason", "seasonsdirty_" .. clock_type)
    local _elapseddaysinseason = net_ushortint(inst.GUID, "shard_seasons_" .. clock_type .. "._elapseddaysinseason", "seasonsdirty_" .. clock_type)
    local _endlessdaysinseason = net_bool(inst.GUID, "shard_seasons_" .. clock_type .. "._endlessdaysinseason", "seasonsdirty_" .. clock_type)

    --------------------------------------------------------------------------
    --[[ Private event listeners ]]
    --------------------------------------------------------------------------

    local OnSeasonsUpdate = _ismastershard and function(src, data)
        local dirty = false

        for i, v in ipairs(_lengths) do
            if v:value() ~= data.lengths[i] then
                v:set(data.lengths[i])
                dirty = true
            end
        end

        if _season:value() ~= data.season then
            _season:set(data.season)
            dirty = true
        end

        if _totaldaysinseason:value() ~= data.totaldaysinseason then
            _totaldaysinseason:set(data.totaldaysinseason)
            dirty = true
        end

        if _remainingdaysinseason:value() ~= data.remainingdaysinseason then
            _remainingdaysinseason:set(data.remainingdaysinseason)
            dirty = true
        end

        if _elapseddaysinseason:value() ~= data.elapseddaysinseason then
            _elapseddaysinseason:set(data.elapseddaysinseason)
            dirty = true
        end

        if _endlessdaysinseason:value() ~= data.endlessdaysinseason then
            _endlessdaysinseason:set(data.endlessdaysinseason)
            dirty = true
        end

        if dirty then
        end
    end or nil

    local OnSeasonsDirty = not _ismastershard and function()
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
        _world:PushEvent("secondary_seasonsupdate_" .. clock_type, data)
    end or nil

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    if _ismastershard then
        -- Register master shard events
        inst:ListenForEvent("master_seasonsupdate_" .. clock_type, OnSeasonsUpdate, _world)
    else
        -- Register network variable sync events
        inst:ListenForEvent("seasonsdirty_" .. clock_type, OnSeasonsDirty)
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end

AddComponentPostInit("shard_seasons", function(self)
    self.MakeShardSeasons = MakeShardSeasons
    self:MakeShardSeasons("plateau")
end)

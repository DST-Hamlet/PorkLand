--------------------------------------------------------------------------
--[[ Shard_Aporkalypse ]]
--------------------------------------------------------------------------

return Class(function(self, inst)
    assert(TheWorld.ismastersim, "Shard_Aporkalypse should not exist on client")

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    self.inst = inst

    -- Private
    local _world = TheWorld
    local _ismastershard = _world.ismastershard

    local seg_time = TUNING.SEG_TIME

    -- Network
    local _rewindmult = net_shortint(inst.GUID, "shard_aporkalypse._rewindmult", "aporkalypsedirty")
    local _aporkalypseactive = net_bool(inst.GUID, "shard_aporkalypse._active", "aporkalypsedirty")
    local _timeuntilaporkalypse = net_float(inst.GUID, "shard_aporkalypse._timeuntilaporkalypse", "aporkalypsedirty")

    --------------------------------------------------------------------------
    --[[ Private event listeners ]]
    --------------------------------------------------------------------------

    local last_timeuntilaporkalypse = 0
    local OnAporkalypseUpdate = _ismastershard and function(src, data)
        local timeuntilaporkalypse = data.timeuntilaporkalypse

        _timeuntilaporkalypse:set_local(timeuntilaporkalypse)
        if math.abs(timeuntilaporkalypse - last_timeuntilaporkalypse) >= seg_time then
            _timeuntilaporkalypse:set(timeuntilaporkalypse)
            last_timeuntilaporkalypse = timeuntilaporkalypse
        end

        if _aporkalypseactive:value() ~= data.aporkalypseactive then
            _aporkalypseactive:set(data.aporkalypseactive)
        end

        if _rewindmult:value() ~= data.rewindmult then
            _rewindmult:set(data.rewindmult)
        end
    end or nil

    local OnAporkalypseDirty = not _ismastershard and function()
        _world:PushEvent("secondary_aporkalypseupdate", {timeuntilaporkalypse = _timeuntilaporkalypse:value(), aporkalypseactive = _aporkalypseactive:value(), rewindmult = _rewindmult:value()})
    end or nil

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    if _ismastershard then
        -- Register master shard events
        inst:ListenForEvent("master_aporkalypseupdate", OnAporkalypseUpdate, _world)
    else
        -- Register network variable sync events
        inst:ListenForEvent("aporkalypsedirty", OnAporkalypseDirty)
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
end)

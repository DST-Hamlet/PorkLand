--------------------------------------------------------------------------
--[[ Aporkalypse class definition ]]
--------------------------------------------------------------------------

local function onrewindmult(self)
    TheWorld:PushEvent("rewindmultchange", self.rewind_mult)
end

return Class(function(self, inst)
    local NEAR_TIME = TUNING.APORKALYPSE_NEAR_TIME
    local APORKALYPSE_PERIOD_LENGTH = TUNING.APORKALYPSE_PERIOD_LENGTH

    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    -- Public
    self.inst = inst
    self.rewind_mult = 0

    local _world = TheWorld

    -- Private
    local _ismastersim = _world.ismastersim
    local _ismastershard = _world.ismastershard
    local _clock = inst.components.clock
    local _seasons = inst.components.seasons

    -- Master simulation
    local active_aporkalypse
    local first_aporkalypse
    local near_aporkalypse = false

    -- Network
    local _timeuntilaporkalypse = net_float(inst.GUID, "timeuntil.aporkalypse")

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local BeginAporkalypse = _ismastersim and function()
        if active_aporkalypse then
            return
        end

        active_aporkalypse = true
        _timeuntilaporkalypse:set(0)

        if _clock and _clock.BeginAporkalypse then
            _clock:BeginAporkalypse()
        end

        if _seasons and _seasons.BeginAporkalypse then
            _seasons:BeginAporkalypse(first_aporkalypse)
        end
    end or nil

    local EndAporkalypse = _ismastersim and function()
        if not active_aporkalypse then
            return
        end

        active_aporkalypse = false
        first_aporkalypse = false
        _timeuntilaporkalypse:set(APORKALYPSE_PERIOD_LENGTH)

        if inst.components.clock and inst.components.clock.EndAporkalypse then
            inst.components.clock:EndAporkalypse()
        end

        if inst.components.seasons and inst.components.seasons.EndAporkalypse then
            inst.components.seasons:EndAporkalypse()
        end
    end or nil

    local ForceResync = _ismastersim and function(netvar)
        netvar:set_local(netvar:value())
        netvar:set(netvar:value())
    end or nil

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local StartAporkalypse = _ismastersim and function()
        if _ismastershard then
            BeginAporkalypse()
        else
            SendModRPCToShard(SHARD_MOD_RPC["Porkland"]["SwitchAporkalypse"], 1, true)
        end
    end or nil

    local StopAporkalypse = _ismastersim and function()
        if _ismastershard then
            EndAporkalypse()
        else
            SendModRPCToShard(SHARD_MOD_RPC["Porkland"]["SwitchAporkalypse"], 1, false)
        end
    end or nil

    local SetRewindMult = _ismastersim and function(src, mult)
        self.rewind_mult = self.rewind_mult + mult

        if not _ismastershard then
            SendModRPCToShard(SHARD_MOD_RPC["Porkland"]["SetAporkalypseClockRewindMult"], 1, mult)
        end
    end or nil

    local OnSimUnpaused = _ismastersim and function()
        ForceResync(_timeuntilaporkalypse)  -- Force resync values
    end or nil

    local OnAporkalypseUpdate = _ismastersim and not _ismastershard and function(src, data)
        _timeuntilaporkalypse:set(data.timeuntilaporkalypse)

        if active_aporkalypse ~= data.activeaporkalypse then
            active_aporkalypse = data.activeaporkalypse

            if data.activeaporkalypse then
                BeginAporkalypse()
            else
                EndAporkalypse()
            end
        end

        self.rewind_mult = data.rewindmult

        self:OnUpdate(0)
    end or nil

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    -- Initialize network variables
    _timeuntilaporkalypse:set(APORKALYPSE_PERIOD_LENGTH)

    if _ismastersim then
        active_aporkalypse = false
        first_aporkalypse = true

        -- Register master events
        inst:ListenForEvent("ms_startaporkalypse", StartAporkalypse, _world)
        inst:ListenForEvent("ms_stopaporkalypse", StopAporkalypse, _world)
        inst:ListenForEvent("ms_setrewindmult", SetRewindMult, _world)
        inst:ListenForEvent("ms_simunpaused", OnSimUnpaused, _world)

        if not _ismastershard then
            -- Register secondary shard events
            inst:ListenForEvent("secondary_aporkalypseupdate", OnAporkalypseUpdate, _world)
        end
    end

    --------------------------------------------------------------------------
    --[[ Post initialization ]]
    --------------------------------------------------------------------------

    function self:OnPostInit(...)
        _clock = inst.components.clock
        _seasons = inst.components.seasons
    end

    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------

    -- Update it in clock component onupdate
    function self:OnUpdate(dt)
        local timeuntilaporkalypse = _timeuntilaporkalypse:value() - dt - self.rewind_mult * 250 * dt

        while timeuntilaporkalypse > APORKALYPSE_PERIOD_LENGTH do
            timeuntilaporkalypse = timeuntilaporkalypse % APORKALYPSE_PERIOD_LENGTH
        end

        if timeuntilaporkalypse > 0 then
            if _ismastershard then
                _timeuntilaporkalypse:set(timeuntilaporkalypse)
            else
                -- Clients and secondary shards must wait server sync
                _timeuntilaporkalypse:set_local(timeuntilaporkalypse)
            end

            if timeuntilaporkalypse <= NEAR_TIME and not near_aporkalypse then
                near_aporkalypse = true
            end
        else
            near_aporkalypse = false

            if _ismastershard then
                if not active_aporkalypse then
                    BeginAporkalypse()
                end
            else
                -- Clients and secondary shards must wait server sync
                _timeuntilaporkalypse:set_local(0)
            end

        end

        if _ismastershard then
            _world:PushEvent("master_aporkalypseupdate", {timeuntilaporkalypse = _timeuntilaporkalypse:value(), activeaporkalypse = active_aporkalypse, rewindmult = self.rewind_mult})
        end

        _world:PushEvent("aporkalypseclocktick", {timeuntilaporkalypse = _timeuntilaporkalypse:value()})
    end

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnSave()
        return {
            active_aporkalypse = active_aporkalypse,
            first_aporkalypse = first_aporkalypse,
            time_until_aporkalypse = _timeuntilaporkalypse:value(),
        }
    end end

    if _ismastersim then function self:OnLoad(data)
        -- can be false, so don't nil check
        first_aporkalypse = data.first_aporkalypse or false

        _timeuntilaporkalypse:set(data.time_until_aporkalypse or APORKALYPSE_PERIOD_LENGTH)

        if data.active_aporkalypse == true then
            BeginAporkalypse()
        end
    end end


    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end,
nil,
{
    rewind_mult = onrewindmult
})

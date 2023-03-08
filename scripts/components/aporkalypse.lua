--------------------------------------------------------------------------
--[[ Aporkalypse class definition ]]
--------------------------------------------------------------------------

local function onrewindmult(self)
    TheWorld:PushEvent("rewindmultchange", self.rewind_mult)
end

return Class(function(self, inst)
    -- Public
    self.inst = inst
    self.rewind_mult = 0
    local _world = TheWorld

    -- Private
    local _ismastersim = _world.ismastersim
    local _ismastershard = _world.ismastershard
    local NEAR_TIME = TUNING.APORKALYPSE_NEAR_TIME
    local APORKALYPSE_PERIOD_LENGTH = TUNING.APORKALYPSE_PERIOD_LENGTH

    local first_aporkalypse = true
    local near_aporkalypse = false

    -- Network
    local _timeuntilaporkalypse = net_float(inst.GUID, "timeuntil.aporkalypse")
    local _aporkalypseactive = net_bool(inst.GUID, "aporkalypse.active", "aporkalypseactivedirty")

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local BeginAporkalypse = _ismastersim and function()
        if inst.components.clock and inst.components.clock.BeginAporkalypse then
            inst.components.clock:BeginAporkalypse()
        end

        if inst.components.seasons and inst.components.seasons.BeginAporkalypse then
            inst.components.seasons:BeginAporkalypse(first_aporkalypse)
        end

        _timeuntilaporkalypse:set(0)
        _aporkalypseactive:set(true)
    end or nil

    local EndAporkalypse = _ismastersim and function()
        if inst.components.clock and inst.components.clock.EndAporkalypse then
            inst.components.clock:EndAporkalypse()
        end

        if inst.components.seasons and inst.components.seasons.EndAporkalypse then
            inst.components.seasons:EndAporkalypse()
        end

        first_aporkalypse = false
        _timeuntilaporkalypse:set(APORKALYPSE_PERIOD_LENGTH)
        _aporkalypseactive:set(false)
    end or nil

    local ForceResync = _ismastersim and function(netvar)
        netvar:set_local(netvar:value())
        netvar:set(netvar:value())
    end or nil

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnAporkalypseActiveDirty()
        _world:PushEvent("aporkalypsechange", _aporkalypseactive:value())
    end

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
        ForceResync(_aporkalypseactive)  -- Force resync values
    end or nil

    local OnAporkalypseUpdate = _ismastersim and not _ismastershard and function(src, data)
        _timeuntilaporkalypse:set(data.timeuntilaporkalypse)

        if _aporkalypseactive:value() ~= data.aporkalypseactive then
            _aporkalypseactive:set(data.aporkalypseactive)

            if data.aporkalypseactive then
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
    _aporkalypseactive:set(false)

    -- Register events
    inst:ListenForEvent("aporkalypseactivedirty", OnAporkalypseActiveDirty)

    if _ismastersim then
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
                if not _aporkalypseactive:value() then
                    BeginAporkalypse()
                end
            else
                -- Clients and secondary shards must wait server sync
                _timeuntilaporkalypse:set_local(math.max(.001, timeuntilaporkalypse))
            end

        end

        if _ismastershard then
            _world:PushEvent("master_aporkalypseupdate", {timeuntilaporkalypse = timeuntilaporkalypse, aporkalypseactive = _aporkalypseactive:value(), rewindmult = self.rewind_mult})
        end

        _world:PushEvent("aporkalypseclocktick", {timeuntilaporkalypse = timeuntilaporkalypse})
    end

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnSave()
        return {
            aporkalypseactive = _aporkalypseactive:value(),
            time_until_aporkalypse = _timeuntilaporkalypse:value(),
            first_aporkalypse = first_aporkalypse,
        }
    end end

    if _ismastersim then function self:OnLoad(data)
        -- can be false, so don't nil check
        first_aporkalypse = data.first_aporkalypse or false

        _timeuntilaporkalypse:set(data.time_until_aporkalypse or APORKALYPSE_PERIOD_LENGTH)

        if data.aporkalypseactive == true then
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

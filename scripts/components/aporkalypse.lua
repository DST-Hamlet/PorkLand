--------------------------------------------------------------------------
--[[ Aporkalypse class definition ]]
--------------------------------------------------------------------------

local SpawnHerald = require("prefabs/ancient_herald_util").SpawnHerald

local function onrewindmult(self)
    TheWorld:PushEvent("rewindmultchange", self.rewind_mult)
end

return Class(function(self, inst)
    local APORKALYPSE_NEAR_TIME = TUNING.APORKALYPSE_NEAR_TIME
    local APORKALYPSE_FIESTA_TIME = TUNING.APORKALYPSE_FIESTA_TIME
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
    local _isplateau = _clock and _clock.current_clock == "plateau"

    local _activefiestadirty = true
    local _isnearaporkalypsedirty = true

    local _bat_time
    local _herald_time

    -- Master shard simulation
    local _timeuntilfiestaend = _ismastershard and TUNING.APORKALYPSE_FIESTA_TIME or nil

    -- Master simulation
    local _activeaporkalypse
    local _firstaporkalypse

    -- Network
    local _timeuntilaporkalypse = net_float(inst.GUID, "aporkalypse.timeuntil")
    local _activefiesta = net_bool(inst.GUID, "aporkalypse.activefiesta", "activefiestadirty")
    local _isnearaporkalypse = net_bool(inst.GUID, "aporkalypse.isnearaporkalypse", "isnearaporkalypsedirty")

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function OnPlayerActivated()
        _isnearaporkalypsedirty = true
        _activefiestadirty = true
    end

    local BeginFiesta = _ismastersim and _isplateau and function()
        if not _activefiesta:value() then
            _activefiesta:set(true)
        end
    end

    local EndFiesta = _ismastersim and _isplateau and function()
        if _activefiesta:value() then
            _activefiesta:set(false)
            _timeuntilfiestaend = APORKALYPSE_FIESTA_TIME
        end
    end

    local function CancelAttacks()
        _bat_time = nil
        _herald_time = nil
    end

    local ScheduleBatAttack = _ismastersim and function()
        _bat_time = TUNING.TOTAL_DAY_TIME + (TUNING.TOTAL_DAY_TIME * math.random(0, 0.25))
    end

    local ScheduleHeraldAttack = _ismastersim and function()
        _herald_time = math.random(TUNING.TOTAL_DAY_TIME / 3, TUNING.TOTAL_DAY_TIME)
    end

    local BeginAporkalypse = _ismastersim and function()
        if _activeaporkalypse then
            return
        end

        TUNING.PERISH_GLOBAL_MULT = TUNING.PERISH_APORKALYPSE_MULT -- 大灾变腐烂加速, 很难找到更好的写法

        _activeaporkalypse = true
        _timeuntilaporkalypse:set(0)

        if _clock and _clock.BeginAporkalypse then
            _clock:BeginAporkalypse()
        end

        if _seasons and _seasons.BeginAporkalypse then
            _seasons:BeginAporkalypse(_firstaporkalypse)
        end

        if _isplateau then
            EndFiesta()
        end

        ScheduleBatAttack()
        ScheduleHeraldAttack()
    end or nil

    local EndAporkalypse = _ismastersim and function()
        if not _activeaporkalypse then
            return
        end

        TUNING.PERISH_GLOBAL_MULT = TUNING.PERISH_NORMAL_MULT

        _activeaporkalypse = false
        _firstaporkalypse = false
        _timeuntilaporkalypse:set(APORKALYPSE_PERIOD_LENGTH)

        if _clock and _clock.EndAporkalypse then
            _clock:EndAporkalypse()
        end

        if _seasons and _seasons.EndAporkalypse then
            _seasons:EndAporkalypse()
        end

        if _isplateau then
            BeginFiesta()
        end

        CancelAttacks()
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
        _activefiesta:set(data.activefiesta)
        _isnearaporkalypse:set(data.isnearaporkalypse)

        if _activeaporkalypse ~= data.activeaporkalypse then
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
    _isnearaporkalypse:set(false)
    _activefiesta:set(false)

    -- Register network variable sync events
    inst:ListenForEvent("activefiestadirty", function() _activefiestadirty = true end)
    inst:ListenForEvent("isnearaporkalypsedirty", function() _isnearaporkalypsedirty = true end)
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)

    if _ismastersim then
        _activeaporkalypse = false
        _firstaporkalypse = true

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
        _isplateau = _clock and _clock.current_clock == "plateau"
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

            if _isplateau and timeuntilaporkalypse <= APORKALYPSE_NEAR_TIME and not _isnearaporkalypse:value() then
                _isnearaporkalypse:set(true)
            end
        else
            _isnearaporkalypse:set(false)

            if _ismastershard then
                if not _activeaporkalypse then
                    BeginAporkalypse()
                end
            else
                -- Clients and secondary shards must wait server sync
                _timeuntilaporkalypse:set_local(0)
            end

        end

        if _activefiesta:value() and _ismastershard then
            _timeuntilfiestaend = _timeuntilfiestaend - dt
            if _timeuntilfiestaend <= 0 then
                EndFiesta()
            end
        end

        if _isnearaporkalypsedirty then
            _world:PushEvent("nearaporkalypsechange", _isnearaporkalypse:value())
            _isnearaporkalypsedirty = false
        end

        if _activefiestadirty then
            _world:PushEvent("fiestachange", _activefiesta:value())
            _activefiestadirty = false
        end

        if _ismastershard then
            _world:PushEvent("master_aporkalypseupdate", {
                timeuntilaporkalypse = _timeuntilaporkalypse:value(),
                isnearaporkalypse = _isnearaporkalypse:value(),
                activefiesta = _activefiesta:value(),
                activeaporkalypse = _activeaporkalypse,
                rewindmult = self.rewind_mult
            })
        end

        if _activeaporkalypse then
            _bat_time = _bat_time - dt
            if _bat_time <= 0 then
                if GetWorldSetting("vampirebat") == "never" then
                    return
                end

                local batted = _world.components.batted
                batted:RegenBat(15)
                batted:ForceBatAttack()
                ScheduleBatAttack()
            end
            _herald_time = _herald_time - dt
            if _herald_time <= 0 then
                local players = {}
                for _, player in pairs(AllPlayers) do
                    if not player:GetIsInInterior() then
                        table.insert(players, player)
                    end
                end

                local player = GetRandomItem(players)
                SpawnHerald(player)
                ScheduleHeraldAttack()
            end
        end

        _world:PushEvent("aporkalypseclocktick", {timeuntilaporkalypse = _timeuntilaporkalypse:value()})
    end

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnSave()
        return {
            activeaporkalypse = _activeaporkalypse,
            firstaporkalypse = _firstaporkalypse,
            activefiesta = _activefiesta:value(),
            isnearaporkalypse = _isnearaporkalypse:value(),
            timeuntilaporkalypse = _timeuntilaporkalypse:value(),
            bat_time = _bat_time,
            herald_time = _herald_time,
        }
    end end

    if _ismastersim then function self:OnLoad(data)
        -- can be false, so don't nil check
        _firstaporkalypse = data.firstaporkalypse or false
        _activefiesta:set(data.activefiesta or false)
        _isnearaporkalypse:set(data.isnearaporkalypse or false)
        _timeuntilaporkalypse:set(data.timeuntilaporkalypse or APORKALYPSE_PERIOD_LENGTH)

        if data.activeaporkalypse == true then
            BeginAporkalypse()
            if data.bat_time then
                _bat_time = data.bat_time
            end
            if data.herald_time then
                _herald_time = data.herald_time
            end
        end
    end end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:GetDebugString()
        local s = ""
        if _activeaporkalypse then
            s = string.format("Next bat attack: %2.2f Next herald attack: %2.2f", _bat_time or -1, _herald_time or -1)
        end

        return s
    end end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end,
nil,
{
    rewind_mult = onrewindmult
})

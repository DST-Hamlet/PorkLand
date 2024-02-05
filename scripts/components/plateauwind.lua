
local HURRICANE_GUST_STATE = {
    WAIT = 0,
    ACTIVE = 1,
    RAMPUP = 2,
    RAMPDOWN = 3,
}

--------------------------------------------------------------------------
--[[ PlateauWind class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)
    assert(TheWorld.ismastersim, "PlateauWind should not exist on client")
    --------------------------------------------------------------------------
    --[[ Dependencies ]]
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    self.inst = inst

    -- Private
    local _world = TheWorld
    local _wind_state = HURRICANE_GUST_STATE.WAIT
    local _wind_gust_timer = 0
    local _wind_gust_period = 0
    local _wind_gust_speed = 0
    local _wind_gust_peak = 0
    local _windy = false

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    -- The reason to not use DoTaskInTime here is wind speed ramps up gradually, not at discrete levels
    local function UpdateHurricaneWind(dt, percent, windstart, windend)
        if windstart <= percent and percent <= windend then
            _wind_gust_timer = _wind_gust_timer + dt
            if _wind_state == HURRICANE_GUST_STATE.WAIT then
                _wind_gust_speed = 0
                if _wind_gust_timer >= _wind_gust_period then
                    _wind_gust_peak = GetRandomMinMax(TUNING.WIND_GUSTSPEED_PEAK_MIN, TUNING.WIND_GUSTSPEED_PEAK_MAX)
                    _wind_gust_timer = 0.0
                    _wind_gust_period = TUNING.WIND_GUSTRAMPUP_TIME
                    _wind_state = HURRICANE_GUST_STATE.RAMPUP
                end

            elseif _wind_state == HURRICANE_GUST_STATE.RAMPUP then
                local peak = 0.5 * _wind_gust_peak
                _wind_gust_speed = -peak * math.cos(PI * _wind_gust_timer / _wind_gust_period) + peak
                if _wind_gust_timer >= _wind_gust_period then
                    _wind_gust_timer = 0
                    _wind_gust_period = GetRandomMinMax(TUNING.WIND_GUSTLENGTH_MIN, TUNING.WIND_GUSTLENGTH_MAX)
                    _wind_state = HURRICANE_GUST_STATE.ACTIVE
                end

            elseif _wind_state == HURRICANE_GUST_STATE.ACTIVE then
                _wind_gust_speed = _wind_gust_peak
                if _wind_gust_timer >= _wind_gust_period then
                    _wind_gust_timer = 0.0
                    _wind_gust_period = TUNING.WIND_GUSTRAMPDOWN_TIME
                    _wind_state = HURRICANE_GUST_STATE.RAMPDOWN
                end

            elseif _wind_state == HURRICANE_GUST_STATE.RAMPDOWN then
                local peak = 0.5 * _wind_gust_peak
                _wind_gust_speed = peak * math.cos(PI * _wind_gust_timer / _wind_gust_period) + peak
                if _wind_gust_timer >= _wind_gust_period then
                    _wind_gust_timer = 0
                    _wind_gust_period = GetRandomMinMax(TUNING.WIND_GUSTDELAY_MIN, TUNING.WIND_GUSTDELAY_MAX)
                    if _world.state.season == SEASONS.LUSH then
                        _wind_gust_period = GetRandomMinMax(TUNING.WIND_GUSTDELAY_MIN_LUSH, TUNING.WIND_GUSTDELAY_MAX_LUSH)
                    end
                    _wind_state = HURRICANE_GUST_STATE.WAIT
                end
            end
        else
            _wind_gust_timer = 0
            _wind_gust_speed = 0
        end
    end

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    function self:StartWind()
        if not _windy then
            _windy = true
            _wind_gust_speed = 0
            _wind_gust_timer = 0.0
            _wind_gust_period = 0.0
            _wind_gust_peak = 0.0
            _wind_state = HURRICANE_GUST_STATE.WAIT
        end
    end

    function self:StopWind()
        if _windy then
            _windy = false
            _wind_gust_speed = 0
            _wind_gust_timer = 0.0
            _wind_gust_period = 0.0
            _wind_gust_peak = 0.0
            _wind_state = HURRICANE_GUST_STATE.WAIT
        end
    end

    function self:UpdateDynamicWind(dt, seasonprogress)
        local seasonpercent = seasonprogress or .5
        UpdateHurricaneWind(dt, seasonpercent, TUNING.HURRICANE_PERCENT_WIND_START, TUNING.HURRICANE_PERCENT_WIND_END)
    end

    function self:GetWindSpeed()
        return _wind_gust_speed
    end

    function self:GetIsWindy()
        return _windy
    end

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    function self:OnSave()
        return {
            windy = _windy,
            wind_state = _wind_state,
            wind_gust_timer = _wind_gust_timer,
            wind_gust_period = _wind_gust_period,
            wind_gust_speed = _wind_gust_speed,
            wind_gust_peak = _wind_gust_peak,
        }
    end

    function self:OnLoad(data)
        _windy = data.windy or false
        _wind_state = data.wind_state or HURRICANE_GUST_STATE.WAIT
        _wind_gust_timer = data.wind_gust_timer or 0
        _wind_gust_period = data.wind_gust_period or 0
        _wind_gust_speed = data.wind_gust_speed or 0
        _wind_gust_peak = data.wind_gust_peak or 0
    end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------

    function self:GetDebugString()
        return string.format("Windy: %s, Gust State: %d, Gust Timer: %0.2f, Gust Period: %0.2f, Gust Speed: %0.2f, Gust Peak: %0.2f",
            _windy, _wind_state, _wind_gust_timer, _wind_gust_period, _wind_gust_speed, _wind_gust_peak)
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end)

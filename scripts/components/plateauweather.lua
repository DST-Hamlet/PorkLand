--------------------------------------------------------------------------
--[[ Weather class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

    --------------------------------------------------------------------------
    --[[ Dependencies ]]
    --------------------------------------------------------------------------

    local easing = require("easing")

    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    local NOISE_SYNC_PERIOD = 30

    --------------------------------------------------------------------------
    --[[ Precipitation constants ]]
    --------------------------------------------------------------------------

    local PRECIP_MODE_NAMES =
    {
        "dynamic",
        "always",
        "never",
    }
    local PRECIP_MODES = table.invert(PRECIP_MODE_NAMES)

    local PRECIP_TYPE_NAMES =
    {
        "none",
        "rain",
    }
    local PRECIP_TYPES = table.invert(PRECIP_TYPE_NAMES)

    local PRECIP_RATE_SCALE = 10
    local MIN_PRECIP_RATE = .1

    local PROGRESS_MULTIPLIERS = {
        temperate = 1,
        humid = 1.5,
        lush = 1,
        aporkalypse = 1
    }

    -- NOTE: In ds lush have no moisture gain at all, this is bad as
    -- percip will get stuck at the same value all season long
    -- so the values have been slightly modified to be more immersive
    local MOISTURE_RATES = {
        MIN = {
            temperate = .25,
            humid = 3,
            lush = 0,
            aporkalypse = .1
        },
        MAX = {
            temperate = 1.0,
            humid = 3.75,
            lush = -0.2,  -- in ds it's 0
            aporkalypse = .5
        }
    }
    local MOISTURE_SYNC_PERIOD = 100

    local MOISTURE_CEIL_MULTIPLIERS =
    {
        temperate = {min = 2, max = 5.5},
        humid = {min = 1, max = 4},
        lush = {min = 2, max = 5.5},
        aporkalypse = {min = 2, max = 8},
    }

    local MOISTURE_FLOOR_MULTIPLIERS =
    {
        temperate = 1,
        humid = 0.5,
        lush = 1,
        aporkalypse = 1
    }

    local GROUND_OVERLAYS =
    {
        puddles =
        {
            texture = "levels/textures/mud.tex",
            colour =
            {
                { 11 / 255, 15 / 255, 23 / 255, .3 },
                { 11 / 255, 15 / 255, 23 / 255, .2 },
                { 11 / 255, 15 / 255, 23 / 255, .12 },
            },
        },
    }

    local POLLEN_PARTICLES = 1

    local PEAK_PRECIPITATION_RANGES =
    {
        temperate = {min = .1, max = .66},
        humid = {min = 1, max = 2},
        lush = {min = .05, max = .15},
        aporkalypse = {min = .1, max = .66},
    }

    --------------------------------------------------------------------------
    --[[ Fog constants ]]
    --------------------------------------------------------------------------

    -- fog is a rain type, when humid season, it will moisture greater than 900, will start fog and stop rain fx
    local FOG_STATE = FOG_STATE

    local FOG_MOISTURE_CEIL = {
        humid = 900
    }

    local FOG_MODE_NAMES =
    {
        "dynamic",
        "never",
    }
    local FOG_MODES = table.invert(FOG_MODE_NAMES)

    local FOG_TRANSITION_TIME = 10

    --------------------------------------------------------------------------
    --[[ Wetness constants ]]
    --------------------------------------------------------------------------

    local DRY_THRESHOLD = TUNING.MOISTURE_DRY_THRESHOLD
    local WET_THRESHOLD = TUNING.MOISTURE_WET_THRESHOLD
    local MIN_WETNESS = 0
    local MAX_WETNESS = 100
    local MIN_WETNESS_RATE = 0
    local MAX_WETNESS_RATE = .75
    local MIN_DRYING_RATE = 0
    local MAX_DRYING_RATE = .3
    local OPTIMAL_DRYING_TEMPERATURE = 70
    local WETNESS_SYNC_PERIOD = 10

    --------------------------------------------------------------------------
    --[[ Lightning (not LightING) constants ]]
    --------------------------------------------------------------------------

    local LIGHTNING_MODE_NAMES =
    {
        "rain",
        "any",
        "always",
        "never",
    }
    local LIGHTNING_MODES = table.invert(LIGHTNING_MODE_NAMES)

    --------------------------------------------------------------------------
    --[[ Lighting (not LightNING) constants ]]
    --------------------------------------------------------------------------

    local SEASON_DYNRANGE_DAY = {
        temperate = .05,
        humid = .05,
        lush = .05,
        aporkalypse = .05
    }

    local SEASON_DYNRANGE_NIGHT = {  -- dusk and night
        temperate = 0,
        humid = 0,
        lush = 0,
        aporkalypse = 0
    }

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    -- Public
    self.inst = inst

    -- Private
    local _world = TheWorld
    local _map = _world.Map
    local _ismastersim = _world.ismastersim
    local _activatedplayer = nil

    -- Temperature cache
    local _temperature = TUNING.STARTING_TEMP

    -- Precipiation
    local _rainsound = false
    local _treerainsound = false
    local _umbrellarainsound = false
    local _seasonprogress = 0
    local _groundoverlay = nil

    -- Fog
    local _fullfog = false

    -- Dedicated server does not need to spawn the local fx
    local _hasfx = not TheNet:IsDedicated()
    local _rainfx = _hasfx and SpawnPrefab("rain") or nil
    local _pollenfx = _hasfx and SpawnPrefab("pollen") or nil

    -- Light
    local _daylight = true
    local _season = "temperate"

    -- Master simulation
    local _moisturerateval
    local _moisturerateoffset
    local _moistureratemultiplier
    local _moistureceilmultiplier
    local _moisturefloormultiplier
    local _fogmode
    local _ishayfever
    local _lightningmode
    local _minlightningdelay
    local _maxlightningdelay
    local _nextlightningtime
    local _lightningtargets
    local _lightningexcludetags

    -- Network
    local _noisetime = net_float(inst.GUID, "weather._noisetime")
    local _moisture = net_float(inst.GUID, "weather._moisture")
    local _moisturerate = net_float(inst.GUID, "weather._moisturerate")
    local _moistureceil = net_float(inst.GUID, "weather._moistureceil", "moistureceildirty")
    local _moisturefloor = net_float(inst.GUID, "weather._moisturefloor")
    local _fogtime = net_float(inst.GUID, "weather._fogtime")
    local _fogstate = net_tinybyte(inst.GUID, "weather._fogstate")
    local _precipmode = net_tinybyte(inst.GUID, "weather._precipmode")
    local _preciptype = net_tinybyte(inst.GUID, "weather._preciptype", "preciptypedirty")
    local _peakprecipitationrate = net_float(inst.GUID, "weather._peakprecipitationrate")
    local _wetness = net_float(inst.GUID, "weather._wetness")
    local _wet = net_bool(inst.GUID, "weather._wet", "wetdirty")

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function StartAmbientRainSound(intensity)
        if not _rainsound then
            _rainsound = true
            _world.SoundEmitter:PlaySound("dontstarve_DLC002/rain/islandrainAMB", "rain")
        end
        _world.SoundEmitter:SetParameter("rain", "intensity", intensity)
    end

    local function StopAmbientRainSound()
        if _rainsound then
            _rainsound = false
            _world.SoundEmitter:KillSound("rain")
        end
    end

    local function StartTreeRainSound(intensity)
        if not _treerainsound then
            _treerainsound = true
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC001/common/rain_on_tree", "treerainsound")
        end
        TheFocalPoint.SoundEmitter:SetParameter("treerainsound", "intensity", intensity)
    end

    local function StopTreeRainSound()
        if _treerainsound then
            _treerainsound = false
            TheFocalPoint.SoundEmitter:KillSound("treerainsound")
        end
    end

    local function StartUmbrellaRainSound()
        if not _umbrellarainsound then
            _umbrellarainsound = true
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/rain/rain_on_umbrella", "umbrellarainsound")
        end
    end

    local function StopUmbrellaRainSound()
        if _umbrellarainsound then
            _umbrellarainsound = false
            TheFocalPoint.SoundEmitter:KillSound("umbrellarainsound")
        end
    end

    local function SetGroundOverlay(overlay, level)
        if _groundoverlay ~= overlay then
            _groundoverlay = overlay
            _map:SetOverlayTexture(overlay.texture)
            _map:SetOverlayColor0(unpack(overlay.colour[1]))
            _map:SetOverlayColor1(unpack(overlay.colour[2]))
            _map:SetOverlayColor2(unpack(overlay.colour[3]))
        end
        _map:SetOverlayLerp(level)
    end

    local function SetWithPeriodicSync(netvar, val, period, ismastersim)
        if netvar:value() ~= val then
            local trunc = val > netvar:value() and "floor" or "ceil"
            local prevperiod = math[trunc](netvar:value() / period)
            local nextperiod = math[trunc](val / period)

            if prevperiod == nextperiod then
                -- Client and server update independently within current period
                netvar:set_local(val)
            elseif ismastersim then
                -- Server sync to client when period changes
                netvar:set(val)
            else
                -- Client must wait at end of period for a server sync
                netvar:set_local(nextperiod * period)
            end
        elseif ismastersim then
            -- Force sync when value stops changing
            netvar:set(val)
        end
    end

    local ForceResync = _ismastersim and function(netvar)
        netvar:set_local(netvar:value())
        netvar:set(netvar:value())
    end or nil

    local CalculateMoistureRate = _ismastersim and function()
        return _moisturerateval * _moistureratemultiplier + _moisturerateoffset
    end or nil

    local RandomizeMoistureCeil = _ismastersim and function()
        local moistureceil = _moistureceilmultiplier.min + math.random() * (_moistureceilmultiplier.max - _moistureceilmultiplier.min)
        return TUNING.TOTAL_DAY_TIME * moistureceil
    end or nil

    local RandomizeMoistureFloor = _ismastersim and function(season)
        return (.25 + math.random() * .5) * _moisture:value() * _moisturefloormultiplier
    end or nil

    local RandomizePeakPrecipitationRate = _ismastersim and function(season)
        local range = PEAK_PRECIPITATION_RANGES[season]
        return range.min + math.random() * (range.max - range.min)
    end or nil

    local function CalculatePrecipitationRate()
        if _precipmode:value() == PRECIP_MODES.always then
            return .1 + perlin(0, _noisetime:value() * .1, 0) * .9
        elseif _preciptype:value() ~= PRECIP_TYPES.none and _precipmode:value() ~= PRECIP_MODES.never then
            local p = math.max(0, math.min(1, (_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value())))
            local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * PI)
            return math.min(rate, _peakprecipitationrate:value())
        end
        return 0
    end

    local StartPrecipitation = _ismastersim and function(temperature)
        _nextlightningtime = GetRandomMinMax(_minlightningdelay or 5, _maxlightningdelay or 15)
        _moisture:set(_moistureceil:value())
        _moisturefloor:set(RandomizeMoistureFloor(_season))
        _peakprecipitationrate:set(RandomizePeakPrecipitationRate(_season))
        _preciptype:set(PRECIP_TYPES.rain)
    end or nil

    local StopPrecipitation = _ismastersim and function()
        _moisture:set(_moisturefloor:value())
        _moistureceil:set(RandomizeMoistureCeil())
        _preciptype:set(PRECIP_TYPES.none)
    end or nil

    local function CalculatePOP()
        return (_preciptype:value() ~= PRECIP_TYPES.none and 1)
            or ((_moistureceil:value() <= 0 or _moisture:value() <= _moisturefloor:value()) and 0)
            or (_moisture:value() < _moistureceil:value() and (_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value()))
            or 1
    end

    local function CalculateLight()
        if _precipmode:value() == PRECIP_MODES.never then
            return 1
        end
        local season = _season
        local dynrange = _daylight and SEASON_DYNRANGE_DAY[season] or SEASON_DYNRANGE_NIGHT[season]

        if _precipmode:value() == PRECIP_MODES.always then
            return 1 - dynrange
        end
        local p = 1 - math.min(math.max((_moisture:value() - _moisturefloor:value()) / (_moistureceil:value() - _moisturefloor:value()), 0), 1)
        if _preciptype:value() ~= PRECIP_TYPES.none then
            p = easing.inQuad(p, 0, 1, 1)
        end
        return p * dynrange + 1 - dynrange
    end

    local function CalculateWetnessRate(temperature, preciprate)
        return  -- Positive wetness rate when it's raining or fog
            (_preciptype:value() == PRECIP_TYPES.rain and easing.inSine(preciprate, MIN_WETNESS_RATE, MAX_WETNESS_RATE, 1))
            -- Negative drying rate when it's not raining or fog
            or -math.clamp(easing.linear(temperature, MIN_DRYING_RATE, MAX_DRYING_RATE, OPTIMAL_DRYING_TEMPERATURE) + easing.inExpo(_wetness:value(), 0, 1, MAX_WETNESS), .01, 1)
    end

    local function PushWeather()
        local data =
        {
            moisture = _moisture:value(),
            fullfog = _fullfog,
            fogstate = _fogstate:value(),
            fogtime = _fogtime:value(),
            fog_transition_time = FOG_TRANSITION_TIME,
            ishayfever = _ishayfever,
            pop = CalculatePOP(),
            precipitationrate = CalculatePrecipitationRate(),
            snowlevel = 0,
            wetness = _wetness:value(),
            light = CalculateLight(),
        }
        _world:PushEvent("weathertick", data)
        _world:PushEvent("plateauweathertick", data)
    end

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnSeasonTick(src, data)
        _season = data.season
        _seasonprogress = data.progress

        if _ismastersim then
            local p = 1 - math.sin(PI * data.progress * PROGRESS_MULTIPLIERS[_season])
            _moisturerateval = MOISTURE_RATES.MIN[_season] + p * (MOISTURE_RATES.MAX[_season] - MOISTURE_RATES.MIN[_season])
            _moisturerateoffset = 0

            _moisturerate:set(CalculateMoistureRate())
            _moistureceilmultiplier = MOISTURE_CEIL_MULTIPLIERS[_season] or MOISTURE_CEIL_MULTIPLIERS.temperate
            _moisturefloormultiplier = MOISTURE_FLOOR_MULTIPLIERS[_season] or MOISTURE_FLOOR_MULTIPLIERS.temperate

            if data.season == "lush" then
                if data.progress > 0.1 then
                    _ishayfever = true
                end
            elseif data.progress > 0.02 or data.season == "aporkalypse" then
                _ishayfever = false
            end
        end
    end

    local function OnTemperatureTick(src, temperature)
        _temperature = temperature
    end

    local function OnPhaseChanged(src, phase)
        _daylight = phase == "day"
    end

    local function OnPlayerActivated(src, player)
        _activatedplayer = player
        if _hasfx then
            _rainfx.entity:SetParent(player.entity)
            _pollenfx.entity:SetParent(player.entity)
            self:OnPostInit()
        end
    end

    local function OnPlayerDeactivated(src, player)
        if _activatedplayer == player then
            _activatedplayer = nil
        end
        if _hasfx then
            _rainfx.entity:SetParent(nil)
            _pollenfx.entity:SetParent(nil)
            if player == ThePlayer then
                _fullfog = false
            end
        end
    end

    local OnPlayerJoined = _ismastersim and function(src, player)
        for i, v in ipairs(_lightningtargets) do
            if v == player then
                return
            end
        end

        if player ~= nil then
            table.insert(_lightningtargets, player)
        end
    end or nil

    local OnPlayerLeft = _ismastersim and function(src, player)
        for i, v in ipairs(_lightningtargets) do
            if v == player then
                table.remove(_lightningtargets, i)
                return
            end
        end
    end or nil

    local OnForcePrecipitation = _ismastersim and function(src, enable)
        _moisture:set(enable ~= false and _moistureceil:value() or _moisturefloor:value())
    end or nil

    local OnSetPrecipitationMode = _ismastersim and function(src, mode)
        _precipmode:set(PRECIP_MODES[mode] or _precipmode:value())
    end or nil

    local OnSetMoistureScale = _ismastersim and function(src, data)
        _moistureratemultiplier = data or _moistureratemultiplier
        _moisturerate:set(CalculateMoistureRate())
    end or nil

    local OnSetFogMode = _ismastersim and function(src, mode)
        _fogmode = FOG_MODES[mode] or FOG_MODES.dynamic
    end or nil

    local OnDeltaMoisture = _ismastersim and function(src, delta)
        _moisture:set(math.min(math.max(_moisture:value() + delta, _moisturefloor:value()), _moistureceil:value()))
    end or nil

    local OnDeltaMoistureCeil = _ismastersim and function(src, delta)
        _moistureceil:set(math.max(_moistureceil:value() + delta, _moisturefloor:value()))
    end or nil

    local OnDeltaWetness = _ismastersim and function(src, delta)
        _wetness:set(math.clamp(_wetness:value() + delta, MIN_WETNESS, MAX_WETNESS))
    end or nil

    local OnSetLightningMode = _ismastersim and function(src, mode)
        _lightningmode = LIGHTNING_MODES[mode] or _lightningmode
    end or nil

    local OnSetLightningDelay = _ismastersim and function(src, data)
        if _preciptype:value() ~= PRECIP_TYPES.none and data.min and data.max then
            _nextlightningtime = GetRandomMinMax(data.min, data.max)
        end
        _minlightningdelay = data.min
        _maxlightningdelay = data.max
    end or nil

    local LIGHTNINGSTRIKE_CANT_TAGS = {"playerghost", "INLIMBO"}
    local LIGHTNINGSTRIKE_ONEOF_TAGS = {"lightningrod", "lightningtarget", "lightningblocker"}
    local LIGHTNINGSTRIKE_SEARCH_RANGE = 40
    local OnSendLightningStrike = _ismastersim and function(src, pos)
        local closest_generic = nil
        local closest_rod = nil
        local closest_blocker = nil

        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, LIGHTNINGSTRIKE_SEARCH_RANGE, nil, LIGHTNINGSTRIKE_CANT_TAGS, LIGHTNINGSTRIKE_ONEOF_TAGS)
        local blockers = nil
        for _, v in pairs(ents) do
            -- Track any blockers we find, since we redirect the strike position later,
            -- and might redirect it into their block range.
            local is_blocker = v.components.lightningblocker ~= nil
            if is_blocker then
                if blockers == nil then
                    blockers = {v}
                else
                    table.insert(blockers, v)
                end
            end

            if closest_blocker == nil and is_blocker
                    and (v.components.lightningblocker.block_rsq + 0.0001) > v:GetDistanceSqToPoint(pos:Get()) then
                closest_blocker = v
            elseif closest_rod == nil and v:HasTag("lightningrod") then
                closest_rod = v
            elseif closest_generic == nil then
                if (v.components.health == nil or not v.components.health:IsInvincible())
                        and not is_blocker -- If we're out of range of the first branch, ignore blocker objects.
                        and (v.components.playerlightningtarget == nil or math.random() <= v.components.playerlightningtarget:GetHitChance()) then
                    closest_generic = v
                end
            end
        end

        local strike_position = pos
        local prefab_type = "lightning"

        if closest_blocker ~= nil then
            closest_blocker.components.lightningblocker:DoLightningStrike(strike_position)
            prefab_type = "thunder"
        elseif closest_rod ~= nil then
            strike_position = closest_rod:GetPosition()

            -- Check if we just redirected into a lightning blocker's range.
            if blockers ~= nil then
                for _, blocker in ipairs(blockers) do
                    if blocker:GetDistanceSqToPoint(strike_position:Get()) < (blocker.components.lightningblocker.block_rsq + 0.0001) then
                        prefab_type = "thunder"
                        blocker.components.lightningblocker:DoLightningStrike(strike_position)
                        break
                    end
                end
            end

            -- If we didn't get blocked, push the event that does all the fx and behaviour.
            if prefab_type == "lightning" then
                closest_rod:PushEvent("lightningstrike")
            end
        else
            if closest_generic ~= nil then
                strike_position = closest_generic:GetPosition()

                -- Check if we just redirected into a lightning blocker's range.
                if blockers ~= nil then
                    for _, blocker in ipairs(blockers) do
                        if blocker:GetDistanceSqToPoint(strike_position:Get()) < (blocker.components.lightningblocker.block_rsq + 0.0001) then
                            prefab_type = "thunder"
                            blocker.components.lightningblocker:DoLightningStrike(strike_position)
                            break
                        end
                    end
                end

                -- If we didn't redirect, strike the playerlightningtarget if there is one.
                if prefab_type == "lightning" then
                    if closest_generic.components.playerlightningtarget ~= nil then
                        closest_generic.components.playerlightningtarget:DoStrike()
                    end
                end
            end

            -- If we're doing lightning, light nearby unprotected objects on fire.
            if prefab_type == "lightning" then
                ents = TheSim:FindEntities(strike_position.x, strike_position.y, strike_position.z, 3, nil, _lightningexcludetags)
                for _, v in pairs(ents) do
                    if v.components.burnable ~= nil then
                        v.components.burnable:Ignite()
                    end
                end
            end
        end

        SpawnPrefab(prefab_type).Transform:SetPosition(strike_position:Get())
    end or nil

    local OnSimUnpaused = _ismastersim and function()
        -- Force resync values that client may have simulated locally
        ForceResync(_noisetime)
        ForceResync(_moisture)
        ForceResync(_wetness)
    end or nil

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    --Initialize network variables
    _noisetime:set(0)
    _moisture:set(0)
    _moisturerate:set(0)
    _moistureceil:set(0)
    _moisturefloor:set(0)
    _fogtime:set(0)
    _fogstate:set(FOG_STATE.CLEAR)
    _precipmode:set(PRECIP_MODES.dynamic)
    _preciptype:set(PRECIP_TYPES.none)
    _peakprecipitationrate:set(1)
    _wetness:set(0)
    _wet:set(false)

    -- Dedicated server does not need to spawn the local fx
    if _hasfx then
        -- Initialize rain particles
        _rainfx.particles_per_tick = 0
        _rainfx.splashes_per_tick = 0

        -- Initialize pollen
        _pollenfx.particles_per_tick = 0
    end

    -- Register network variable sync events
    inst:ListenForEvent("moistureceildirty", function() _world:PushEvent("moistureceilchanged", _moistureceil:value()) end)
    inst:ListenForEvent("preciptypedirty", function() _world:PushEvent("precipitationchanged", PRECIP_TYPE_NAMES[_preciptype:value()]) end)
    inst:ListenForEvent("wetdirty", function() _world:PushEvent("wetchanged", _wet:value()) end)

    -- Register events
    inst:ListenForEvent("seasontick", OnSeasonTick, _world)
    inst:ListenForEvent("plateautemperature", OnTemperatureTick, _world)
    inst:ListenForEvent("phasechanged", OnPhaseChanged, _world)
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _world)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated, _world)

    if _ismastersim then
        -- Initialize master simulation variables
        _moisturerateval = 1
        _moisturerateoffset = 0
        _moistureratemultiplier = 1
        _moistureceilmultiplier = {min = 1, max = 2}
        _moisturefloormultiplier = 1
        _fogmode = FOG_MODES.dynamic
        _ishayfever = false
        _lightningmode = LIGHTNING_MODES.rain
        _minlightningdelay = nil
        _maxlightningdelay = nil
        _nextlightningtime = 5
        _lightningtargets = {}
        _lightningexcludetags = { "player", "INLIMBO", "lightningblocker" }

        for k, v in pairs(FUELTYPE) do
            if v ~= FUELTYPE.USAGE then  -- Not a real fuel
                table.insert(_lightningexcludetags, v .. "_fueled")
            end
        end

        for i, v in ipairs(AllPlayers) do
            table.insert(_lightningtargets, v)
        end

        _moisturerate:set(CalculateMoistureRate())
        _moistureceil:set(RandomizeMoistureCeil())

        -- Register master simulation events
        inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
        inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)
        inst:ListenForEvent("ms_forceprecipitation", OnForcePrecipitation, _world)
        inst:ListenForEvent("ms_setprecipitationmode", OnSetPrecipitationMode, _world)
        inst:ListenForEvent("ms_setmoisturescale", OnSetMoistureScale, _world)
        inst:ListenForEvent("ms_setfogmode", OnSetFogMode, _world)
        inst:ListenForEvent("ms_deltamoisture", OnDeltaMoisture, _world)
        inst:ListenForEvent("ms_deltamoistureceil", OnDeltaMoistureCeil, _world)
        inst:ListenForEvent("ms_deltawetness", OnDeltaWetness, _world)
        inst:ListenForEvent("ms_setlightningmode", OnSetLightningMode, _world)
        inst:ListenForEvent("ms_setlightningdelay", OnSetLightningDelay, _world)
        inst:ListenForEvent("ms_sendlightningstrike", OnSendLightningStrike, _world)
        inst:ListenForEvent("ms_simunpaused", OnSimUnpaused, _world)
    end

    PushWeather()
    inst:StartUpdatingComponent(self)

    --------------------------------------------------------------------------
    --[[ Post initialization ]]
    --------------------------------------------------------------------------

    if _hasfx then function self:OnPostInit()
        if _preciptype:value() == PRECIP_TYPES.rain then
            _rainfx:PostInit()
        end

        if _season == "lush" then
            _pollenfx:PostInit()
        end
    end end

    --------------------------------------------------------------------------
    --[[ Deinitialization ]]
    --------------------------------------------------------------------------

    if _hasfx then function self:OnRemoveEntity()
        if _rainfx.entity:IsValid() then
            _rainfx:Remove()
        end
        if _pollenfx.entity:IsValid() then
            _pollenfx:Remove()
        end
    end end

    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------

    --[[
        Client updates temperature, moisture, precipitation effects, and snow
        level on its own while server force syncs values periodically. Client
        cannot start, stop, or change precipitation on its own, and must wait
        for server syncs to trigger these events.
    --]]
    function self:OnUpdate(dt)
        -- Update noise
        SetWithPeriodicSync(_noisetime, _noisetime:value() + dt, NOISE_SYNC_PERIOD, _ismastersim)

        local preciprate = CalculatePrecipitationRate()

        -- Update moisture and toggle precipitation
        if _precipmode:value() == PRECIP_MODES.always then
            if _ismastersim and _preciptype:value() == PRECIP_TYPES.none then
                StartPrecipitation(_temperature)
            end
        elseif _precipmode:value() == PRECIP_MODES.never then
            if _ismastersim and _preciptype:value() ~= PRECIP_TYPES.none then
                StopPrecipitation()
            end
        elseif _preciptype:value() ~= PRECIP_TYPES.none then
            -- Dissipate moisture
            local moisture = math.max(_moisture:value() - preciprate * dt * PRECIP_RATE_SCALE, 0)
            if moisture <= _moisturefloor:value() then
                if _ismastersim then
                    StopPrecipitation()
                else
                    _moisture:set_local(math.min(_moisturefloor:value() + .001, _moisture:value()))
                end
            else
                SetWithPeriodicSync(_moisture, moisture, MOISTURE_SYNC_PERIOD, _ismastersim)
            end
        elseif _moistureceil:value() > 0 then
            -- Accumulate moisture
            local moisture = _moisture:value() + _moisturerate:value() * dt
            if moisture >= _moistureceil:value() then
                if _ismastersim then
                    StartPrecipitation(_temperature)
                else
                    _moisture:set_local(math.max(_moistureceil:value() - .001, _moisture:value()))
                end
            else
                SetWithPeriodicSync(_moisture, moisture, MOISTURE_SYNC_PERIOD, _ismastersim)
            end
        end

        -- Update wetness
        local wetrate = CalculateWetnessRate(_temperature, preciprate)
        SetWithPeriodicSync(_wetness, math.clamp(_wetness:value() + wetrate * dt, MIN_WETNESS, MAX_WETNESS), WETNESS_SYNC_PERIOD, _ismastersim)
        if _ismastersim then
            if _wet:value() then
                if _wetness:value() < DRY_THRESHOLD then
                    _wet:set(false)
                end
            elseif _wetness:value() > WET_THRESHOLD then
                _wet:set(true)
            end
        end

        -- Update precipitation effects
        if _preciptype:value() == PRECIP_TYPES.rain and not _fullfog then
            local preciprate_sound = preciprate
            if _activatedplayer == nil then
                StartTreeRainSound(0)
                StopUmbrellaRainSound()
            elseif _activatedplayer.replica.sheltered ~= nil and _activatedplayer.replica.sheltered:IsSheltered() then
                StartTreeRainSound(preciprate_sound)
                StopUmbrellaRainSound()
                preciprate_sound = preciprate_sound - .4
            else
                StartTreeRainSound(0)
                if _activatedplayer.replica.inventory:EquipHasTag("umbrella") then
                    preciprate_sound = preciprate_sound - .4
                    StartUmbrellaRainSound()
                else
                    StopUmbrellaRainSound()
                end
            end
            StartAmbientRainSound(preciprate_sound)
            if _hasfx then
                -- DST reduces rain fx but we need it
                local peakprecipitationrate = _peakprecipitationrate:value()
                _rainfx.particles_per_tick = (5 + peakprecipitationrate * 25) * preciprate
                _rainfx.splashes_per_tick = 8 * peakprecipitationrate * preciprate
            end
        else
            StopAmbientRainSound()
            StopTreeRainSound()
            StopUmbrellaRainSound()
            if _hasfx then
                _rainfx.particles_per_tick = 0
                _rainfx.splashes_per_tick = 0
            end
        end

        -- Update fog
        -- fog is created instead of rain during the humid season when it should rain and the atmo moisture is above a threshold
        -- client fog state wait for server sync
        if FOG_MOISTURE_CEIL[_season] and _moisture:value() >= FOG_MOISTURE_CEIL[_season] and _preciptype:value() == PRECIP_TYPES.rain and _fogmode ~= FOG_MODES.never then
            if _fogstate:value() ~= FOG_STATE.FOGGY then
                if _fogstate:value() ~= FOG_STATE.SETTING then
                    if _ismastersim then
                        _fogtime:set(FOG_TRANSITION_TIME)
                        _fogstate:set(FOG_STATE.SETTING)
                    end
                end

                if _fogstate:value() == FOG_STATE.SETTING then
                    SetWithPeriodicSync(_fogtime, _fogtime:value() - dt, FRAMES, _ismastersim)
                    if _fogtime:value() <= 5 and _hasfx and ThePlayer ~= nil then
                        ThePlayer:PushEvent("startfog")
                    end

                    if _fogtime:value() <= 0 then
                        _fullfog = true
                        if _ismastersim then
                            _fogtime:set(0)
                            _fogstate:set(FOG_STATE.FOGGY)
                        end
                    end
                end
            elseif not _fullfog then  -- on load or change character
                if _hasfx then
                    if ThePlayer ~= nil then
                        _fullfog = true
                        ThePlayer:PushEvent("setfog")
                    end
                else
                    _fullfog = true
                end
            end
        elseif _fogstate:value() ~= FOG_STATE.CLEAR then
            if _fogstate:value() ~= FOG_STATE.LIFTING then
                TheSim:ClearDSP(.5)
                if _hasfx and ThePlayer then
                    ThePlayer:PushEvent("stopfog")
                end

                if _ismastersim then
                    _fogtime:set(FOG_TRANSITION_TIME)
                    _fogstate:set(FOG_STATE.LIFTING)
                end
                _fullfog = false
            end

            if _fogstate:value() == FOG_STATE.LIFTING then
                SetWithPeriodicSync(_fogtime, _fogtime:value() - dt, FRAMES, _ismastersim)

                if _fogtime:value() <= 0 then
                    if _ismastersim then
                        _fogtime:set(0)
                        _fogstate:set(FOG_STATE.CLEAR)
                    end
                end
            end
        end

        -- Update pollen
        if _hasfx then
            if _season ~= "lush" or (ThePlayer ~= nil and _world.components.sandstorms ~= nil and _world.components.sandstorms:IsInSandstorm(ThePlayer)) then
                _pollenfx.particles_per_tick = 0
            elseif _seasonprogress < .2 then
                local ramp = _seasonprogress / .2
                _pollenfx.particles_per_tick = ramp * POLLEN_PARTICLES
            elseif _seasonprogress > .8 then
                local ramp = (1-_seasonprogress) / .2
                _pollenfx.particles_per_tick = ramp * POLLEN_PARTICLES
            else
                _pollenfx.particles_per_tick = POLLEN_PARTICLES
            end
        end

        if _ismastersim then
            -- Update lightning
            if _lightningmode == LIGHTNING_MODES.always or
                LIGHTNING_MODE_NAMES[_lightningmode] == PRECIP_TYPE_NAMES[_preciptype:value()] or
                (_lightningmode == LIGHTNING_MODES.any and _preciptype:value() ~= PRECIP_TYPES.none) then
                if _nextlightningtime > dt then
                    _nextlightningtime = _nextlightningtime - dt
                else
                    local min = _minlightningdelay or easing.linear(preciprate, 30, 10, 1)
                    local max = _maxlightningdelay or (min + easing.linear(preciprate, 30, 10, 1))
                    _nextlightningtime = GetRandomMinMax(min, max)
                    if (preciprate > .75 or _lightningmode == LIGHTNING_MODES.always) and next(_lightningtargets) ~= nil then
                        local targeti = math.min(math.floor(easing.inQuint(math.random(), 1, #_lightningtargets, 1)), #_lightningtargets)
                        local target = _lightningtargets[targeti]
                        table.remove(_lightningtargets, targeti)
                        table.insert(_lightningtargets, target)

                        local x, y, z = target.Transform:GetWorldPosition()
                        local radius = 2 + math.random() * 8
                        local theta = math.random() * 2 * PI
                        local pos = Vector3(x + radius * math.cos(theta), y, z + radius * math.sin(theta))
                        _world:PushEvent("ms_sendlightningstrike", pos)
                    else
                        SpawnPrefab(preciprate > .5 and "thunder_close" or "thunder_far")
                    end
                end
            end
        end

        -- SetGroundOverlay(GROUND_OVERLAYS.puddles, _wetness:value() * 3 / 100) -- wetness goes from 0-100

        PushWeather()
    end

    self.LongUpdate = self.OnUpdate

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnSave()
        return
        {
            temperature = _temperature,
            daylight = _daylight or nil,
            season = _season,
            noisetime = _noisetime:value(),
            moisturerateval = _moisturerateval,
            moisturerateoffset = _moisturerateoffset,
            moistureratemultiplier = _moistureratemultiplier,
            moisturerate = _moisturerate:value(),
            moisture = _moisture:value(),
            moisturefloor = _moisturefloor:value(),
            moistureceilmultiplier = _moistureceilmultiplier,
            moisturefloormultiplier = _moisturefloormultiplier,
            moistureceil = _moistureceil:value(),
            fogstate = _fogstate:value(),
            ishayfever = _ishayfever,
            precipmode = PRECIP_MODE_NAMES[_precipmode:value()],
            preciptype = PRECIP_TYPE_NAMES[_preciptype:value()],
            peakprecipitationrate = _peakprecipitationrate:value(),
            lightningmode = LIGHTNING_MODE_NAMES[_lightningmode],
            minlightningdelay = _minlightningdelay,
            maxlightningdelay = _maxlightningdelay,
            nextlightningtime = _nextlightningtime,
            wetness = _wetness:value(),
            wet = _wet:value() or nil,
        }
    end end

    if _ismastersim then function self:OnLoad(data)
        _temperature = data.temperature or TUNING.STARTING_TEMP
        _daylight = data.daylight == true
        _season = data.season or "temperate"
        _noisetime:set(data.noisetime or 0)
        _moisturerateval = data.moisturerateval or 1
        _moisturerateoffset = data.moisturerateoffset or 0
        _moistureratemultiplier = data.moistureratemultiplier or 1
        _moisturerate:set(data.moisturerate or CalculateMoistureRate())
        _moisture:set(data.moisture or 0)
        _moisturefloor:set(data.moisturefloor or 0)
        _moistureceilmultiplier = data.moistureceilmultiplier or {min = 1, max = 2}
        _moisturefloormultiplier = data.moisturefloormultiplier or 1
        _moistureceil:set(data.moistureceil or RandomizeMoistureCeil())
        _fogstate:set(data.fogstate or FOG_STATE.CLEAR)
        _ishayfever = data._ishayfever or false
        _precipmode:set(PRECIP_MODES[data.precipmode] or PRECIP_MODES.dynamic)
        _preciptype:set(PRECIP_TYPES[data.preciptype] or PRECIP_TYPES.none)
        _peakprecipitationrate:set(data.peakprecipitationrate or 1)
        _lightningmode = LIGHTNING_MODES[data.lightningmode] or LIGHTNING_MODES.rain
        _minlightningdelay = data.minlightningdelay
        _maxlightningdelay = data.maxlightningdelay
        _nextlightningtime = data.nextlightningtime or 5
        _wetness:set(data.wetness or 0)
        _wet:set(data.wet == true)

        PushWeather()
    end end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------

    function self:GetDebugString()
        local preciprate = CalculatePrecipitationRate()
        local wetrate = CalculateWetnessRate(_temperature, preciprate)
        local str =
        {
            string.format("temperature:%2.2f",_temperature),
            string.format("moisture:%2.2f(%2.2f/%2.2f) + %2.2f", _moisture:value(), _moisturefloor:value(), _moistureceil:value(), _moisturerate:value()),
            string.format("preciprate:(%2.2f of %2.2f)", preciprate, _peakprecipitationrate:value()),
            string.format("fog:%2.5f", _fogstate:value()),
            string.format("wetness:%2.2f(%s%2.2f)%s", _wetness:value(), wetrate > 0 and "+" or "", wetrate, _wet:value() and " WET" or ""),
            string.format("light:%2.5f", CalculateLight()),
        }

        if _ismastersim then
            table.insert(str, string.format("lightning:%2.2f", _nextlightningtime))
        end

        return table.concat(str, ", ")
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------

end)

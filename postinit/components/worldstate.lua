local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("worldstate", function(self, inst)

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------
    assert(inst == TheWorld, "Invalid world")

    -- Private
    local data = self.data

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local OnTemperatureTick = inst:GetEventCallbacks("temperaturetick", TheWorld, "scripts/components/worldstate.lua")
    local SetVariable = ToolUtil.GetUpvalue(OnTemperatureTick, "SetVariable")

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnPlateauTemperatureTick(src, temperature)
        SetVariable("temperature", temperature)
        SetVariable("plateautemperature", temperature)
    end

    local function OnSeasonTick(src, data)
        SetVariable("istemperate", data.season == "temperate", "temperate")
        SetVariable("ishumid", data.season == "humid", "humid")
        SetVariable("islush", data.season == "lush", "lush")
        SetVariable("isaporkalypse", data.season == "aporkalypse", "aporkalypse")
        SetVariable("preaporkalypseseason", data.preaporkalypseseason)
        SetVariable("preaporkalypseseasonprogress", data.preaporkalypseseasonprogress)
    end

    local function OnSeasonLengthsChanged(src, data)
        SetVariable("temperatelength", data.temperate)
        SetVariable("humidlength", data.humid)
        SetVariable("lushlength", data.lush)
        SetVariable("aporkalypselength", data.aporkalypse)
    end

    local function OnPlateauWeatherTick(src, data)
        SetVariable("fullfog", data.fogstate == FOG_STATE.FOGGY)
        SetVariable("fogstate", data.fogstate)
        SetVariable("fogtime", data.fogtime)
        SetVariable("fog_transition_time", data.fog_transition_time)
    end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    --[[
        World state variables are initialized to default values that can be
        used by entities if there are no world components controlling those
        variables.  e.g. If there is no season component on the world, then
        everything will run in temperate state.
    --]]

    data.plateautemperature = TUNING.STARTING_TEMP
    data.istemperate = true
    data.ishumid = false
    data.islush = false
    data.isaporkalypse = false
    data.preaporkalypseseason = "temperate"
    data.preaporkalypseseasonprogress = 0
    data.fullfog = false
    data.fogstate = FOG_STATE.CLEAR
    data.fogtime = 0
    data.fog_transition_time = 10

    if TheWorld:HasTag("porkland") then
        local OnTemperatureTick = inst:GetEventCallbacks("temperaturetick", nil, "scripts/components/worldstate.lua")
        inst:RemoveEventCallback("temperaturetick", OnTemperatureTick)
        inst:ListenForEvent("plateautemperaturetick", OnPlateauTemperatureTick)
    end

    inst:ListenForEvent("seasontick", OnSeasonTick)
    inst:ListenForEvent("seasonlengthschanged", OnSeasonLengthsChanged)
    inst:ListenForEvent("plateauweathertick", OnPlateauWeatherTick)
end)

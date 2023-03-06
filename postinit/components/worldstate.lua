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
    local SetVariable = UpvalueHacker.GetUpvalue(OnTemperatureTick, "SetVariable")

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnPlateauTemperatureTick(src, temperature)
        SetVariable("temperature", temperature)
        SetVariable("plateautemperature", temperature)
    end

    local function OnAporkalypseChange(src, isaporkalypse)
        SetVariable("isaporkalypse", isaporkalypse, "aporkalypse")
    end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    --[[
        World state variables are initialized to default values that can be
        used by entities if there are no world components controlling those
        variables.  e.g. If there is no season component on the world, then
        everything will run in autumn state.
    --]]

    data.plateautemperature = TUNING.STARTING_TEMP
    data.isaporkalypse = false

    if TheWorld:HasTag("porkland") then
        local OnTemperatureTick = inst:GetEventCallbacks("temperaturetick", nil, "scripts/components/worldstate.lua")
        inst:RemoveEventCallback("temperaturetick", OnTemperatureTick)
        inst:ListenForEvent("plateautemperaturetick", OnPlateauTemperatureTick)
    end

    inst:ListenForEvent("aporkalypsechange", OnAporkalypseChange)

    -- inst:ListenForEvent("snowcoveredchanged", function(inst, show)
    --     TheSim:HideAnimOnEntitiesWithTag("Climate_island", "snow")
    --     TheSim:HideAnimOnEntitiesWithTag("Climate_volcano", "snow")
    -- end)
end)

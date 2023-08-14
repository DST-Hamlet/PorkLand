local modname = modname
GLOBAL.setfenv(1, GLOBAL)

IACore.OnUnloadMods[modname] = function()
    IACore.WorldLocations[1].PORKLAND = nil

    IACore.OnUnloadlevel()
end

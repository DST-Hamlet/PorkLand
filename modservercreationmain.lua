local modimport = modimport
local modname = modname
GLOBAL.setfenv(1, GLOBAL)

if not rawget(_G, "IACore") then
    for i, _modname in ipairs(ModManager:GetEnabledServerModNames()) do
        local modinfo = KnownModIndex:GetModInfo(_modname)
        if modinfo.name == "Ia Core" then
            ModManager:FrontendLoadMod(_modname)
            break
        end
    end
end

modimport("modfrontendmain")
modimport("modcustonsizitems")

IACore.WorldLocations[1].PORKLAND = true

scheduler:ExecuteInTime(0, function()  -- Delay a frame so we can get ServerCreationScreen when entering a existing world
    local servercreationscreen = TheFrontEnd:GetOpenScreenOfType("ServerCreationScreen")

    if not (KnownModIndex:IsModEnabled(modname) and servercreationscreen) then
        return
    end

    if not servercreationscreen:CanResume() then  -- Only when first time creating the world
        IACore.SetLevelLocations(servercreationscreen, "porkland", 1)  -- Automatically try switching to the porkland Preset
    end
end)

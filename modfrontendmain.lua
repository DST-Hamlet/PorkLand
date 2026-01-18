local _modname = modname
GLOBAL.setfenv(1, GLOBAL)

local function OnUnloadlevel()
    local servercreationscreen = TheFrontEnd:GetOpenScreenOfType("ServerCreationScreen")

    PL_EnableWorldLocations = nil

    if not (servercreationscreen and servercreationscreen.world_tabs)  then
        return
    end

    SERVER_LEVEL_LOCATIONS = {"forest", "cave"}

    servercreationscreen:SetLevelLocations()

    for i, world_tab in ipairs(servercreationscreen.world_tabs) do
        local text = world_tab:GetLocationTabName()
        servercreationscreen.world_config_tabs.menu.items[i + 1]:SetText(text)

        if world_tab.choose_world_button then
            world_tab.choose_world_button:Hide()
        end
    end
end

local _FrontendUnloadMod = ModManager.FrontendUnloadMod
function ModManager:FrontendUnloadMod(modname, ...)
    if not modname or modname == _modname then  -- modname is nil unload all level
        OnUnloadlevel()
        ModManager.FrontendUnloadMod = _FrontendUnloadMod
    end

    return _FrontendUnloadMod(self, modname, ...)
end

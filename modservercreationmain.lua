FrontEndAssets = {
    Asset("ANIM", "anim/generating_hamlet.zip"),
    Asset("SOUND", "sound/DLC003_music_stream.fsb"),
    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev"),
}
ReloadFrontEndAssets()

local modname = modname
local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

modimport("main/toolutil")
modimport("main/strings")
modimport("modfrontendmain")
modimport("modcustonsizitems")

local TEMPLATES = require("widgets/redux/templates")
local PopupDialogScreen = require("screens/redux/popupdialog")
local ChooseWorldSreen = require("widgets/redux/chooseworldscreen")

local world_locations = {
    [1] = {FOREST = true, PORKLAND = true, CAVE = true},
    [2] = {CAVE = true}
}

local function SetLevelLocations(servercreationscreen, location, i)
    local server_level_locations = {}
    server_level_locations[i] = location
    server_level_locations[3 - i] = SERVER_LEVEL_LOCATIONS[3 - i]
    servercreationscreen:SetLevelLocations(server_level_locations)
    local text = servercreationscreen.world_tabs[i]:GetLocationTabName()
    servercreationscreen.world_config_tabs.menu.items[i + 1]:SetText(text)
end

local function OnWorldButton(world_tab, i)
    if world_tab:GetParentScreen() then
        world_tab:GetParentScreen().last_focus = TheFrontEnd:GetFocusWidget()
    end
    local currentworld = world_tab:GetLocation()
    local chooseworldscreen = ChooseWorldSreen(world_tab, currentworld, i, SetLevelLocations, world_locations)
    TheFrontEnd:PushScreen(chooseworldscreen)
end

scheduler:ExecuteInTime(0, function()  -- Delay a frame so we can get ServerCreationScreen when entering a existing world
    local servercreationscreen = TheFrontEnd:GetOpenScreenOfType("ServerCreationScreen")

    if not (KnownModIndex:IsModEnabled(modname) and servercreationscreen and servercreationscreen.world_tabs and servercreationscreen.world_tabs[1]) then
        return
    end

    for i, world_tab in ipairs(servercreationscreen.world_tabs) do
        if servercreationscreen:CanResume() and world_tab:GetLocation() ~= SERVER_LEVEL_LOCATIONS[i] then
            SERVER_LEVEL_LOCATIONS[i] = world_tab:GetLocation()
            servercreationscreen.world_tabs[i]:RefreshOptionItems()
            local text = servercreationscreen.world_tabs[i]:GetLocationTabName()
            servercreationscreen.world_config_tabs.menu.items[i + 1]:SetText(text)
        end

        if world_tab.settings_widget:IsNewShard() then
            if not world_tab.choose_world_button then
                world_tab.choose_world_button = world_tab.settings_root:AddChild(TEMPLATES.StandardButton(function() OnWorldButton(world_tab, i) end, STRINGS.UI.SANDBOXMENU.CHOOSEWORLD))
                world_tab.choose_world_button.image:SetScale(.47)
                world_tab.choose_world_button.text:SetColour(0, 0, 0, 1)
                world_tab.choose_world_button:SetTextSize(19.6)
                world_tab.choose_world_button:SetPosition(320, 285)
            elseif not world_tab.choose_world_button.shown then
                world_tab.choose_world_button:Show()
            end
        end
    end

    if not servercreationscreen:CanResume() then  -- Only when first time creating the world
        SetLevelLocations(servercreationscreen, "porkland", 1)  -- Automatically try switching to the porkland Preset
    end
end)

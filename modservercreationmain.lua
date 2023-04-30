local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

PLENV.modimport("main/pl_util")
PLENV.modimport("modfrontendmain")
PLENV.modimport("modcustonsizitems")

local Menu = require("widgets/menu")
local ImageButton = require("widgets/imagebutton")

local function SetLevelLocations(servercreationscreen, location)
    servercreationscreen:SetLevelLocations({location, "cave"})
    local text = servercreationscreen.world_tabs[1]:GetLocationTabName()
    servercreationscreen.world_config_tabs.menu.items[2]:SetText(text)
end

scheduler:ExecuteInTime(0, function()  -- Delay a frame so we can get ServerCreationScreen when entering a existing world
    local servercreationscreen = TheFrontEnd:GetOpenScreenOfType("ServerCreationScreen")

    if not (KnownModIndex:IsModEnabled(PLENV.modname) and servercreationscreen and servercreationscreen.world_tabs and servercreationscreen.world_tabs[1]) then
        return
    end

    local world_tab = servercreationscreen.world_tabs[1]

    if not servercreationscreen:CanResume() then  -- Only when first time creating the world then
        SetLevelLocations(servercreationscreen, "porkland")
    elseif world_tab:GetLocation() ~= SERVER_LEVEL_LOCATIONS[1] then
        SERVER_LEVEL_LOCATIONS[1] = world_tab:GetLocation()
        servercreationscreen.world_tabs[1]:RefreshOptionItems()
        local text = servercreationscreen.world_tabs[1]:GetLocationTabName()
        servercreationscreen.world_config_tabs.menu.items[2]:SetText(text)
    end

    if not world_tab.world_locations then
        world_tab.world_locations = {FOREST = true, PORKLAND = true, CAVE = true}

        local menuitems = {}
        for location in pairs(world_tab.world_locations) do
            table.insert(menuitems, {text = STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[location], cb = function() SetLevelLocations(servercreationscreen, location:lower()) end, style = "carny_long"})
        end
        world_tab.choose_world_menu = world_tab:AddChild(Menu(menuitems, 100))

    elseif not world_tab.world_locations.PORKLAND then
        world_tab.world_locations.PORKLAND = true
        world_tab.choose_world_menu:AddItem(STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME.PORKLAND, function() SetLevelLocations(servercreationscreen, "porkland") end)
    end

    world_tab.choose_world_menu:Hide()

    if not world_tab.choose_world_button then
        world_tab.choose_world_button = world_tab:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))

        world_tab.choose_world_button.image:SetScale(.49)
        world_tab.choose_world_button:SetFont(CHATFONT)
        world_tab.choose_world_button.text:SetColour(0, 0, 0, 1)
        world_tab.choose_world_button:SetOnClick(function(self, ...)
            if world_tab.choose_world_menu.shown then
                world_tab.choose_world_menu:Hide()
            else
                world_tab.choose_world_menu:Show()
            end
        end)
        world_tab.choose_world_button:SetTextSize(19.6)
        world_tab.choose_world_button:SetText(STRINGS.UI.SANDBOXMENU.CHOOSEWORLD)
        world_tab.choose_world_button:SetPosition(430, 290)
    end

    world_tab.choose_world_button:Show()
end)

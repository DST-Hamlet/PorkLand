-- [WARNING]: This file is imported into modclientmain.lua, be careful!
if not env.is_mim_enabled then
    FrontEndAssets = {
        Asset("IMAGE", "images/hud/customization_porkland.tex"),
        Asset("ATLAS", "images/hud/customization_porkland.xml"),
    }
    ReloadFrontEndAssets()

    modimport("main/strings")
end

local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Menu = require("widgets/menu")
local ImageButton = require("widgets/imagebutton")

local Customize = require("map/customize")

local worldgen_atlas = "images/worldgen_customization.xml"
local pl_atlas = "images/hud/customization_porkland.xml"

local function GetUpvalue(fn, name)
	local i = 1
	while debug.getupvalue(fn, i) and debug.getupvalue(fn, i) ~= name do
		i = i + 1
	end
	local _, value = debug.getupvalue(fn, i)
	return value, i
end

local function add_group_and_item(category, name, text, desc, atlas, order, items)
    if text then  -- assume that if the group has a text string its new
        PLENV.AddCustomizeGroup(category, name, text, desc, atlas or pl_atlas, order)
    end
    if items then
        for k, v in pairs(items) do
            PLENV.AddCustomizeItem(category, name, k, v)
        end
    end
end

local frequency_descriptions = {
    {text = STRINGS.UI.SANDBOXMENU.SLIDENEVER,    data = "never"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDERARE,     data = "rare"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT,  data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEOFTEN,    data = "often"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEALWAYS,   data = "always"},
}

local season_length_descriptions = {
    {text = STRINGS.UI.SANDBOXMENU.SLIDENEVER,     data = "noseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSHORT, data = "veryshortseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDESHORT,     data = "shortseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT,   data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDELONG,      data = "longseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYLONG,  data = "verylongseason"},
    {text = STRINGS.UI.SANDBOXMENU.RANDOM,         data = "random"},
}

local pl_customize_table = {
    porkland_settings_global = {
        order = 0,
        category = LEVELCATEGORY.SETTINGS,
        text = STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME.PORKLAND .. STRINGS.UI.SANDBOXMENU.CHOICEGLOBAL,
        items = {
            temperate  = {value = "default", image = "temperate.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 2, master_controlled = true},
            humid      = {value = "default", image = "humid.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 3, master_controlled = true},
            lush       = {value = "default", image = "lush.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 4, master_controlled = true},
            -- aporkalypse = {value = "default", image = "dry.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 5, master_controlled = true},
        }
    },
}

local custonsiz_items = {
    [LEVELCATEGORY.WORLDGEN] = {
        monsters = {
            "grass_tall_patch",
        },
        animals = {
            ["peagawk_spawner"] = {image = "peagawk.tex"}
        },
        resources = {
            "asparagus",
            "grass_tall",
        },
        misc = {
            ["jungle_border_vine"] = {desc = frequency_descriptions},
            ["deep_jungle_fern_noise"] = {desc = frequency_descriptions},
        }
    },
    [LEVELCATEGORY.SETTINGS] = {
        monsters = {
            weevole_setting = {image = "weevole.tex"},
        },
        animals = {
            peagawk_setting = {image = "peagawk.tex"},
        },
        resources = {
            asparagus_regrowth = {image = "asparagus.tex"},
        }
    }
}

local change_items = {  -- change dst settings
    worldgen = {
        resources = {"rock", "sapling", "grass", "flowers", "reeds", "mushroom"},
        misc = {"task_set", "start_location", "world_size", "touchstone", "boons"},
    },
    world_settings = {
        resources = {"flowers_regrowth", "reeds_regrowth"},
        animals = {"butterfly"}
    }
}

local WORLDGEN_GROUP = GetUpvalue(Customize.GetWorldGenOptions, "WORLDGEN_GROUP")
local WORLDSETTINGS_GROUP = GetUpvalue(Customize.GetWorldSettingsOptions, "WORLDSETTINGS_GROUP")
for category, category_data in pairs(change_items) do
    local GROUP = category == "worldgen" and WORLDGEN_GROUP or WORLDSETTINGS_GROUP
    for group, items in pairs(category_data) do
        for _, item in ipairs(items) do
            table.insert(GROUP[group].items[item].world, "porkland")
        end
    end
end

for name, data in pairs(pl_customize_table) do
    add_group_and_item(data.category, name, data.text, data.desc, data.atlas, data.order, data.items)
end

for category, category_data in pairs(custonsiz_items) do
    for group, group_data in pairs(category_data) do
        for item, data in pairs(group_data) do
            local name = item
            local itemsettings = data
            if type(data) == "string" then
                name = itemsettings
                itemsettings = {}
            end

            itemsettings.image = itemsettings.image or name .. ".tex"
            itemsettings.value = itemsettings.value or "default"
            itemsettings.world = itemsettings.world or {"porkland"}
            itemsettings.atlas = pl_atlas
            PLENV.AddCustomizeItem(category, group, name, itemsettings)
        end
    end
end


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

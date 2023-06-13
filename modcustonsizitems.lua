-- [WARNING]: This file is imported into modclientmain.lua, be careful!
if not env.is_mim_enabled then
    FrontEndAssets = {
        Asset("IMAGE", "images/hud/customization_porkland.tex"),
        Asset("ATLAS", "images/hud/customization_porkland.xml"),
    }
    ReloadFrontEndAssets()

    modimport("main/strings")
end

local AddCustomizeItem = AddCustomizeItem
local AddCustomizeGroup = AddCustomizeGroup
GLOBAL.setfenv(1, GLOBAL)

local Customize = require("map/customize")

local worldgen_atlas = "images/worldgen_customization.xml"
local pl_atlas = "images/hud/customization_porkland.xml"

local season_start_descriptions = {
    {text = STRINGS.UI.SANDBOXMENU.PORKLAND_DEFAULT, data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.HUMID, data = "humid"},
    {text = STRINGS.UI.SANDBOXMENU.LUSH, data = "lush"},
    {text = STRINGS.UI.SANDBOXMENU.RANDOM, data = "temperate|humid|lush"},
}

local frequency_descriptions = {
    {text = STRINGS.UI.SANDBOXMENU.SLIDENEVER,   data = "never"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDERARE,    data = "rare"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEOFTEN,   data = "often"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEALWAYS,  data = "always"},
}

local season_length_descriptions = {
    {text = STRINGS.UI.SANDBOXMENU.SLIDENEVER,     data = "noseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSHORT, data = "veryshortseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDESHORT,     data = "shortseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT,   data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDELONG,      data = "longseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYLONG,  data = "verylongseason"},
    {text = STRINGS.UI.SANDBOXMENU.RANDOM,         data = "random"}
}

local enable_descriptions = {
    {text = STRINGS.UI.SANDBOXMENU.SLIDENEVER,   data = "never"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default"}
}

local pl_customize_table = {  -- we customize
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

local custonsiz_items = {  -- add in dst custonsiz
    [LEVELCATEGORY.WORLDGEN] = {
        ["global"] = {  -- global is keywords
            porkland_season_start = {image = "season_start.tex", options_remap = {img = "blank_season_red.tex", atlas = "images/customisation.xml"}, desc = season_start_descriptions, master_controlled = true, order = 2}
        },
        monsters = {
            "grass_tall_patch",
        },
        animals = {
            peagawk_spawner = {image = "peagawk.tex"}
        },
        resources = {
            "asparagus",
            "grass_tall",
        },
        misc = {
            jungle_border_vine = {desc = frequency_descriptions},
            deep_jungle_fern_noise = {desc = frequency_descriptions},
        }
    },
    [LEVELCATEGORY.SETTINGS] = {
        monsters = {
            weevole_setting = {image = "weevole.tex"},
        },
        animals = {
            peagawk_setting = {image = "peagawk.tex"},
            glowfly_setting = {image = "glowflies.tex"},
            dung_beetle_setting = {image = "dung_beetles.tex"},
            pog_setting = {image = "pogs.tex"},
            hippopotamoose_setting = {image = "hippopotamoose.tex"},
        },
        resources = {
            asparagus_regrowth = {image = "asparagus.tex"},
        },
        misc = {
            fog = {desc = enable_descriptions},
            glowflycycle = {image = "glowfly_life_cycle.tex", desc = enable_descriptions},
            poison = {desc = enable_descriptions}
        },
    }
}

local change_items = {  -- change dst custonsiz settings
    worldgen = {
        resources = {"rock", "sapling", "grass", "flowers", "reeds", "mushroom"},
        misc = {"task_set", "start_location", "world_size", "touchstone", "boons"},
    },
    world_settings = {
        resources = {"regrowth", "flowers_regrowth", "reeds_regrowth"},
        animals = {"butterfly"},
        misc = {"lightning", "weather"}
    }
}

local function add_group_and_item(category, name, text, desc, atlas, order, items)
    if text then  -- assume that if the group has a text string its new
        AddCustomizeGroup(category, name, text, desc, atlas or pl_atlas, order)
    end
    if items then
        for k, v in pairs(items) do
            AddCustomizeItem(category, name, k, v)
        end
    end
end

local WORLDGEN_GROUP = Pl_Util.GetUpvalue(Customize.GetWorldGenOptions, "WORLDGEN_GROUP")
local WORLDSETTINGS_GROUP = Pl_Util.GetUpvalue(Customize.GetWorldSettingsOptions, "WORLDSETTINGS_GROUP")
for category, category_data in pairs(change_items) do  -- use dst custonsiz settings for porkland
    local GROUP = category == "worldgen" and WORLDGEN_GROUP or WORLDSETTINGS_GROUP
    for group, items in pairs(category_data) do
        for _, item in ipairs(items) do
            table.insert(GROUP[group].items[item].world, "porkland")
        end
    end
end

for name, data in pairs(pl_customize_table) do  -- add we customize
    add_group_and_item(data.category, name, data.text, data.desc, data.atlas, data.order, data.items)
end

for category, category_data in pairs(custonsiz_items) do  -- -- add to dst custonsiz
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
            AddCustomizeItem(category, group, name, itemsettings)
        end
    end
end

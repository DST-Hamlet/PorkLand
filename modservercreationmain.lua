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

local ImageButton = require("widgets/imagebutton")

local size_descriptions = PLENV.GetCustomizeDescription("size_descriptions")
local yesno_descriptions = PLENV.GetCustomizeDescription("yesno_descriptions")
local enableddisabled_descriptions = PLENV.GetCustomizeDescription("enableddisabled_descriptions")

local frequency_descriptions = {
    { text = STRINGS.UI.SANDBOXMENU.SLIDENEVER,    data = "never" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDERARE,     data = "rare" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT,  data = "default" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEOFTEN,    data = "often" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEALWAYS,   data = "always" },
}

local worldgen_frequency_descriptions = {
    { text = STRINGS.UI.SANDBOXMENU.SLIDENEVER, data = "never" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDERARE, data = "rare" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEUNCOMMON, data = "uncommon" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEOFTEN, data = "often" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEMOSTLY, data = "mostly" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEALWAYS, data = "always" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEINSANE, data = "insane" },
}

local speed_descriptions = {
    { text = STRINGS.UI.SANDBOXMENU.SLIDENEVER, data = "never" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSLOW, data = "veryslow" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDESLOW, data = "slow" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEFAST, data = "fast" },
    { text = STRINGS.UI.SANDBOXMENU.SLIDEVERYFAST, data = "veryfast" },
}

local worldgen_atlas = "images/worldgen_customization.xml"
local pl_atlas = "images/hud/customization_porkland.xml"

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

local clocktype = {
    {text = STRINGS.UI.SANDBOXMENU.CLOCKTYPE_DEFAULT, data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.CLOCKTYPE_PORKLAND, data = "plateau"},
}

local season_length_descriptions = {
    {text = STRINGS.UI.SANDBOXMENU.SLIDENEVER, data = "noseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYSHORT, data = "veryshortseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDESHORT, data = "shortseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEDEFAULT, data = "default"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDELONG, data = "longseason"},
    {text = STRINGS.UI.SANDBOXMENU.SLIDEVERYLONG, data = "verylongseason"},
    {text = STRINGS.UI.SANDBOXMENU.RANDOM, data = "random"},
}

local pl_customize_table = {
    pl_settings_global = {
        order = 0,
        category = LEVELCATEGORY.SETTINGS,
        text = STRINGS.UI.SANDBOXMENU.CUSTOMIZATIONPREFIX_PL .. STRINGS.UI.SANDBOXMENU.CHOICEGLOBAL,
        items = {
            pl_clocktype  = {value = "default", image = "blank_world.tex", desc = clocktype, order = 1, world = {"forest", "cave"}},
            temperate     = {value = "default", image = "temperate.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 2, master_controlled = true},
            humid         = {value = "default", image = "humid.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 3, master_controlled = true},
            lush          = {value = "default", image = "lush.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 4, master_controlled = true},
            -- aporkalypse = {value = "default", image = "dry.tex", options_remap = {img = "blank_season_yellow.tex", atlas = "images/customisation.xml"}, desc = season_length_descriptions, order = 5, master_controlled = true},
        }
    },
}

for name, data in pairs(pl_customize_table) do
    add_group_and_item(data.category, name, data.text, data.desc, data.atlas, data.order, data.items)
end

PLCustomizeTable = pl_customize_table

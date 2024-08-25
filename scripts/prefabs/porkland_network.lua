local MakeWorldNetwork = require("prefabs/world_network")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/world_network.lua"),
}

local prefabs =
{
    "thunder_close",
    "thunder_far",
    "thunder",
    "lightning",
}

local function custom_postinit(inst)
    inst:AddComponent("plateauweather")
    inst.components.weather = inst.components.plateauweather
    inst:AddComponent("plateauwind")
    inst:AddComponent("worldplateautemperature")

    -- Compatible with Global Positions https://github.com/rezecib/Global-Positions
    if softresolvefilepath("scripts/components/globalpositions.lua") then
        inst:AddComponent("globalpositions")
    end
end

return MakeWorldNetwork("porkland_network", prefabs, assets, custom_postinit)

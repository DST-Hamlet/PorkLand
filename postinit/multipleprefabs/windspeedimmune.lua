local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local immune_to_wind = {
    "crawlingnightmare",
    "nightmarebeak",
    "crawlinghorror",
    "terrorbeak",
    "oceanhorror",
    "ghost",
}

local function add_wind_speed_immune(inst)
    inst:AddTag("windspeedimmune")
end

for _, prefab in ipairs(immune_to_wind) do
    AddPrefabPostInit(prefab, add_wind_speed_immune)
end

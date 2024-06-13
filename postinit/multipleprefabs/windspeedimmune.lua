local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local immune_to_wind = {
    "crawlinghorror",
    "crawlingnightmare",
    "ghost",
    "nightmarebeak",
    "oceanhorror",
    "terrorbeak",
}

for _, prefab in pairs(immune_to_wind) do
    AddPrefabPostInit(prefab, function(inst)
        inst:AddTag("windspeedimmune")
    end)
end

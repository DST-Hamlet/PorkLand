local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local notraptrigger_mobs = {
    "abigail",
    "chester",
    "crawlinghorror",
    "crawlingnightmare",
    "nightmarebeak",
    "terrorbeak",
}

local function add_tag(inst)
    inst:AddTag("notraptrigger")
end

for _, prefab in pairs(notraptrigger_mobs) do
   AddPrefabPostInit(prefab, add_tag)
end

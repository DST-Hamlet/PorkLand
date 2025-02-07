local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local shadow_creatures =
{
    "crawlinghorror",
    "terrorbeak",
    "crawlingnightmare",
    "nightmarebeak"
}

for _, name in pairs(shadow_creatures) do
    AddPrefabPostInit(name, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst.components.locomotor.pathcaps = {ignorewalls = true, ignorecreep = true, allowocean = true}
    end)
end

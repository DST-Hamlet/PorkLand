local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local TRADER = require("prefabs/pig_trades_defs").TRADER

local function add_tradable(inst)
    if not TheWorld.ismastersim then
        return
    end
    if not inst.components.tradable then
        inst:AddComponent("tradable")
    end
end

for _, def in pairs(TRADER) do
    for _, prefab in ipairs(def.items) do
        AddPrefabPostInit(prefab, add_tradable)
    end
end

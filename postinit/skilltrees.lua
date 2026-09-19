local GetModConfigData = GetModConfigData
GLOBAL.setfenv(1, GLOBAL)
--local GetModConfigData = GetModConfigData
local skilltreedefs = require("prefabs/skilltree_defs")

if not GetModConfigData("classical_skilltree") then
    for characterprefab in pairs(skilltreedefs.SKILLTREE_DEFS) do
        skilltreedefs.SKILLTREE_DEFS[characterprefab] = nil
    end
end
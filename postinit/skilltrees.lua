GLOBAL.setfenv(1, GLOBAL)

local skilltreedefs = require("prefabs/skilltree_defs")

for characterprefab in pairs(skilltreedefs.SKILLTREE_DEFS) do
    skilltreedefs.SKILLTREE_DEFS[characterprefab] = nil
end

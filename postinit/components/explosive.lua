GLOBAL.setfenv(1, GLOBAL)

local Explosive = require("components/explosive")

local _OnBurnt = Explosive.OnBurnt
function Explosive:OnBurnt()
    local interiorID = self.inst:GetCurrentInteriorID()
    if interiorID then
        local name = TheWorld.components.interiorspawner.interiors[interiorID].dungeon_name
        if not name or not name:find("pig_shop") then -- maybe we should define interior quake rooms as constants instead?
            TheWorld:PushEvent("interior_startquake", {interiorID = interiorID, quake_level = INTERIOR_QUAKE_LEVELS.PILLAR_WORKED})
        end
    end

    _OnBurnt(self)
end

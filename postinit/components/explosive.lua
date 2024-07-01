GLOBAL.setfenv(1, GLOBAL)

local Explosive = require("components/explosive")

local _OnBurnt = Explosive.OnBurnt
function Explosive:OnBurnt()
    local interiorID = self.inst:GetCurrentInteriorID()
    if interiorID then
        TheWorld:PushEvent("interior_startquake", {interiorID = interiorID, quake_level = INTERIOR_QUAKE_LEVELS.PILLAR_WORKED})
    end

    _OnBurnt(self)
end

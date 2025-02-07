GLOBAL.setfenv(1, GLOBAL)

local Explosive = require("components/explosive")

local _OnBurnt = Explosive.OnBurnt
function Explosive:OnBurnt()
    local owner = self.inst and self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner() or nil
    if owner and owner:HasTag("pocketdimension_container") then
        self.inst:Remove()
        return
    end
    local interiorID = self.inst:GetCurrentInteriorID()
    if interiorID then
        local name = TheWorld.components.interiorspawner.interior_defs[interiorID].dungeon_name
        if name and not (name:find("pig_shop") or name:find("playerhouse") or name == "pig_palace") then -- maybe we should define interior quake rooms as constants instead?
            TheWorld:PushEvent("interior_startquake", {interiorID = interiorID, quake_level = INTERIOR_QUAKE_LEVELS.PILLAR_WORKED})
        end
    end

    return _OnBurnt(self)
end

GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Burnable = require("components/burnable")

local _SpawnFX = Burnable.SpawnFX
function Burnable:SpawnFX(...)
    if self.nofx then
        return
    end
    return _SpawnFX(self, ...)
end

function Burnable:SetAllowInventoryBurning(allow)
    if allow then
        self.inst:AddTag("allowinventoryburning")
    else
        self.inst:RemoveTag("allowinventoryburning")
    end
end

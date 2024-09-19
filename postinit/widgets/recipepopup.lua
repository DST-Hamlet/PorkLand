GLOBAL.setfenv(1, GLOBAL)

local RecipePopup = require("widgets/recipepopup")

local refresh = RecipePopup.Refresh
function RecipePopup:Refresh(...)
    if not self.owner then
        return refresh(self, ...)
    end
    -- See postinit/components/inventory_replica.lua
    self.owner.replica.inventory.check_all_oincs = true
    local ret = { refresh(self, ...) }
    self.owner.replica.inventory.check_all_oincs = nil
    return unpack(ret)
end

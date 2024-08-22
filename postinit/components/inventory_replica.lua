GLOBAL.setfenv(1, GLOBAL)

local Inventory = require("components/inventory_replica")

local has = Inventory.Has
function Inventory:Has(prefab, amount, checkallcontainers, ...)
    if self.check_all_oincs and prefab == "oinc" then
        local _, oincamount = has(self, "oinc", 0, true)
        local _, oinc10amount = has(self, "oinc10", 0, true)
        local _, oinc100amount = has(self, "oinc100", 0, true)
        local total = oincamount + (oinc10amount * 10) + (oinc100amount * 100)
        return total >= amount, total
    end
    return has(self, prefab, amount, checkallcontainers, ...)
end

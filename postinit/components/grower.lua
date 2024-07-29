GLOBAL.setfenv(1, GLOBAL)

local Grower = require("components/grower")

local plant_item = Grower.PlantItem
function Grower:PlantItem(...)
    local ret = { plant_item(self, ...) }
    if self.inst.components.citypossession and self.inst.components.citypossession.cityID then
        for plant in pairs(self.crops) do
            if not plant.components.citypossession then
                plant:AddComponent("citypossession")
            end
            plant.components.citypossession:SetCity(self.inst.components.citypossession.cityID)
        end
    end
    return unpack(ret)
end

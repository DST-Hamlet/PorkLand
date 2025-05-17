GLOBAL.setfenv(1, GLOBAL)

local Eater = require("components/eater")

local _TestFood = Eater.TestFood
function Eater:TestFood(food, ...)
    local success = true
    if self.testfoodfn then
        success = self.testfoodfn(self.inst, food)
    end

    return success and _TestFood(self, food, ...)
end

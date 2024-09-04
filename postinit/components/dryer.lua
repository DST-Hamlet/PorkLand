GLOBAL.setfenv(1, GLOBAL)

local Dryer = require("components/dryer")

local _Resume = Dryer.Resume
function Dryer:Resume()
    if self.product == "walkingstick" and self.ingredient == nil then
        return
    end
    _Resume(self)
end

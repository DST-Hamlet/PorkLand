local Pickable = require("components/pickable")

local PlPickable = Class(Pickable, function(self, inst)
    Pickable._ctor(self, inst)
    self.caninteractwith = false
end)

return PlPickable

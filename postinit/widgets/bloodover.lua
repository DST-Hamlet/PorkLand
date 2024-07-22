GLOBAL.setfenv(1, GLOBAL)
local BloodOver = require("widgets/bloodover")

local _Flash = BloodOver.Flash
function BloodOver:Flash(...)
    if self.owner:HasTag("ironlord") then
        return
    end
    _Flash(self, ...)
end

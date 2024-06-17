GLOBAL.setfenv(1, GLOBAL)


local Rider = require("components/rider")

function Rider:GetMountSpeedMultiplier()
    return self.inst.replica.rider:GetMountSpeedMultiplier()
end

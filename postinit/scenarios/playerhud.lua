GLOBAL.setfenv(1, GLOBAL)

local PoisonOver = require("widgets/poisonover")
local PlayerHud = require("screens/playerhud")

local _CreateOverlays = PlayerHud.CreateOverlays
function PlayerHud:CreateOverlays(owner, ...)
    _CreateOverlays(self, owner, ...)

    self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))
end

GLOBAL.setfenv(1, GLOBAL)

local Battleborn = require("components/battleborn")

local _OnAttack = Battleborn.OnAttack
function Battleborn:OnAttack(data, ...)
    if data.target and not data.target:HasTag("no_durability_loss_on_hit") then
        _OnAttack(self, data, ...)
    end
end

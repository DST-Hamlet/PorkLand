GLOBAL.setfenv(1, GLOBAL)
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------

local OldAger = require("components/oldager")

local _OnTakeDamage = OldAger.OnTakeDamage
function OldAger:OnTakeDamage(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    if cause == "drowning" then
        return false
    end
    return _OnTakeDamage(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
end

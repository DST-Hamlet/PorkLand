GLOBAL.setfenv(1, GLOBAL)

local Skinner = require("components/skinner")

local function empty_fn() end

local set_skin_mode = Skinner.SetSkinMode
function Skinner:SetSkinMode(skintype, default_build, ...)
    local set_skins_on_anim = SetSkinsOnAnim
    if self.inst:HasTag("ironlord") and skintype ~= "living_suit" then
        SetSkinsOnAnim = empty_fn
    end
    local ret = { set_skin_mode(self, skintype, default_build, ...) }
    SetSkinsOnAnim = set_skins_on_anim
    return unpack(ret)
end

local GetModConfigData = GetModConfigData
GLOBAL.setfenv(1, GLOBAL)

local SkillTreeToast = require("widgets/skilltreetoast")
local ScrapbookToast = require("widgets/scrapbooktoast")

if not GetModConfigData("classical_skilltree") then
    -- Those two are the popup on top left corner of the HUD
    function SkillTreeToast:UpdateElements()
        -- do nothing
    end

    function ScrapbookToast:UpdateElements()
        -- do nothing
    end
end

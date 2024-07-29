GLOBAL.setfenv(1, GLOBAL)

local ex_fns = require("prefabs/player_common_extensions")

local _ConfigurePlayerLocomotor = ex_fns.ConfigurePlayerLocomotor
function ex_fns.ConfigurePlayerLocomotor(inst, ...)
    _ConfigurePlayerLocomotor(inst, ...)
    UpdateSailorPathcaps(inst, inst:IsSailing())
end

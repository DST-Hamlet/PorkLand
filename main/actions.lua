local AddAction = AddAction
GLOBAL.setfenv(1, GLOBAL)

local PEAGAWK_TRANSFORM = Action({})  -- Dummy action for flup hiding
PEAGAWK_TRANSFORM.id = "PEAGAWK_TRANSFORM"
PEAGAWK_TRANSFORM.str = ""
AddAction(PEAGAWK_TRANSFORM)

PEAGAWK_TRANSFORM.fn = function(act)
    return true
end

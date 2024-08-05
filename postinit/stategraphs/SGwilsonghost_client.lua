local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

-- local TIMEOUT = 2

local actionhandlers = {
    ActionHandler(ACTIONS.USEDOOR, "jumpin_pre"),
}

local eventhandlers = {

}

local states = {

}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilsonghost_client", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilsonghost_client", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilsonghost_client", state)
end

AddStategraphPostInit("wilsonghost_client", function(sg)

end)

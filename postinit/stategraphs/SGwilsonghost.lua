local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local actionhandlers = {
    ActionHandler(ACTIONS.USEDOOR, "jumpin_pre"),
}

local eventhandlers = {

}

local states = {

}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilsonghost", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilsonghost", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilsonghost", state)
end

AddStategraphPostInit("wilsonghost", function(sg)

end)

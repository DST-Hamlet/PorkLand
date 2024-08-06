local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local actionhandlers = {
    ActionHandler(ACTIONS.USEDOOR, "usedoor_pre"),
}

local eventhandlers = {

}

local states = {
    State{
        name = "usedoor_pre",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dissipate")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt", nil, nil, true)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.bufferedaction ~= nil then
                        inst:PerformBufferedAction()
                    end
                    inst.sg:GoToState("haunt")
                end
            end),
        },
    },
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

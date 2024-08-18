local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

-- local TIMEOUT = 2

local actionhandlers = {
    ActionHandler(ACTIONS.USEDOOR, "usedoor_pre"),
}

local eventhandlers = {

}

local states = {
    State{
        name = "usedoor_pre",
        tags = { "doing", "busy", "canrotate" },
        server_states = { "usedoor_pre"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dissipate")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt", nil, nil, true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("appear")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("appear")
            inst.sg:GoToState("idle", true)
        end,
    },
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

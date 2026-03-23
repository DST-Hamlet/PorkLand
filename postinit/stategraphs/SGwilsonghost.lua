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

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst)
                if inst.components.playercontroller then
                    inst.components.playercontroller:Enable(false)
                end

                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                if target and not target.components.door:IsLocked() then
                    inst:ScreenFade(false, 0.4)
                    inst.sg.statemem.screenfaded = true
                end

                inst.sg.statemem.fadetask = inst:DoStaticTaskInTime(2, function() -- 用于防止服务器暂停导致卡死
                    if inst.sg.statemem.screenfaded then
                        inst:ScreenFade(true, 0.4)
                        inst.sg.statemem.screenfaded = false
                    end
                end)
            end),
        },

        onexit = function(inst)
            if inst.components.playercontroller then
                inst.components.playercontroller:Enable(true)
            end
            if inst.sg.statemem.screenfaded then
                inst:ScreenFade(true, 0.4)
                inst.sg.statemem.screenfaded = false
            end
            if inst.sg.statemem.fadetask then
                inst.sg.statemem.fadetask:Cancel()
                inst.sg.statemem.fadetask = nil
            end
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

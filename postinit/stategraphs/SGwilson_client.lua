local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local TIMEOUT = 2
local DoFoleySounds = nil

local actionhandlers = {
    ActionHandler(ACTIONS.RETRIEVE, "dolongaction"),
    ActionHandler(ACTIONS.TOGGLEON, "give"),
    ActionHandler(ACTIONS.TOGGLEOFF, "give"),
    ActionHandler(ACTIONS.REPAIRBOAT, "dolongaction"),
    ActionHandler(ACTIONS.HACK, function(inst)
        if inst:HasTag("beaver") then
            return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
        end
        return not inst.sg:HasStateTag("prehack") and "hack_start" or nil
    end),
    ActionHandler(ACTIONS.PAN, function(inst)
        if not inst.sg:HasStateTag("panning") then
            return "pan_start"
        end
    end),
    ActionHandler(ACTIONS.SHEAR, function(inst)
        return not inst.sg:HasStateTag("preshear") and "shear_start" or nil
    end),
}

local eventhandlers = {
    EventHandler("sailequipped", function(inst)
        if inst.sg:HasStateTag("rowing") then
            inst.sg:GoToState("sail")
        end
    end),

    EventHandler("sailunequipped", function(inst)
        if inst.sg:HasStateTag("sailing") then
            inst.sg:GoToState("row")

            if not inst:HasTag("mime") then
                inst.AnimState:OverrideSymbol("paddle", "swap_paddle", "paddle")
            end
            -- TODO allow custom paddles?
            inst.AnimState:OverrideSymbol("wake_paddle", "swap_paddle", "wake_paddle")
        end
    end),
}

local states = {
    State{
        name = "row_start",
        tags = {"moving", "running", "rowing", "boating", "canrotate"},

        onenter = function(inst)
            local boat = inst.replica.sailor:GetBoat()

            inst.components.locomotor:RunForward()

            if not inst:HasTag("mime") then
                inst.AnimState:OverrideSymbol("paddle", "swap_paddle", "paddle")
            end
            -- TODO allow custom paddles?
            inst.AnimState:OverrideSymbol("wake_paddle", "swap_paddle", "wake_paddle")

            local oar = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

            inst.AnimState:PlayAnimation(oar and oar:HasTag("oar") and "row_pre" or "row_pre_pl")
            if boat and boat.replica.sailable then
                boat.replica.sailable:PlayPreRowAnims()
            end

            DoFoleySounds(inst)
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("row") end),
        },
    },

    State{
        name = "row",
        tags = {"moving", "running", "rowing", "boating", "canrotate"},

        onenter = function(inst)
            local boat = inst.replica.sailor:GetBoat()

            if boat and boat.replica.sailable and boat.replica.sailable.creaksound then
                inst.SoundEmitter:PlaySound(boat.replica.sailable.creaksound, nil, nil, true)
            end
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat/paddle", nil, nil, true)
            DoFoleySounds(inst)

            local oar = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

            local anim = oar and oar:HasTag("oar") and "row_medium" or "row_loop"
            if not inst.AnimState:IsCurrentAnimation(anim) then
                --RoT has row_medium, which is identical but uses the equipped item as paddle
                inst.AnimState:PlayAnimation(anim, true)
            end

            if boat and boat.replica.sailable then
                boat.replica.sailable:PlayRowAnims()
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        onexit = function(inst)
            local boat = inst.replica.sailor:GetBoat()
            if inst.sg.nextstate ~= "row" and inst.sg.nextstate ~= "sail" then
                inst.components.locomotor:Stop(nil, true)
                if inst.sg.nextstate ~= "row_stop" and inst.sg.nextstate ~= "sail_stop" then
                    if boat and boat.replica.sailable then
                        boat.replica.sailable:PlayIdleAnims(true)
                    end
                end
            end
        end,

        timeline = {
            TimeEvent(8 * FRAMES, function(inst)
                local boat = inst.replica.sailor:GetBoat()
                if boat and boat.replica.container then
                    local trawlnet = boat.replica.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
                    if trawlnet and trawlnet.rowsound then
                        inst.SoundEmitter:PlaySound(trawlnet.rowsound, nil, nil, true)
                    end
                end
            end),
        },

        events = {
            EventHandler("trawlitem", function(inst)
                local boat = inst.replica.sailor:GetBoat()
                if boat and boat.replica.sailable then
                    boat.replica.sailable:PlayTrawlOverAnims()
                end
            end),
        },

        ontimeout = function(inst) inst.sg:GoToState("row") end,
    },

    State{
        name = "row_stop",
        tags = {"canrotate", "idle"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            local boat = inst.replica.sailor:GetBoat()

            local oar = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

            inst.AnimState:PlayAnimation(oar and oar:HasTag("oar") and "row_idle_pst" or "row_pst")
            if boat and boat.replica.sailable then
                boat.replica.sailable:PlayPostRowAnims()
            end
        end,

        events = {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "sail_start",
        tags = {"moving", "running", "canrotate", "boating", "sailing"},

        onenter = function(inst)
            local boat = inst.replica.sailor:GetBoat()

            inst.components.locomotor:RunForward()

            local anim = boat.replica.sailable.sailstartanim or "sail_pre"
            if anim ~= "sail_pre" or inst.has_sailface then
                inst.AnimState:PlayAnimation(anim)
            else
                inst.AnimState:PlayAnimation("sail_pre")
            end

            if boat and boat.replica.sailable then
                boat.replica.sailable:PlayPreSailAnims()
            end
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("sail") end),
        },
    },

    State{
        name = "sail",
        tags = {"canrotate", "moving", "running", "boating", "sailing"},

        onenter = function(inst)
            local boat = inst.replica.sailor:GetBoat()

            local loopsound = nil
            local flapsound = nil

            if boat and boat.replica.container and boat.replica.container.hasboatequipslots then
                local sail = boat.replica.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
                if sail then
                    loopsound = sail.loopsound
                    flapsound = sail.flapsound
                end
            elseif boat and boat.replica.sailable and boat.replica.sailable.sailsound then
                loopsound = boat.replica.sailable.sailsound
            end

            if not inst.SoundEmitter:PlayingSound("sail_loop") and loopsound then
                inst.SoundEmitter:PlaySound(loopsound, "sail_loop", nil, true)
            end

            if flapsound then
                inst.SoundEmitter:PlaySound(flapsound, nil, nil, true)
            end

            if boat and boat.replica.sailable and boat.replica.sailable.creaksound then
                inst.SoundEmitter:PlaySound(boat.replica.sailable.creaksound, nil, nil, true)
            end


            local anim = boat and boat.replica.sailable and boat.replica.sailable.sailloopanim or "sail_loop"
            if not inst.AnimState:IsCurrentAnimation(anim) then
                if anim ~= "sail_loop" or inst.has_sailface then
                    inst.AnimState:PlayAnimation(anim, true)
                else
                    inst.AnimState:PlayAnimation("sail_loop", true)
                end
            end
            if boat and boat.replica.sailable then
                boat.replica.sailable:PlaySailAnims()
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        onexit = function(inst)
            local boat = inst.replica.sailor:GetBoat()
            if inst.sg.nextstate ~= "sail" then
                inst.SoundEmitter:KillSound("sail_loop")
                if inst.sg.nextstate ~= "row" then
                    inst.components.locomotor:Stop(nil, true)
                end
                if inst.sg.nextstate ~= "row_stop" and inst.sg.nextstate ~= "sail_stop" then
                    if boat and boat.replica.sailable then
                        boat.replica.sailable:PlayIdleAnims()
                    end
                end
            end
        end,

        events = {
            EventHandler("trawlitem", function(inst)
                local boat = inst.replica.sailor:GetBoat()
                if boat and boat.replica.sailable then
                    boat.replica.sailable:PlayTrawlOverAnims()
                end
            end),
        },

        ontimeout = function(inst) inst.sg:GoToState("sail") end,
    },

    State{
        name = "sail_stop",
        tags = {"canrotate", "idle"},

        onenter = function(inst)
            local boat = inst.replica.sailor:GetBoat()

            inst.components.locomotor:Stop()
            local anim = boat.replica.sailable.postsailanim or "sail_pst"
            if anim ~= "sail_pst" or inst.has_sailface then
                inst.AnimState:PlayAnimation(anim)
            else
                inst.AnimState:PlayAnimation("sail_pst")
            end
            if boat and boat.replica.sailable then
                boat.replica.sailable:PlayPostSailAnims()
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hack_start",
        tags = {"prehack", "hacking", "working"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if not inst:HasTag("working") then
                local action = inst:GetBufferedAction()
                local tool = action ~= nil and action.invobject or nil
                local hacksymbols = tool ~= nil and tool.hack_overridesymbols or nil
                if hacksymbols ~= nil then
                    hacksymbols[3] = tool:GetSkinBuild()
                    if hacksymbols[3] ~= nil then
                        inst.AnimState:OverrideItemSkinSymbol("swap_machete", hacksymbols[3], hacksymbols[1], tool.GUID, hacksymbols[2])
                    else
                        inst.AnimState:OverrideSymbol("swap_machete", hacksymbols[1], hacksymbols[2])
                    end
                    inst.AnimState:PlayAnimation("hack_pre")
                    inst.AnimState:PushAnimation("hack_lag", false)
                else
                    inst.AnimState:PlayAnimation("chop_pre")
                    inst.AnimState:PushAnimation("chop_lag", false)
                end
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "pan_start",
        tags = {"prepan", "panning", "working"},
        server_states = {"pan_start", "pan"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst.sg:ServerStateMatches() then
                inst.AnimState:PlayAnimation("pan_pre")
                inst.AnimState:PushAnimation("pan_loop", false) -- TODO: make pan_lag anim
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pan_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "shear_start",
        tags = {"preshear", "working"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if not inst:HasTag("working") then
                inst.AnimState:PlayAnimation("cut_pre")
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("cut_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "castspell_bone",
        tags = {"doing", "busy", "canrotate", "spell"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("staff_pre")
            inst.AnimState:PushAnimation("staff_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },
}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson_client", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilson_client", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilson_client", state)
end

AddStategraphPostInit("wilson_client", function(sg)
    local _run_start_timeevent_2 = sg.states["run_start"].timeline[2].fn
    DoFoleySounds = ToolUtil.GetUpvalue(_run_start_timeevent_2, "DoFoleySounds")

    local _locomote_eventhandler = sg.events.locomote.fn
    sg.events.locomote.fn = function(inst, data)
        if inst.sg:HasStateTag("busy") or inst:HasTag("busy") then
            return
        end
        local is_attacking = inst.sg:HasStateTag("attack")

        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()
        if inst.replica.sailor and inst.replica.sailor:GetBoat() and not inst.replica.sailor:GetBoat().replica.sailable then
            should_move = false
        end

        local should_run = inst.components.locomotor:WantsToRun()
        local hasSail = inst.replica.sailor and inst.replica.sailor:GetBoat() and inst.replica.sailor:GetBoat().replica.sailable:GetIsSailEquipped() or false

        if inst:HasTag("_sailor") and inst:HasTag("sailing") then
            if not is_attacking then
                if is_moving and not should_move then
                    if hasSail then
                        inst.sg:GoToState("sail_stop")
                    else
                        inst.sg:GoToState("row_stop")
                    end
                elseif not is_moving and should_move or (is_moving and should_move and is_running ~= should_run) then
                    if hasSail then
                        inst.sg:GoToState("sail_start")
                    else
                        inst.sg:GoToState("row_start")
                    end
                end
            end
            return
        end

        _locomote_eventhandler(inst, data)
    end

    local _castspell_deststate = sg.actionhandlers[ACTIONS.CASTSPELL].deststate
    sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action)
        local staff = action.invobject or action.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if staff:HasTag("bonestaff") then
            return "castspell_bone"
        else
            return _castspell_deststate and _castspell_deststate(inst, action)
        end
    end
end)

local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

local TIMEOUT = 2
local DoFoleySounds = nil

local actionhandlers = {
    ActionHandler(ACTIONS.RENOVATE, "dolongaction"),
    ActionHandler(ACTIONS.SHOP, "doshortaction"),
    ActionHandler(ACTIONS.TAKEFROMSHELF, "doshortaction"),
    ActionHandler(ACTIONS.PUTONSHELF, "doshortaction"),
    ActionHandler(ACTIONS.RETRIEVE, "dolongaction"),
    ActionHandler(ACTIONS.TOGGLEON, "give"),
    ActionHandler(ACTIONS.TOGGLEOFF, "give"),
    ActionHandler(ACTIONS.REPAIRBOAT, "dolongaction"),
    ActionHandler(ACTIONS.HACK, function(inst)
        if inst:HasTag("ironlord") then
            return not inst.sg:HasStateTag("punchworking") and "ironlord_work" or nil
        end
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
    ActionHandler(ACTIONS.DISLODGE, function(inst)
        return not inst.sg:HasStateTag("pretap") and "tap_start" or nil
    end),
    ActionHandler(ACTIONS.CUREPOISON, function(inst, action)
        local target = action.target

        if not target or target == inst then
            return "curepoison"
        else
            return "give"
        end
    end),
    ActionHandler(ACTIONS.USEDOOR, "usedoor"),
    ActionHandler(ACTIONS.WEIGHDOWN, "doshortaction"),
    ActionHandler(ACTIONS.DISARM, "dolongaction"),
    ActionHandler(ACTIONS.REARM, "dolongaction"),
    ActionHandler(ACTIONS.SPY, function(inst, action)
        if not inst.sg:HasStateTag("preinvestigate") then
            if action.invobject ~= nil and action.invobject:HasTag("goggles") then
                return "goggle"
            else
                return "investigate_start"
            end
        end
    end),
    ActionHandler(ACTIONS.USE_LIVING_ARTIFACT, "give"),
    ActionHandler(ACTIONS.CHARGE_UP, "ironlord_charge"),
    ActionHandler(ACTIONS.CHARGE_RELEASE, function(inst, action)
        if inst.sg:HasStateTag("strafing") then
            inst.sg.statemem.should_shoot = true
            inst.sg.mem.shootpos = action:GetActionPoint()
        end
    end),
    ActionHandler(ACTIONS.GAS, function(inst)
        return "crop_dust"
    end),
    ActionHandler(ACTIONS.SEARCH_MYSTERY, "dolongaction"),
    ActionHandler(ACTIONS.BUILD_ROOM, "doshortaction"),
    ActionHandler(ACTIONS.DEMOLISH_ROOM, "doshortaction"),
    ActionHandler(ACTIONS.THROW, "throw"),
    ActionHandler(ACTIONS.DODGE, "dodge"),
}

local eventhandlers = {
    EventHandler("sailequipped", function(inst)
        if inst.sg:HasStateTag("rowing") then
            inst.sg:GoToState("sail")
        end
    end),

    EventHandler("sailunequipped", function(inst)
        if inst.sg:HasStateTag("sailing") then
            inst.sg:GoToState("pl_row")

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
        name = "curepoison",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("quick_eat_pre")
            inst.AnimState:PushAnimation("quick_eat_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
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
            EventHandler("animover", function(inst) inst.sg:GoToState("pl_row") end),
        },
    },

    State{
        name = "pl_row",
        tags = {"moving", "running", "rowing", "boating", "canrotate"},

        onenter = function(inst)
            local boat = inst.replica.sailor:GetBoat()

            if boat and boat.replica.sailable and boat.replica.sailable.creaksound then
                inst.SoundEmitter:PlaySound(boat.replica.sailable.creaksound, nil, nil, true)
            end
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat_paddle", nil, nil, true)
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
            if inst.sg.nextstate ~= "pl_row" and inst.sg.nextstate ~= "sail" then
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

        ontimeout = function(inst) inst.sg:GoToState("pl_row") end,
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
                if inst.sg.nextstate ~= "pl_row" then
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
        tags = {"doing", "busy", "canrotate", "spell", "strafing"},
        server_states = {"castspell_bone"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("staff_pre")
            inst.AnimState:PushAnimation("staff", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,

        EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
    },

    State{
        name = "tap_start",
        tags = {"pretap", "working"},
        server_states = {"tap_start", "tap", "tap_end"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if not inst:HasTag("working") then
                inst.AnimState:PlayAnimation("tamp_pre")
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
                inst.AnimState:PlayAnimation("tamp_pst")
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "usedoor",
        tags = {"doing", "busy"},
        server_states = {"usedoor"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("give")

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)

            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            if target and TagToDirect(target) then
                inst.Transform:SetRotation(TagToDirect(target))
            end
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("give_pst")
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "investigate_start",
        tags = {"preinvestigate", "investigating", "working"},
        server_states = {"investigate_start", "investigate", "investigate_post"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if not inst:HasTag("investigating") then
                inst.AnimState:PlayAnimation("lens")
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
                inst.AnimState:PlayAnimation("lens_pst")
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "goggle",
        tags = {"preinvestigate", "investigating", "working"},
        server_states = {"goggle", "goggle_post"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if not inst:HasTag("investigating") then
                inst.AnimState:PlayAnimation("goggle")
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("investigating") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("goggle_pst")
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "ironlord_charge",
        tags = {"busy", "doing", "strafing", "charge"},
        server_states = {"ironlord_charge", "ironlord_charge_full"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("charge_pre")
            inst.AnimState:PushAnimation("charge_grow")
            inst.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/iron_lord/charge_up_LP", "chargedup")

            inst.sg.statemem.ready_to_shoot = false
            inst.sg.statemem.should_shoot = false

            inst:PerformPreviewBufferedAction()
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("chargedup")
        end,

        onupdate = function(inst)
            if inst.sg.statemem.should_shoot then
                if inst.sg.statemem.ready_to_shoot then
                    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser",  {intensity = math.random(0.7, 1)})
                else
                    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/smallshot", {timeoffset = math.random()})
                end
                inst.SoundEmitter:KillSound("chargedup")
                inst.sg:GoToState("ironlord_shoot", inst.sg.statemem.ready_to_shoot)
            end
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.sg.statemem.ready_to_shoot = true end),
            TimeEvent(20 * FRAMES, function(inst)
                inst.AnimState:PlayAnimation("charge_super_pre")
                inst.AnimState:PushAnimation("charge_super_loop", true)
                inst.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/iron_lord/electro")
                inst.sg.statemem.ready_to_shoot = false
            end),
            TimeEvent(25 * FRAMES, function(inst) inst.sg.statemem.ready_to_shoot = true end),
        },
    },


    State{
        name = "ironlord_shoot",
        tags = {"busy"},
        server_states = {"ironlord_shoot"},

        onenter = function(inst, is_full_charge)
            inst.components.locomotor:Stop()
            if is_full_charge then
                inst.AnimState:PlayAnimation("charge_super_pst")
            else
                inst.AnimState:PlayAnimation("charge_pst")
            end
            inst.sg.statemem.is_full_charge = is_full_charge

            if inst.sg.mem.shootpos ~= nil then
                inst:ForceFacePoint(inst.sg.mem.shootpos:Get())
            end
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),

        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State{
        name = "ironlord_work",
        tags = {"prepunchwork", "punchworking", "working"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("power_punch")

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
            inst.sg:GoToState("idle", true)
        end,
    },

    State{
        name = "ironlord_attack",
        tags = {"attack", "abouttoattack"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("power_punch")
            inst.sg.statemem.target = target
            inst.replica.combat:StartAttack()

            inst:PerformPreviewBufferedAction()

            if target and target:IsValid() then
                inst:FacePoint(inst.replica.combat:GetTarget().Transform:GetWorldPosition())
            end

        end,

        timeline = {
            TimeEvent(8  * FRAMES, function(inst) inst:PerformPreviewBufferedAction() inst.sg:RemoveStateTag("abouttoattack") end),
            TimeEvent(13 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") inst.sg:AddStateTag("idle") end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
                inst.replica.combat:CancelAttack()
            end
        end,
    },

    State{
        name = "crop_dust",
        tags = {"busy", "canrotate"},
        server_states = {"crop_dust"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("cropdust_pre")
            inst.AnimState:PushAnimation("cropdust_loop")

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("cropdust_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("cropdust_pst")
            inst.sg:GoToState("idle", true)
        end
    },

    State{
        name = "shoot",
        tags = {"attack", "notalking", "abouttoattack", "busy"},

        onenter = function(inst)
            if inst.replica.rider:IsRiding() then
                inst.Transform:SetFourFaced()
            end
            local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon and weapon:HasTag("hand_gun") then
                inst.AnimState:PlayAnimation("hand_shoot")
            else
                inst.AnimState:PlayAnimation("shoot")
            end

            local buffaction = inst:GetBufferedAction()
            local target = buffaction and buffaction.target
            inst.replica.combat:SetTarget(target)
            inst.replica.combat:StartAttack()
            inst.components.locomotor:Stop()

            if target and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
            end
        end,

        timeline=
        {
            TimeEvent(17*FRAMES, function(inst)
                inst:PerformPreviewBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst.sg:RemoveStateTag("attack")
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },

        onexit = function(inst)
            if inst.replica.rider:IsRiding() then
                inst.Transform:SetSixFaced()
            end
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
                inst.replica.combat:CancelAttack()
            end
        end,
    },

    State{
        name = "blunderbuss",
        tags = {"attack", "notalking", "abouttoattack"},

        onenter = function(inst)
            if inst:HasTag("_sailor") and inst:HasTag("sailing") then
                inst.sg:AddStateTag("boating")
            end
            local target = inst.replica.combat:GetTarget()
            inst.sg.statemem.target = target
            inst.replica.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("speargun")

            if target and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
            end
        end,

        timeline=
        {

            TimeEvent(12*FRAMES, function(inst)
                inst:PerformPreviewBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/weapon/blunderbuss_shoot")
            end),
            TimeEvent(20*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
                inst.replica.combat:CancelAttack()
            end
        end,
    },

    State{
        name = "map",
        tags = {"doing"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("scroll", false)
            inst.AnimState:OverrideSymbol("scroll", "messagebottle", "scroll")
            inst.AnimState:PushAnimation("scroll_pst", false)

            inst:PerformPreviewBufferedAction()
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        timeline=
        {
            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/treasuremap_open") end),
            TimeEvent(58 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/treasuremap_close") end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                inst:PerformBufferedAction()
            end),


            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State
    {
        name = "dodge",
        tags = {"busy", "evade", "no_stun", "canrotate"},

        onenter = function(inst)
            local action = inst:GetBufferedAction()
            if action then
                local pos = action:GetActionPoint()
                inst:ForceFacePoint(pos)
            end

            inst.sg:SetTimeout(TUNING.DODGE_TIMEOUT)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("slide_pre")

            inst.AnimState:PushAnimation("slide_loop")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/slide")
            inst.Physics:SetMotorVelOverride(20, 0, 0)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.last_dodge_time = GetTime()
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("dodge_pst")
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()

            inst.components.locomotor:SetBufferedAction(nil)
        end,
    },

    State
    {
        name = "dodge_pst",
        tags = {"evade", "no_stun"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("slide_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        }
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
        local hasSail = inst.replica.sailor and inst.replica.sailor:GetBoat() and inst.replica.sailor:GetBoat().replica.sailable and inst.replica.sailor:GetBoat().replica.sailable:GetIsSailEquipped() or false

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
    sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action, ...)
        local staff = action.invobject or action.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if staff:HasTag("bonestaff") then
            return "castspell_bone"
        else
            return _castspell_deststate and _castspell_deststate(inst, action, ...)
        end
    end

    local _attack_onenter = sg.states["attack"].onenter
    sg.states["attack"].onenter = function(inst, data)
        local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equip and equip:HasTag("halberd") then
            inst.SoundEmitter:OverrideSound("dontstarve/wilson/attack_weapon", "dontstarve_DLC003/common/items/weapon/halberd")
        elseif equip and equip:HasTag("corkbat") then
            inst.SoundEmitter:OverrideSound("dontstarve/wilson/attack_weapon", "dontstarve_DLC003/common/items/weapon/corkbat")
        elseif equip and equip:HasTag("cutlass") then
            inst.SoundEmitter:OverrideSound("dontstarve/wilson/attack_weapon", "dontstarve_DLC002/common/swordfish_sword")
        end

        _attack_onenter(inst, data)

        inst.SoundEmitter:OverrideSound("dontstarve/wilson/attack_weapon", nil)

        if equip and equip:HasTag("corkbat") then
            inst.sg:SetTimeout(23 * FRAMES)
        end
    end

    local _start_sitting_onenter = sg.states["start_sitting"].onenter
    sg.states["start_sitting"].onenter = function(inst, ...)
        _start_sitting_onenter(inst, ...)
        local buffaction = inst:GetBufferedAction()
        local chair = buffaction ~= nil and buffaction.target or nil
        if chair and chair:HasTag("limited_chair") then
            if chair:HasTag("rotatableobject") then
                inst.Transform:SetTwoFaced()
            end
        end
    end

    local _attack_deststate = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        if not inst.sg:HasStateTag("sneeze") then
            if inst:HasTag("ironlord") then
                return "ironlord_attack"
            end
            if not (inst.sg:HasStateTag("attack") and action and action.target == inst.sg.statemem.attacktarget or inst.replica.health:IsDead()) then
                local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equip then
                    if equip:HasTag("blunderbuss_loaded") then
                        return "blunderbuss"
                    elseif equip:HasTag("gun") then
                        return "shoot"
                    end
                end
            end
            return _attack_deststate and _attack_deststate(inst, action, ...)
        end
    end

    local _light_deststate = sg.actionhandlers[ACTIONS.LIGHT].deststate
    sg.actionhandlers[ACTIONS.LIGHT].deststate = function(inst, ...)
        local equipped = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equipped and equipped:HasTag("magnifying_glass") then
            return "investigate_start"
        else
            return _light_deststate(inst, ...)
        end
    end

    local _teach_deststatae = sg.actionhandlers[ACTIONS.TEACH].deststate
    sg.actionhandlers[ACTIONS.TEACH].deststate = function(inst, action, ...)
        if action and action.invobject and action.invobject:HasTag("treasuremap") then
            return "map"
        end
        return _teach_deststatae(inst, ...)
    end

    local _chop_deststate = sg.actionhandlers[ACTIONS.CHOP].deststate
    sg.actionhandlers[ACTIONS.CHOP].deststate = function(inst, action)
        if inst:HasTag("ironlord") then
            return "ironlord_work"
        else
            return _chop_deststate and _chop_deststate(inst, action)
        end
    end

    local _mine_deststate = sg.actionhandlers[ACTIONS.MINE].deststate
    sg.actionhandlers[ACTIONS.MINE].deststate = function(inst, action)
        if inst:HasTag("ironlord") then
            return "ironlord_work"
        else
            return _mine_deststate and _mine_deststate(inst, action)
        end
    end

    local _dig_deststate = sg.actionhandlers[ACTIONS.DIG].deststate
    sg.actionhandlers[ACTIONS.DIG].deststate = function(inst, action)
        if inst:HasTag("ironlord") then
            return "ironlord_work"
        else
            return _dig_deststate and _dig_deststate(inst, action)
        end
    end

    local _hammer_deststate = sg.actionhandlers[ACTIONS.HAMMER].deststate
    sg.actionhandlers[ACTIONS.HAMMER].deststate = function(inst, action)
        if inst:HasTag("ironlord") then
            return "ironlord_work"
        else
            return _hammer_deststate and _hammer_deststate(inst, action)
        end
    end
end)

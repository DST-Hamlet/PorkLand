require("stategraphs/commonstates")

local function getidleanim(inst)
    return (inst.components.aura.applying and "attack_loop")
        or (inst.is_defensive and math.random() < 0.1 and "idle_custom")
        or "idle"
end

local function startaura(inst)
    if inst.components.health:IsDead() then
        return
    end

    inst.Light:SetColour(255/255, 32/255, 32/255)
    inst.AnimState:SetMultColour(207/255, 92/255, 92/255, 1)

    inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/attack_LP", "angry")

    local attack_anim = "attack" .. tostring(inst.attack_level or 1)

    inst.attack_fx = SpawnPrefab("abigail_attack_fx")
    inst:AddChild(inst.attack_fx)
    inst.attack_fx.AnimState:PlayAnimation(attack_anim .. "_pre")
    inst.attack_fx.AnimState:PushAnimation(attack_anim .. "_loop", true)

    local skin_build = inst:GetSkinBuild()
    if skin_build then
        inst.attack_fx.AnimState:OverrideItemSkinSymbol("flower", skin_build, "flower", inst.GUID, "abigail_attack_fx")
    end
end

local function stopaura(inst)
    inst.Light:SetColour(180/255, 195/255, 225/255)
    inst.SoundEmitter:KillSound("angry")
    inst.AnimState:SetMultColour(1, 1, 1, 1)

    if inst.attack_fx then
        inst.attack_fx:kill_fx(inst.attack_level or 1)
        inst.attack_fx = nil
    end
end

---------------------------------------------------------------------------------------------------------------------------------------

local actionhandlers =
{
    ActionHandler(ACTIONS.HAUNT, "haunt_pre"),
}

local events =
{
    CommonHandlers.OnLocomote(true, true),
    EventHandler("startaura", startaura),
    EventHandler("stopaura", stopaura),
    EventHandler("attacked", function(inst)        
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("dissipate")) and not inst.sg:HasStateTag("nointerrupt") then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("dance", function(inst)
        if not (inst.sg:HasStateTag("dancing") or inst.sg:HasStateTag("busy") or
                inst.components.health:IsDead() or inst.sg:HasStateTag("dissipate")) then
            inst.sg:GoToState("dance")
        end
    end),
    EventHandler("start_playwithghost", function(inst, data)
        local target = data.target
        if target and target:IsValid() and not inst.sg:HasStateTag("playing")
                and (GetTime() - (inst.sg.mem.lastplaytime or 0)) > TUNING.ABIGAIL_PLAYFUL_DELAY then
            inst.sg.mem.queued_play_target = target
            target:PushEvent("ghostplaywithme", { target = inst })
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            if inst.sg.mem.queued_play_target then
                inst.sg.mem.lastplaytime = GetTime()
                inst.sg:GoToState("play", inst.sg.mem.queued_play_target)
                inst.sg.mem.queued_play_target = nil
            else
                local anim = getidleanim(inst)
                if anim ~= nil then
                    inst.AnimState:PlayAnimation(anim)
                end
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
            EventHandler("startaura", function(inst)
                inst.sg:GoToState("attack_start")
            end),
        },

    },

    State{
        name = "attack_start",
        tags = { "busy", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "appear",
        tags = { "busy", "noattack", "nointerrupt" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
			if inst.components.health then
		        inst.components.health:SetInvincible(true)
			end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.aura:Enable(true)
	        inst.components.health:SetInvincible(false)
			if inst._playerlink then
				inst._playerlink.components.ghostlybond:SummonComplete()
			end
        end,
    },

    State{
        name = "dance",
        tags = {"idle", "dancing"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PushAnimation("dance", true)
        end,
    },

    State{
        name = "hit",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "dissipate",
        tags = { "busy", "noattack", "nointerrupt", "dissipate", "nocommand" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("dissipate")

	        inst.components.health:SetInvincible(true)
			inst.components.aura:Enable(false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					if inst._playerlink and inst._playerlink.components.ghostlybond then
						inst.sg:GoToState("dissipated")
					else
						inst:Remove()
					end
                end
            end)
        },

		onexit = function(inst)
	        inst.components.health:SetInvincible(false)
            inst:BecomeDefensive()
            inst:FreezeMovements(false)
            inst._goto_position = nil
            inst:_OnHauntTargetRemoved()
            inst:_OnNextHauntTargetRemoved()
		end,
    },

    State{
        name = "dissipated",
        tags = { "busy", "noattack", "nointerrupt", "dissipate", "nocommand" },

        onenter = function(inst)
            inst.Physics:Stop()
			inst.components.aura:Enable(false)
			if inst._playerlink then
				inst._playerlink.components.ghostlybond:RecallComplete()
			end
			if inst.components.health:IsDead() then
				inst.components.health:SetCurrentHealth(1)
			end
        end,
    },

    State{
        name = "ghostlybond_levelup",
        tags = { "busy" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("flower_change")

			inst.sg.statemem.level = (data ~= nil and data.level) or nil
        end,

        timeline =
        {
			TimeEvent(14 * FRAMES, function(inst)
                local change_sound = (inst.sg.statemem.level == 3 and "dontstarve/characters/wendy/abigail/level_change/2")
                    or "dontstarve/characters/wendy/abigail/level_change/1"
                inst.SoundEmitter:PlaySound(change_sound)
            end),
			TimeEvent(15 * FRAMES, function(inst)
				local fx = SpawnPrefab("abigaillevelupfx")
				fx.entity:SetParent(inst.entity)

                local skin_build = inst:GetSkinBuild()
                if skin_build ~= nil then
                    fx.AnimState:OverrideItemSkinSymbol("flower", skin_build, "flower", inst.GUID, "abigail_attack_fx" )
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "walk_start",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            if inst.AnimState:AnimDone() or inst.AnimState:GetCurrentAnimationLength() == 0 then
                inst.sg:GoToState("walk")
            else
                inst.components.locomotor:WalkForward()
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State{
        name = "walk",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            local anim = getidleanim(inst)
            if anim then
                inst.AnimState:PlayAnimation(anim)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                if math.random() < 0.8 then
                    inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/howl")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("walk")
        end,
    },

    State{
        name = "walk_stop",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            if inst.AnimState:AnimDone() or inst.AnimState:GetCurrentAnimationLength() == 0 then
                inst.sg:GoToState("run")
            else
                inst.components.locomotor:RunForward()
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State{
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            local anim = getidleanim(inst)
            if anim then
                inst.AnimState:PlayAnimation(anim)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                if math.random() < 0.8 then
                    inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/howl")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "haunt_pre",
        tags = { "busy", "doing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dissipate")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt", nil, nil, true)
        end,

        timeline =
        {
            FrameEvent(15, function(inst)
                inst:PerformBufferedAction()
            end)
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("haunt")
            end),
        },
    },

    State {
        name = "haunt",
        tags = { "busy", "doing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("appear")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "play",
		tags = {"busy", "canrotate", "playful"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()

            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end

            inst.AnimState:PlayAnimation("dance")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end)
        },
    },
}

return StateGraph("abigail", states, events, "appear", actionhandlers)

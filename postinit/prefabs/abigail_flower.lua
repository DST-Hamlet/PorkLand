local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local ABIGAIL_COMMAND_DISTANCE = PLAYER_CAMERA_SEE_DISTANCE * 0.5

local function CanWendyTalk(inst)
    if (inst.components.health ~= nil and inst.components.health:IsDead() and inst.components.revivablecorpse == nil) or
        inst:HasTag("playerghost") or
        (inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep()) or
        (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) then

        return false
    end

    return true
end

local function ReticuleGhostMouseTargetFn(inst, pos)
    local doer_pos = inst:GetPosition()
    if inst:GetDistanceSqToPoint(pos) > ABIGAIL_COMMAND_DISTANCE * ABIGAIL_COMMAND_DISTANCE then
        return doer_pos + (pos - doer_pos):Normalize() * ABIGAIL_COMMAND_DISTANCE
    end
end

local function ReticuleGhostTargetFn(inst) -- 这是给手柄用的?
    return Vector3(ThePlayer.entity:LocalToWorldSpace(7, 0.001, 0))
end

local function StartAOETargeting(inst)
    if ThePlayer.components.playercontroller then
        ThePlayer.components.playercontroller:StartAOETargetingUsing(inst)
    end
end

-- Rile Up and Soothe actions
local function GhostChangeBehaviour(inst, doer)
    if not CanWendyTalk(doer) then
        return
    end

    local ghostlybond = doer.components.ghostlybond

	if ghostlybond == nil or ghostlybond.ghost == nil then
		return false
	end

    local pos = doer.components.ghostlybond.ghost and doer.components.ghostlybond.ghost:GetPosition() or nil
    if doer.WhisperTalk then
        local speech = ghostlybond.ghost.is_defensive and "ANNOUNCE_ABIGAIL_MAKE_AGGRESSIVE" or "ANNOUNCE_ABIGAIL_MAKE_DEFENSIVE"
        doer:WhisperTalk({speech = speech, text = GetString(doer, speech), pos = pos})
    end

	doer.components.ghostlybond:ChangeBehaviour()

	inst:PushEvent("spellupdateneeded", doer)

	return true
end

local function ToggleFreezeGhostMovements(inst, doer)
    if not CanWendyTalk(doer) then
        return
    end

    local ghostlybond = doer.components.ghostlybond

	if ghostlybond == nil or ghostlybond.ghost == nil then
		return false
	end

    local pos = doer.components.ghostlybond.ghost and doer.components.ghostlybond.ghost:GetPosition() or nil
    if doer.WhisperTalk then
        local speech = doer:HasTag("has_movements_frozen_follower") and "ANNOUNCE_ABIGAIL_MAKE_FOLLOW" or "ANNOUNCE_ABIGAIL_MAKE_STAY"
        doer:WhisperTalk({speech = speech, text = GetString(doer, speech), pos = pos})
    end

    doer.components.ghostlybond:FreezeMovements(not doer:HasTag("has_movements_frozen_follower"))
	doer.refreshflowertooltip:push()
	inst:PushEvent("spellupdateneeded", doer)
	return true
end

local function DoGhostSpell(doer, event, state, data, speech, ...)
    if not CanWendyTalk(doer) then
        return
    end

    local pos = nil
    if data.position then
        pos = data.position
    elseif data.target then
        pos = data.target:GetPosition()
    end
    if doer:GetDistanceSqToPoint(pos) > ABIGAIL_COMMAND_DISTANCE * ABIGAIL_COMMAND_DISTANCE then
        return
    end

    if doer.WhisperTalk then
        doer:WhisperTalk({speech = speech, text = GetString(doer, speech), pos = pos})
    end

	-- local spellbookcooldowns = doer.components.spellbookcooldowns
	local ghostlybond = doer.components.ghostlybond

	-- if spellbookcooldowns and (spellbookcooldowns:IsInCooldown("ghostcommand") or spellbookcooldowns:IsInCooldown(event or state)) then
    --     return false
	-- end

	if ghostlybond == nil or ghostlybond.ghost == nil then
		return false
	end

	if ghostlybond.ghost.components.health:IsDead() then
		return false
	end

	if event then
		ghostlybond.ghost:PushEvent(event, data, ...)

	elseif state then
		ghostlybond.ghost.sg:GoToState(state, data, ...)
	end

	-- if spellbookcooldowns then
	-- 	spellbookcooldowns:RestartSpellCooldown("ghostcommand", TUNING.WENDYSKILL_COMMAND_COOLDOWN)
	-- end

	return true
end

-- local function GhostEscapeSpell(inst, doer)
-- 	return DoGhostSpell(doer, "do_ghost_escape")
-- end

-- local function GhostAttackAtSpell(inst, doer, pos)
-- 	return DoGhostSpell(doer, "do_ghost_attackat", nil, pos)
-- end

-- local function GhostScareSpell(inst, doer)
-- 	return DoGhostSpell(doer, nil, "scare")
-- end

-- local function GhostHauntSpell(inst, doer, pos)
--     return DoGhostSpell(doer, "do_ghost_hauntat", nil, pos)
-- end

local function GhostHauntSpellCommand(inst, doer, position, target)
    return DoGhostSpell(doer, "do_ghost_haunt_target", nil, {target = target}, "ANNOUNCE_ABIGAIL_HAUNT")
end

local function GhostGotoSpellCommand(inst, doer, position)
    return DoGhostSpell(doer, "do_ghost_goto_position", nil, {position = position}, "ANNOUNCE_ABIGAIL_GOTO")
end

local function LeftClickPicker(inst, target, position)
    local actions = {}
    if target and target ~= inst then
        target:CollectActions("SCENE", inst, actions, false)
    end
    for _, action in ipairs(actions) do
        if action == ACTIONS.HAUNT then
            local distance = ABIGAIL_COMMAND_DISTANCE
            if inst:GetDistanceSqToInst(target) > distance * distance then
                return
            end
            
            local spellbook = inst.HUD:GetCurrentOpenSpellBook()
            return { BufferedAction(inst, target, ACTIONS.SPELL_COMMAND, spellbook, nil, nil, distance) }
        end
    end
end

-- local function RightClickPicker(inst, target, position)
--     return {}
-- end

local function AlwaysTrue()
    return true
end

local ATLAS = "images/hud/abigail_flower_commands.xml"
local SCALE = 0.9

local COMMANDS = {
	{
        id = "unsummon",
		label = STRINGS.SPELLCOMMAND.TALK_TO_ABIGAIL.UNSUMMON,
		on_execute_on_server = function(inst, doer)
            -- Done with action
		end,
		on_execute_on_client = function(inst)
            ThePlayer.components.playercontroller:CastSpellCommand(inst, "unsummon")
		end,
        action = function(inst, doer, position, target)
            return BufferedAction(doer, nil, ACTIONS.CASTUNSUMMON, inst)
        end,
        widget_scale = SCALE,
		atlas = ATLAS,
		normal = "unsummon.tex",
	},
    {
        id = "toggle_aggressive",
        label = function(inst)
           return ThePlayer:HasTag("has_aggressive_follower") and STRINGS.SPELLCOMMAND.TALK_TO_ABIGAIL.MAKE_DEFENSIVE or STRINGS.SPELLCOMMAND.TALK_TO_ABIGAIL.MAKE_AGGRESSIVE
        end,
        on_execute_on_server = GhostChangeBehaviour,
        on_execute_on_client = function(inst)
            ThePlayer.components.playercontroller:CastSpellCommand(inst, "toggle_aggressive")
        end,
        widget_scale = SCALE,
		atlas = ATLAS,
		normal = function(inst)
           return ThePlayer:HasTag("has_aggressive_follower") and "smoothe.tex" or "rileup.tex"
        end,
    },
    {
        id = "toggle_freeze_movements",
        label = function(inst)
           return ThePlayer:HasTag("has_movements_frozen_follower") and STRINGS.SPELLCOMMAND.TALK_TO_ABIGAIL.MAKE_FOLLOW or STRINGS.SPELLCOMMAND.TALK_TO_ABIGAIL.MAKE_STAY
        end,
        on_execute_on_server = ToggleFreezeGhostMovements,
        on_execute_on_client = function(inst)
            ThePlayer.components.playercontroller:CastSpellCommand(inst, "toggle_freeze_movements")
        end,
        widget_scale = SCALE,
		atlas = ATLAS,
		normal = function(inst)
           return ThePlayer:HasTag("has_movements_frozen_follower") and "resume.tex" or "freeze.tex"
        end,
    },
	-- {
	-- 	label = STRINGS.GHOSTCOMMANDS.ESCAPE,
	-- 	onselect = function(inst)
	-- 		local spellbook = inst.components.spellbook
	-- 		spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.ESCAPE)

	-- 		if TheWorld.ismastersim then
	-- 			inst.components.aoespell:SetSpellFn(nil)
    --             spellbook:SetSpellFn(GhostEscapeSpell)
	-- 		end
	-- 	end,
	-- 	execute = function(inst)
	-- 		if ThePlayer.replica.inventory then
	-- 			ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
	-- 		end
	-- 	end,
	-- 	bank = "spell_icons_wendy",
	-- 	build = "spell_icons_wendy",
	-- 	anims =
	-- 	{
	-- 		idle = { anim = "teleport" },
	-- 		focus = { anim = "teleport_focus", loop = true },
	-- 		down = { anim = "teleport_pressed" },
	-- 		disabled = { anim = "teleport_disabled" },
	-- 		cooldown = { anim = "teleport_cooldown" },
	-- 	},
	-- 	widget_scale = ICON_SCALE,
	-- 	checkcooldown = function(doer)
	-- 		--client safe
	-- 		return (doer ~= nil
	-- 			and doer.components.spellbookcooldowns
	-- 			and doer.components.spellbookcooldowns:GetSpellCooldownPercent("ghostcommand"))
	-- 			or nil
	-- 	end,
	-- 	cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
	-- },
    -- {
    --     label = STRINGS.GHOSTCOMMANDS.ATTACK_AT,
    --     onselect = function(inst)
	-- 		local spellbook = inst.components.spellbook
	-- 		local aoetargeting = inst.components.aoetargeting

    --         spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.ATTACK_AT)
    --         aoetargeting:SetDeployRadius(0)
	-- 		aoetargeting:SetRange(20)
    --         aoetargeting.reticule.reticuleprefab = "reticuleaoeghosttarget"
    --         aoetargeting.reticule.pingprefab = "reticuleaoeghosttarget_ping"

    --         aoetargeting.reticule.mousetargetfn = nil
    --         aoetargeting.reticule.targetfn = ReticuleGhostTargetFn
    --         aoetargeting.reticule.updatepositionfn = nil
	-- 		aoetargeting.reticule.twinstickrange = 15

    --         if TheWorld.ismastersim then
    --             aoetargeting:SetTargetFX("reticuleaoeghosttarget")
    --             inst.components.aoespell:SetSpellFn(GhostAttackAtSpell)
    --             spellbook:SetSpellFn(nil)
    --         end
    --     end,
    --     execute = StartAOETargeting,
	-- 	bank = "spell_icons_wendy",
	-- 	build = "spell_icons_wendy",
	-- 	anims =
	-- 	{
	-- 		idle = { anim = "attack_at" },
	-- 		focus = { anim = "attack_at_focus", loop = true },
	-- 		down = { anim = "attack_at_pressed" },
	-- 		disabled = { anim = "attack_at_disabled" },
	-- 		cooldown = { anim = "attack_at_cooldown" },
	-- 	},
    --     widget_scale = ICON_SCALE,
	-- 	checkcooldown = function(doer)
	-- 		--client safe
	-- 		if doer == nil or doer.components.spellbookcooldowns == nil then
	-- 			return
	-- 		end

	-- 		local cooldown = math.max(doer.components.spellbookcooldowns:GetSpellCooldownPercent("do_ghost_attackat") or 0, doer.components.spellbookcooldowns:GetSpellCooldownPercent("ghostcommand") or 0)

	-- 		return cooldown > 0 and cooldown or nil
	-- 	end,
	-- 	cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    -- },
    -- {
    --     label = STRINGS.GHOSTCOMMANDS.SCARE,
    --     onselect = function(inst)
    --         local spellbook = inst.components.spellbook
    --         spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.SCARE)

    --         if TheWorld.ismastersim then
    --             inst.components.aoespell:SetSpellFn(nil)
    --             spellbook:SetSpellFn(GhostScareSpell)
    --         end
    --     end,
    --     execute = function(inst)
    --         if ThePlayer.replica.inventory then
    --             ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
    --         end
    --     end,
    --     bank = "spell_icons_wendy",
    --     build = "spell_icons_wendy",
    --     anims =
    --     {
    --         idle = { anim = "scare" },
    --         focus = { anim = "scare_focus", loop = true },
    --         down = { anim = "scare_pressed" },
    --         disabled = { anim = "scare_disabled" },
    --         cooldown = { anim = "scare_cooldown" },
    --     },
    --     widget_scale = ICON_SCALE,
    --     checkcooldown = function(doer)
    --         --client safe
    --         return (doer ~= nil
    --             and doer.components.spellbookcooldowns
    --             and doer.components.spellbookcooldowns:GetSpellCooldownPercent("ghostcommand"))
    --             or nil
    --     end,
    --     cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    -- },
    {
        id = "haunt_at",
        label = STRINGS.SPELLCOMMAND.TALK_TO_ABIGAIL.HAUNT,
        on_execute_on_server = GhostHauntSpellCommand,
        on_execute_on_client = function(inst)
            inst.components.spellcommand:SetSelectedCommand("haunt_at")
            ThePlayer.components.playercontroller:StartCastingActionOverrideSpell(inst, LeftClickPicker)
        end,
        widget_scale = SCALE,
		atlas = ATLAS,
		normal = "haunt.tex",
        -- checkcooldown = function(doer)
        --     --client safe
        --     return (doer ~= nil
        --         and doer.components.spellbookcooldowns
        --         and doer.components.spellbookcooldowns:GetSpellCooldownPercent("ghostcommand"))
        --         or nil
        -- end,
        -- cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
    },
    {
        id = "goto",
        label = STRINGS.SPELLCOMMAND.TALK_TO_ABIGAIL.GOTO,
        on_execute_on_server = function(inst, doer, position)
            -- TODO: See if we still want this
            inst.components.aoetargeting:SetTargetFX("reticuleaoeghosttarget")
            local fx = inst.components.aoetargeting:SpawnTargetFXAt(position)
            if fx then
                -- This is normally done in SG to align with the animations,
                -- but since we don't want it to have animations right now,
                -- we remove it after a fixed time
                fx:DoTaskInTime(15* FRAMES, function(inst)
                    if inst.KillFX then
                        inst:KillFX()
                    else
                        inst:Remove()
                    end
                end)
            end

            GhostGotoSpellCommand(inst, doer, position)
        end,
        on_execute_on_client = function(inst)
            inst.components.spellcommand:SetSelectedCommand("goto")

			local aoetargeting = inst.components.aoetargeting
            aoetargeting:SetAllowWater(true)
            aoetargeting:SetDeployRadius(0)
			aoetargeting:SetRange(40)
			aoetargeting:SetShouldRepeatCastFn(AlwaysTrue)
            
            aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
            aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
            aoetargeting.reticule.reticuleprefab = "reticuleaoeghosttarget"
            aoetargeting.reticule.pingprefab = "reticuleaoeghosttarget_ping"
            aoetargeting.reticule.mousetargetfn = ReticuleGhostMouseTargetFn
            aoetargeting.reticule.targetfn = ReticuleGhostTargetFn
            aoetargeting.reticule.updatepositionfn = nil
			aoetargeting.reticule.twinstickrange = 15

            StartAOETargeting(inst)
        end,
        widget_scale = SCALE,
		atlas = ATLAS,
		normal = "goto.tex",
    },
}

AddPrefabPostInit("abigail_flower", function(inst)
    inst:AddComponent("spellcommand")
    inst.components.spellcommand:SetSpellCommands(COMMANDS)
    inst.components.spellcommand.ui_background = {
        bank = "ui_abigail_command_5x1",
        build = "ui_abigail_command_5x1",
    }
end)

AddPrefabRegisterPostInit("abigail_flower", function(abigail_flower)
    ToolUtil.SetUpvalue(abigail_flower.fn, "updatespells", function(inst, owner)
        if not owner then
            return
        end
        if owner:HasTag("ghostfriend_summoned") then
            if owner.HUD and owner.HUD.controls.spellcontrols:IsOpen() then
                owner.HUD.controls.spellcontrols:RefreshItemStates()
            end
        else
            if owner.HUD and owner.HUD.controls.spellcontrols:IsOpen() then
                owner.HUD.controls.spellcontrols:Close()
            end
        end
    end)
end)

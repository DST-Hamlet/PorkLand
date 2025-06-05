local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function ReticuleGhostTargetFn(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(7, 0.001, 0))
end

local function StartAOETargeting(inst)
    if ThePlayer.components.playercontroller then
        ThePlayer.components.playercontroller:StartAOETargetingUsing(inst)
    end
end

-- Rile Up and Soothe actions
local function GhostChangeBehaviour(inst, doer)
	doer.components.ghostlybond:ChangeBehaviour()

	inst:PushEvent("spellupdateneeded", doer)

	return true
end

local function FreezeGhostMovements(inst, doer)
    doer.components.ghostlybond:FreezeMovements(true)
	doer.refreshflowertooltip:push()
	inst:PushEvent("spellupdateneeded", doer)
	return true
end

local function ResumeGhostMovements(inst, doer)
    doer.components.ghostlybond:FreezeMovements(false)
	doer.refreshflowertooltip:push()
	inst:PushEvent("spellupdateneeded", doer)
	return true
end

local function DoGhostSpell(doer, event, state, ...)
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
		ghostlybond.ghost:PushEvent(event, ...)

	elseif state then
		ghostlybond.ghost.sg:GoToState(state, ...)
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

local function GhostHauntSpellCommand(inst, buffered_action)
    local doer = buffered_action.doer
    return DoGhostSpell(doer, "do_ghost_haunt_target", nil, buffered_action.target)
end

local function GhostGotoSpellCommand(inst, doer, pos)
    return DoGhostSpell(doer, "do_ghost_goto_position", nil, pos)
end

local function GhostUnsummonSpell(inst, doer)
	inst:RemoveTag("unsummoning_spell")

	local doer_ghostlybond = doer.components.ghostlybond
	if not doer_ghostlybond then
		return false
	else
		doer_ghostlybond:Recall(false)
		return true
	end
end

local function LeftClickPicker(inst, target, position)
    local actions = {}
    if target and target ~= inst then
        target:CollectActions("SCENE", inst, actions, false)
    end
    for _, action in ipairs(actions) do
        if action == ACTIONS.HAUNT then
            local distance = 40
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
local SCALE = {0.9, 0.9, 0.9}

local COMMANDS = {
	{
        id = "unsummon",
		label = STRINGS.GHOSTCOMMANDS.UNSUMMON,
		onselect = function(inst)
			local spellbook = inst.components.spellbook
			spellbook:SetSpellName(STRINGS.GHOSTCOMMANDS.UNSUMMON)

			inst:AddTag("unsummoning_spell")
			if TheWorld.ismastersim then
				inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(GhostUnsummonSpell)
			end
		end,
		execute = function(inst)
			if ThePlayer.replica.inventory then
				ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
			end
		end,
		atlas = ATLAS,
        scale = SCALE,
		normal = "unsummon.tex",
	},
    {
        id = "make_aggressive",
        label = STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_AGGRESSIVE,
        onselect = function(inst)
            local spellbook = inst.components.spellbook
            spellbook:SetSpellName(STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_AGGRESSIVE)

            if TheWorld.ismastersim then
                inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(GhostChangeBehaviour)
            end
        end,
        execute = function(inst)
            if ThePlayer.replica.inventory then
                ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
            end
        end,
        should_show = function(inst)
            return not ThePlayer:HasTag("has_aggressive_follower")
        end,
		atlas = ATLAS,
        scale = SCALE,
		normal = "rileup.tex",
    },
    {
        id = "make_defensive",
        label = STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_DEFENSIVE,
        onselect = function(inst)
            local spellbook = inst.components.spellbook
            spellbook:SetSpellName(STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_DEFENSIVE)

            if TheWorld.ismastersim then
                inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(GhostChangeBehaviour)
            end
        end,
        execute = function(inst)
            if ThePlayer.replica.inventory then
                ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
            end
        end,
        should_show = function(inst)
            return ThePlayer:HasTag("has_aggressive_follower")
        end,
		atlas = ATLAS,
        scale = SCALE,
		normal = "smoothe.tex",
    },
    {
        id = "freeze_movements",
        label = "Freeze Movements",
        onselect = function(inst)
            local spellbook = inst.components.spellbook
            spellbook:SetSpellName("Freeze Movements")

            if TheWorld.ismastersim then
                inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(FreezeGhostMovements)
            end
        end,
        execute = function(inst)
            if ThePlayer.replica.inventory then
                ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
            end
        end,
        should_show = function(inst)
            return not ThePlayer:HasTag("has_movements_frozen_follower")
        end,
		atlas = ATLAS,
        scale = SCALE,
		normal = "freeze.tex",
    },
    {
        id = "resume_movements",
        label = "Resume Movements",
        onselect = function(inst)
            local spellbook = inst.components.spellbook
            spellbook:SetSpellName("Resume Movements")

            if TheWorld.ismastersim then
                inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(ResumeGhostMovements)
            end
        end,
        execute = function(inst)
            if ThePlayer.replica.inventory then
                ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
            end
        end,
        should_show = function(inst)
            return ThePlayer:HasTag("has_movements_frozen_follower")
        end,
		atlas = ATLAS,
        scale = SCALE,
		normal = "resume.tex",
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
        label = STRINGS.GHOSTCOMMANDS.HAUNT_AT,
        onselect = function(inst)
            inst.components.spellcommand:SetSpell(STRINGS.GHOSTCOMMANDS.HAUNT_AT, GhostHauntSpellCommand)
        end,
        execute = function(inst)
            if ThePlayer then
                ThePlayer.components.playercontroller:StartCastingActionOverrideSpell(inst, LeftClickPicker)
            end
        end,
		atlas = ATLAS,
        scale = SCALE,
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
        label = "Goto",
        onselect = function(inst)
			local spellbook = inst.components.spellbook
			local aoetargeting = inst.components.aoetargeting

            spellbook:SetSpellName("Goto")
            inst.components.spellcommand:SetSpellName("Goto")
            inst.components.spellcommand:SetSelectedSpell("goto")

            aoetargeting:SetDeployRadius(0)
			aoetargeting:SetRange(20)
			aoetargeting:SetShouldRepeatCastFn(AlwaysTrue)
            -- aoetargeting.reticule.reticuleprefab = "reticuleaoeghosttarget"
            aoetargeting.reticule.pingprefab = "reticuleaoeghosttarget_ping"

            aoetargeting.reticule.mousetargetfn = nil
            aoetargeting.reticule.targetfn = ReticuleGhostTargetFn
            aoetargeting.reticule.updatepositionfn = nil
			aoetargeting.reticule.twinstickrange = 15

            if TheWorld.ismastersim then
                aoetargeting:SetTargetFX("reticuleaoeghosttarget")
                inst.components.aoespell:SetSpellFn(GhostGotoSpellCommand)
                spellbook:SetSpellFn(nil)
            end
        end,
        execute = StartAOETargeting,
		atlas = ATLAS,
        scale = SCALE,
		normal = "goto.tex",
    },
}

AddPrefabPostInit("abigail_flower", function(inst)
    inst.components.spellbook:SetItems(COMMANDS)
    inst.components.spellbook.background = {
        bank = "ui_abigail_command_5x1",
        build = "ui_abigail_command_5x1",
    }

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("spellcommand")
end)

AddPrefabRegisterPostInit("abigail_flower", function(abigail_flower)
    ToolUtil.SetUpvalue(abigail_flower.fn, "updatespells", function(inst, owner)
        if not owner then
            return
        end
        if owner:HasTag("ghostfriend_summoned") then
            inst.components.spellbook:SetItems(COMMANDS)
            if owner.HUD and owner.HUD.controls.spellcontrols:IsOpen() then
                owner.HUD.controls.spellcontrols:Open(inst.components.spellbook.items, inst.components.spellbook.background)
            end
        else
            if owner.HUD and owner.HUD.controls.spellcontrols:IsOpen() then
                owner.HUD.controls.spellcontrols:Close()
            end
        end
    end)
end)

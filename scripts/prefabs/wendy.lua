local MakePlayerCharacter = require("prefabs/player_common")
local WendyFlowerOver = require("widgets/wendyflowerover")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/wendy.fsb"),

	Asset("ANIM", "anim/wendy_channel.zip"),
	Asset("ANIM", "anim/wendy_mount_channel.zip"),
	Asset("ANIM", "anim/wendy_recall.zip"),
	Asset("ANIM", "anim/wendy_mount_recall.zip"),
	Asset("ANIM", "anim/player_wendy_commune.zip"),
	Asset("ANIM", "anim/player_wendy_mount_commune.zip"),
	Asset("ANIM", "anim/wendy_flower_over.zip"),
	Asset("ANIM", "anim/wendy_elixir.zip"),
    Asset("ANIM", "anim/player_idles_wendy.zip"),
    Asset("ANIM", "anim/wendy_elixer_mounted.zip"),
    Asset("ANIM", "anim/wendy_resurrect.zip"),

    Asset("SCRIPT", "scripts/prefabs/skilltree_wendy.lua"),
}

local prefabs =
{
    "abigail",
    "lavaarena_abigail",

	"abigailsummonfx",
	"abigailsummonfx_mount",
	"abigailunsummonfx",
	"abigailunsummonfx_mount",

	"wendy_sanityaura_buff_on_fx",
	"wendy_sanityaura_buff_off_fx",
	"abigail_gravestone_rebirth_fx",
	"wendy_gravestone_rebirth_fx",
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WENDY
end

prefabs = FlattenTree({ prefabs, start_inv }, true)

local function OnBondLevelDirty(inst)
	if inst.HUD ~= nil then
		local bond_level = inst._bondlevel:value()
		for i = 0, 3 do
			if i ~= 1 then
				inst:SetClientSideInventoryImageOverrideFlag("bondlevel"..i, i == bond_level)
			end
		end
		if not inst:HasTag("playerghost") then
			if bond_level > 1 then
				if inst.HUD.wendyflowerover ~= nil then
					inst.HUD.wendyflowerover:Play( bond_level )
				end
			end
		end
    end
end

local function OnPlayerDeactivated(inst)
    inst:RemoveEventCallback("onremove", OnPlayerDeactivated)
    if not TheWorld.ismastersim then
        inst:RemoveEventCallback("_bondleveldirty", OnBondLevelDirty)
    end
end

local function OnClientPetSkinChanged(inst)
	if inst.HUD ~= nil and inst.HUD.wendyflowerover ~= nil then
		local skinname = TheInventory:LookupSkinname( inst.components.pethealthbar._petskin:value() )
		inst.HUD.wendyflowerover:SetSkin( skinname )
	end
end

local function OnPlayerActivated(inst)
	if inst == ThePlayer then
		if inst.HUD.wendyflowerover == nil and inst.components.pethealthbar ~= nil then
			inst.HUD.wendyflowerover = inst.HUD.overlayroot:AddChild(WendyFlowerOver(inst))
			inst.HUD.wendyflowerover:MoveToBack()
			OnClientPetSkinChanged( inst )
		end
		inst:ListenForEvent("onremove", OnPlayerDeactivated)
		if not TheWorld.ismastersim then
			inst:ListenForEvent("_bondleveldirty", OnBondLevelDirty)
		end
		OnBondLevelDirty(inst)
	end
end

local function RefreshFlowerTooltip(inst)
	if inst == ThePlayer then
		inst:PushEvent("inventoryitem_updatespecifictooltip", {prefab = "abigail_flower"})
	end
end


local function common_postinit(inst)
	inst:AddTag("ghostlyfriend")
	inst:AddTag("elixirbrewer")

    inst:AddComponent("pethealthbar")

	inst.AnimState:AddOverrideBuild("wendy_channel")
	inst.AnimState:AddOverrideBuild("player_idles_wendy")

	inst._bondlevel = net_tinybyte(inst.GUID, "wendy._bondlevel", "_bondleveldirty")
	inst.refreshflowertooltip = net_event(inst.GUID, "refreshflowertooltip")
	inst:ListenForEvent("playeractivated", OnPlayerActivated)
	inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)

	inst:ListenForEvent("clientpetskindirty", OnClientPetSkinChanged)

	inst:ListenForEvent("refreshflowertooltip", RefreshFlowerTooltip)
end

local function OnDespawn(inst)
	local abigail = inst.components.ghostlybond.ghost
	if abigail ~= nil and abigail.sg ~= nil and not abigail.inlimbo then
		if not abigail.sg:HasStateTag("dissipate") then
			abigail.sg:GoToState("dissipate")
		end
		abigail:DoTaskInTime(25 * FRAMES, abigail.Remove)
	end
end

local function OnReroll(inst)
	-- This is its own function in case OnDespawn above changes that requires workarounds for seamlessswap to not interfere.
    OnDespawn(inst)
end

local function ondeath(inst)
	inst.components.ghostlybond:Recall()
	inst.components.ghostlybond:PauseBonding()
end

local function onresurrection(inst)
	inst.components.ghostlybond:SetBondLevel(1)
	inst.components.ghostlybond:ResumeBonding()
end

local function ghostlybond_onlevelchange(inst, ghost, level, prev_level, isloading)
	inst._bondlevel:set(level)

	if not isloading and inst.components.talker ~= nil and level > 1 then
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_GHOSTLYBOND_LEVELUP", "LEVEL"..tostring(level)))
		OnBondLevelDirty(inst)
	end
end

local function ghostlybond_onsummon(inst, ghost)
	if inst.components.sanity ~= nil and inst.migration == nil then
		inst.components.sanity:DoDelta(TUNING.SANITY_MED)
	end
end

local function ghostlybond_onrecall(inst, ghost, was_killed)
	if inst.migration == nil then
		if inst.components.sanity ~= nil then
			inst.components.sanity:DoDelta(was_killed and (-TUNING.SANITY_MED * 2) or -TUNING.SANITY_MED)
		end

		if inst.components.talker ~= nil then
			inst.components.talker:Say(GetString(inst, was_killed and "ANNOUNCE_ABIGAIL_DEATH" or "ANNOUNCE_ABIGAIL_RETRIEVE"))
		end
	end

	inst.components.ghostlybond.ghost.sg:GoToState("dissipate")
end

local function ghostlybond_onsummoncomplete(inst, ghost)
	inst.refreshflowertooltip:push()
end

local function ghostlybond_changebehaviour(inst, ghost)
	-- todo: toggle abigail between defensive and offensive
    if ghost.is_defensive then
        ghost:BecomeAggressive()
    else
        ghost:BecomeDefensive()
    end
	inst.refreshflowertooltip:push()

	return true
end

local function WhisperTalk(inst, data)
	if data == nil then
		return
	end

	if inst.lastwhisper and inst.lastwhisper == data.speech 
		and inst.lastwhispertime and (GetTime() - inst.lastwhispertime) < 1 then

	else
		inst:PushEvent("talk_whisper", {pos = data.pos})
		inst.components.talker:Say(data.text)

		inst.lastwhisper = data.speech
		inst.lastwhispertime = GetTime()
	end
end

-------------------------------------------------------------------------------
local function OnSave(inst, data)
    if inst.questghost ~= nil then
        data.questghost = inst.questghost:GetSaveRecord()
    end
end

local function OnLoad(inst, data)
	if not data then return end

	if data.abigail ~= nil then -- retrofitting
		inst.components.inventory:GiveItem(SpawnPrefab("abigail_flower"))
	end

	if data.questghost ~= nil and inst.questghost == nil then
		local questghost = SpawnSaveRecord(data.questghost)
		if questghost ~= nil then
			if inst.migrationpets ~= nil then
				table.insert(inst.migrationpets, questghost)
			end
			questghost.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
			questghost:LinkToPlayer(inst)
		end
	end
end

--------------------------------------------------------------------------------
local function master_postinit(inst)
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

    inst.customidleanim = "idle_wendy"

    inst.components.health:SetMaxHealth(TUNING.WENDY_HEALTH)
    inst.components.hunger:SetMax(TUNING.WENDY_HUNGER)
    inst.components.sanity:SetMax(TUNING.WENDY_SANITY)

    inst.components.sanity.night_drain_mult = TUNING.WENDY_SANITY_MULT
    inst.components.sanity.neg_aura_mult = TUNING.WENDY_SANITY_MULT
    inst.components.sanity:AddSanityAuraImmunity("ghost")
    inst.components.sanity:SetPlayerGhostImmunity(true)

	-- For colour fading in Wendy's gravestone revive animation.
	inst:AddComponent("fader")

	inst:AddComponent("ghostlybond")
	inst.components.ghostlybond.maxbondlevel = 1
	inst.components.ghostlybond.onbondlevelchangefn = ghostlybond_onlevelchange
	inst.components.ghostlybond.onsummonfn = ghostlybond_onsummon
	inst.components.ghostlybond.onrecallfn = ghostlybond_onrecall
	inst.components.ghostlybond.onsummoncompletefn = ghostlybond_onsummoncomplete
	inst.components.ghostlybond.changebehaviourfn = ghostlybond_changebehaviour

	inst.components.ghostlybond:Init("abigail", TUNING.ABIGAIL_BOND_LEVELUP_TIME)

	inst:ListenForEvent("death", ondeath)
	inst:ListenForEvent("ms_becameghost", ondeath)
	inst:ListenForEvent("ms_respawnedfromghost", onresurrection)

    inst.components.combat.damagemultiplier = TUNING.WENDY_DAMAGE_MULT

	inst.WhisperTalk = WhisperTalk

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnDespawn = OnDespawn
	inst:ListenForEvent("ms_playerreroll", OnReroll)
end

return MakePlayerCharacter("wendy", prefabs, assets, common_postinit, master_postinit)

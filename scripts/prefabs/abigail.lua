local SpDamageUtil = require("components/spdamageutil")

local assets =
{
    Asset("ANIM", "anim/player_ghost_withhat.zip"),
    Asset("ANIM", "anim/ghost_abigail_build.zip"),

    Asset("ANIM", "anim/ghost_abigail.zip"),
    Asset("ANIM", "anim/ghost_abigail_gestalt.zip"),

    Asset("ANIM", "anim/lunarthrall_plant_front.zip"),
    Asset("ANIM", "anim/brightmare_gestalt_evolved.zip"),
    Asset("ANIM", "anim/ghost_abigail_commands.zip"),
    Asset("ANIM", "anim/ghost_abigail_gestalt_build.zip"),
    Asset("ANIM", "anim/ghost_abigail_shadow_build.zip"),
    Asset("ANIM", "anim/ghost_abigail_resurrect.zip"),
    Asset("ANIM", "anim/ghost_wendy_resurrect.zip"),

    Asset("ANIM", "anim/ghost_abigail_human.zip"),

    Asset("SOUND", "sound/ghost.fsb"),
}

local prefabs =
{
    "abigail_attack_fx",
    "abigail_attack_fx_ground",
	"abigail_retaliation",
	"abigaillevelupfx",
    "abigail_attack_shadow_fx",
    "abigail_gestalt_hit_fx",
    "abigail_rising_twinkles_fx",
}

local brain = require("brains/abigailbrain")

local function SetMaxHealth(inst)
    local health = inst.components.health
    if health then
        if health:IsDead() then
            health.maxhealth = inst.base_max_health
        else
            local health_percent = health:GetPercent()
            health:SetMaxHealth(inst.base_max_health)
            health:SetPercent(health_percent, true)
        end

        if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil then
            inst._playerlink.components.pethealthbar:SetMaxHealth(health.maxhealth)
        end
    end
end

local function UpdateGhostlyBondLevel(inst, level)
	local max_health = level == 3 and TUNING.ABIGAIL_HEALTH_LEVEL3
					or level == 2 and TUNING.ABIGAIL_HEALTH_LEVEL2
					or TUNING.ABIGAIL_HEALTH_LEVEL1

    inst.base_max_health = max_health

	SetMaxHealth(inst)

	local light_vals = TUNING.ABIGAIL_LIGHTING[level] or TUNING.ABIGAIL_LIGHTING[1]
	if light_vals.r ~= 0 then
		inst.Light:Enable(not inst.inlimbo)
		inst.Light:SetRadius(light_vals.r)
		inst.Light:SetIntensity(light_vals.i)
		inst.Light:SetFalloff(light_vals.f)
	else
		inst.Light:Enable(false)
	end
    inst.AnimState:SetLightOverride(light_vals.l)
end

local ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ = TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW * TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
local function IsWithinDefensiveRange(inst)
    local range = ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ
    return (inst._playerlink ~= nil) and inst:GetDistanceSqToInst(inst._playerlink) < range
end

local function SetTransparentPhysics(inst, on)
	if on then
		inst.Physics:SetCollisionMask(TheWorld:CanFlyingCrossBarriers() and COLLISION.GROUND or COLLISION.WORLD)
	else
		inst.Physics:SetCollisionMask(
			TheWorld:CanFlyingCrossBarriers() and COLLISION.GROUND or COLLISION.WORLD,
			COLLISION.CHARACTERS,
			COLLISION.GIANTS
		)
	end
end

local COMBAT_MUSHAVE_TAGS = { "_combat", "_health" }
local COMBAT_CANTHAVE_TAGS = { "INLIMBO", "noauradamage", "companion" }

local COMBAT_MUSTONEOF_TAGS_AGGRESSIVE = { "monster", "prey", "insect", "hostile", "character", "animal" }
local COMBAT_MUSTONEOF_TAGS_DEFENSIVE = { "monster", "prey" }

local COMBAT_TARGET_DSQ = TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE * TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE

local function HasFriendlyLeader(inst, target, PVP_enabled)
    local leader = (inst.components.follower ~= nil and inst.components.follower.leader) or nil
    if not leader then
        return false
    end

    local target_leader = (target.components.follower ~= nil) and target.components.follower.leader or nil

    if target_leader and target_leader.components.inventoryitem then
        target_leader = target_leader.components.inventoryitem:GetGrandOwner()
        -- Don't attack followers if their follow object has no owner
        if not target_leader then
            return true
        end
    end

    if PVP_enabled == nil then
        PVP_enabled = TheNet:GetPVPEnabled()
    end

    return leader == target
        or (
            target_leader ~= nil
            and (
                target_leader == leader or (not PVP_enabled and target_leader.isplayer)
            )
        ) or (
            not PVP_enabled
            and target.components.domesticatable ~= nil
            and target.components.domesticatable:IsDomesticated()
        ) or (
            not PVP_enabled
            and target.components.saltlicker ~= nil
            and target.components.saltlicker.salted
        )
end

local function CommonRetarget(inst, v)
    return v ~= inst and v ~= inst._playerlink and v.entity:IsVisible()
            and v:GetDistanceSqToInst(inst._playerlink) < COMBAT_TARGET_DSQ
            and inst.components.combat:CanTarget(v)
            and v.components.minigame_participator == nil
            and not HasFriendlyLeader(inst, v)
end

local function DefensiveRetarget(inst)
    if not inst._playerlink or not IsWithinDefensiveRange(inst) then
        return nil
    else
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        local entities_near_me = TheSim:FindEntities(
            ix, iy, iz, TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW,
            COMBAT_MUSHAVE_TAGS, COMBAT_CANTHAVE_TAGS, COMBAT_MUSTONEOF_TAGS_DEFENSIVE
        )
        local should_force_retarget = inst:HasTag("movements_frozen")

        for _, v in ipairs(entities_near_me) do
            if CommonRetarget(inst, v)
                    and (v.components.combat.target == inst._playerlink or
                        inst._playerlink.components.combat.target == v or
                        v.components.combat.target == inst) then

                return v, should_force_retarget
            end
        end

        return nil
    end
end

local function AggressiveRetarget(inst)
    if inst._playerlink == nil then
        return nil
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local entities_near_me = TheSim:FindEntities(
        ix, iy, iz, TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE,
        COMBAT_MUSHAVE_TAGS, COMBAT_CANTHAVE_TAGS, COMBAT_MUSTONEOF_TAGS_AGGRESSIVE
    )
    local should_force_retarget = inst:HasTag("movements_frozen")

    for _, entity_near_me in ipairs(entities_near_me) do
        if CommonRetarget(inst, entity_near_me) then
            return entity_near_me, should_force_retarget
        end
    end

    return nil
end

local function OnAttacked(inst, data)
    local combat = inst.components.combat
    if data.attacker == nil then
        combat:SetTarget(nil)
    elseif not data.attacker:HasTag("noauradamage") then
        if not combat:IsValidTarget(combat.target) then
            if not inst.is_defensive then
                combat:SetTarget(data.attacker)
            elseif inst:IsWithinDefensiveRange() and inst._playerlink:GetDistanceSqToInst(data.attacker) < ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ then
                -- Basically, we avoid targetting the attacker if they're far enough away that we wouldn't reach them anyway.
                combat:SetTarget(data.attacker)
            end
        end
    end
end

local function OnBlocked(inst, data)
    if data ~= nil and inst._playerlink ~= nil and data.attacker == inst._playerlink then
		if inst.components.health ~= nil and not inst.components.health:IsDead() then
			inst._playerlink.components.ghostlybond:Recall()
		end
	end
end

local function OnDeath(inst)
    inst.components.aura:Enable(false)
end

local function OnRemoved(inst)
    inst:BecomeDefensive()
end

local function auratest(inst, target, can_initiate)
    if target == inst._playerlink then
        return false
    end

	if target.components.minigame_participator ~= nil then
		return false
	end

    if (target:HasTag("player") and not TheNet:GetPVPEnabled()) or target:HasTag("ghost") or target:HasTag("noauradamage") then
        return false
    end

    local leader = inst.components.follower.leader
    if leader ~= nil
        and (leader == target
            or (target.components.follower ~= nil and
                target.components.follower.leader == leader)) then
        return false
    end

    if inst.is_defensive and not can_initiate and not IsWithinDefensiveRange(inst) then
        return false
    end

    if inst.components.combat.target == target then
        return true
    end

    if target.components.combat.target ~= nil
        and (target.components.combat.target == inst or
            target.components.combat.target == leader) then
        return true
    end

    local ismonster = target:HasTag("monster")
    if ismonster and not TheNet:GetPVPEnabled() and
       ((target.components.follower and target.components.follower.leader ~= nil and
         target.components.follower.leader:HasTag("player")) or target.bedazzled) then
        return false
    end

    return not target:HasTag("companion") and
        (can_initiate or ismonster or target:HasTag("prey"))
end

local function UpdateDamage(inst)
	local phase = TheWorld.state.phase
    local position = inst:GetPosition()
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
    if center ~= nil then
        local is_house = FindEntity(center, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"safelight"}, {"INLIMBO"}) ~= nil
        if is_house then
            phase = "dusk"
        else
            phase = "night"
        end
    end
    local modified_damage = (TUNING.ABIGAIL_DAMAGE[phase] or TUNING.ABIGAIL_DAMAGE.day)
	inst.components.combat.defaultdamage = modified_damage

    inst.attack_level = (phase == "day" and 1)
						or (phase == "dusk" and 2)
						or 3

    -- If the animation fx was already playing we update its animation
    local level_str = tostring(inst.attack_level)
    if inst.attack_fx and not inst.attack_fx.AnimState:IsCurrentAnimation("attack" .. level_str .. "_loop") then
        inst.attack_fx.AnimState:PlayAnimation("attack" .. level_str .. "_loop", true)
    end
end

local function AbigailHealthDelta(inst, data)
    if not inst._playerlink then return end

    if data.oldpercent > data.newpercent and data.newpercent <= 0.25 and not inst.issued_health_warning then
        inst._playerlink.components.talker:Say(GetString(inst._playerlink, "ANNOUNCE_ABIGAIL_LOW_HEALTH"))
        inst.issued_health_warning = true
    elseif data.oldpercent < data.newpercent and data.newpercent > 0.33 then
        inst.issued_health_warning = false
    end
end

local function DoAppear(sg)
	sg:GoToState("appear")
end

local function AbleToAcceptTest(inst, item)
    return false, (item:HasTag("reviver") and "ABIGAILHEART") or nil
end

local function on_ghostlybond_level_change(inst, player, data)
	if not inst.inlimbo and data.level > 1 and not inst.sg:HasStateTag("busy") and (inst.components.health == nil or not inst.components.health:IsDead()) then
		inst.sg:GoToState("ghostlybond_levelup", {level = data.level})
	end

	UpdateGhostlyBondLevel(inst, data.level)
end

local function BecomeAggressive(inst)
    inst.AnimState:OverrideSymbol("ghost_eyes", "ghost_abigail_build", "angry_ghost_eyes")
    inst.is_defensive = false
    inst._playerlink:AddTag("has_aggressive_follower")
    inst.components.combat:SetRetargetFunction(3 * FRAMES, AggressiveRetarget)
end

local function BecomeDefensive(inst)
    inst.AnimState:ClearOverrideSymbol("ghost_eyes")
    inst.is_defensive = true
	if inst._playerlink ~= nil then
	    inst._playerlink:RemoveTag("has_aggressive_follower")
	end
    inst.components.combat:SetRetargetFunction(3 * FRAMES, DefensiveRetarget)
end

local function onlostplayerlink(inst)
	inst._playerlink = nil
end

local function linktoplayer(inst, player)
    inst.persists = false
    inst._playerlink = player

    BecomeDefensive(inst)
    inst:FreezeMovements(false)

    inst:ListenForEvent("healthdelta", AbigailHealthDelta)

    player.components.leader:AddFollower(inst)
    if player.components.pethealthbar ~= nil then
        player.components.pethealthbar:SetPet(inst, "", TUNING.ABIGAIL_HEALTH_LEVEL1)
    end

    UpdateGhostlyBondLevel(inst, player.components.ghostlybond.bondlevel)
    inst:ListenForEvent("ghostlybond_level_change", inst._on_ghostlybond_level_change, player)
    inst:ListenForEvent("onremove", inst._onlostplayerlink, player)
end

local function OnExitLimbo(inst)
	local level = (inst._playerlink ~= nil and inst._playerlink.components.ghostlybond ~= nil) and inst._playerlink.components.ghostlybond.bondlevel or 1
	local light_vals = TUNING.ABIGAIL_LIGHTING[level] or TUNING.ABIGAIL_LIGHTING[1]
	inst.Light:Enable(light_vals.r ~= 0)
end

--
local function getstatus(inst)
	local bondlevel = (inst._playerlink ~= nil and inst._playerlink.components.ghostlybond ~= nil) and inst._playerlink.components.ghostlybond.bondlevel or 0
	return bondlevel == 3 and "LEVEL3"
		or bondlevel == 2 and "LEVEL2"
		or "LEVEL1"
end

local function OnSave(inst, data)

end

local function OnLoad(inst, data)

end

-- 云霄国度的新内容
local function FreezeMovements(inst, should_freeze)
    inst._playerlink:AddOrRemoveTag("has_movements_frozen_follower", should_freeze)
    inst:AddOrRemoveTag("movements_frozen", should_freeze)
end

local function OnGotoCommand(inst, data)
    local position = data.position
    if position == nil then
        return
    end
    inst._goto_position = position
    inst:_OnHauntTargetRemoved()
    inst:_OnNextHauntTargetRemoved()
end

local HAUNT_CANT_TAGS = {"catchable", "DECOR", "FX", "haunted", "INLIMBO", "NOCLICK"}
local function DoGhostHauntTarget(inst, data)
    local target = data.target
    if target == nil then
        return
    end
    if (inst.sg and inst.sg:HasStateTag("nocommand"))
            or (inst.components.health and inst.components.health:IsDead()) then
        return
    end

    for _, cant_tag in pairs(HAUNT_CANT_TAGS) do
        if target:HasTag(cant_tag) then
            return
        end
    end

    inst._next_haunt_target = target
    inst._goto_position = nil
    inst:ListenForEvent("onremove", inst._OnNextHauntTargetRemoved, inst._next_haunt_target)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ghost")
    inst.AnimState:SetBuild("ghost_abigail_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim_bloom_ghost.ksh")

    inst.AnimState:AddOverrideBuild("ghost_abigail_gestalt")
    inst.AnimState:AddOverrideBuild("ghost_abigail_human")

    inst:AddTag("abigail")
    inst:AddTag("character")
    inst:AddTag("flying")
    inst:AddTag("ghost")
    inst:AddTag("girl")
    inst:AddTag("noauradamage")
    inst:AddTag("NOBLOCK")
    inst:AddTag("notraptrigger")
    inst:AddTag("scarytoprey")

    inst:AddTag("trader") --trader (from trader component) added to pristine state for optimization

    MakeGhostPhysics(inst, 1, .5)

    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.6)
    inst.Light:Enable(false)
    inst.Light:SetColour(180 / 255, 195 / 255, 225 / 255)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    --
    inst.scrapbook_damage = { TUNING.ABIGAIL_DAMAGE.day, TUNING.ABIGAIL_DAMAGE.night }
    inst.scrapbook_ignoreplayerdamagemod = true

    inst.is_defensive = true
    inst.issued_health_warning = false
    --inst._playerlink = nil

    --inst._haunt_target = nil
    inst._OnHauntTargetRemoved = function()
        if inst._haunt_target then
            inst:RemoveEventCallback("onremove", inst._OnHauntTargetRemoved, inst._haunt_target)
            inst._haunt_target = nil
        end
    end

    inst._OnNextHauntTargetRemoved = function()
        if inst._next_haunt_target then
            inst:RemoveEventCallback("onremove", inst._OnNextHauntTargetRemoved, inst._next_haunt_target)
            inst._next_haunt_target = nil
        end
    end

    inst._SetNewHauntTarget = function()
        inst:_OnHauntTargetRemoved()
        if inst._next_haunt_target and inst._next_haunt_target:IsValid() then
            inst._haunt_target = inst._next_haunt_target
            inst:ListenForEvent("onremove", inst._OnHauntTargetRemoved, inst._haunt_target)
        end
        inst:_OnNextHauntTargetRemoved()
    end

    --
    inst.auratest = auratest
    inst.BecomeDefensive = BecomeDefensive
    inst.BecomeAggressive = BecomeAggressive
    inst.IsWithinDefensiveRange = IsWithinDefensiveRange
    inst.LinkToPlayer = linktoplayer
    inst.SetTransparentPhysics = SetTransparentPhysics
    inst.FreezeMovements = FreezeMovements
    inst.OnGotoCommand = OnGotoCommand

    --
    local aura = inst:AddComponent("aura")
    aura.radius = 4
    aura.tickperiod = 3 * FRAMES
    aura.attack_period = 1
    aura.ignoreallies = true
    aura.auratestfn = auratest

    --
    local combat = inst:AddComponent("combat")
    combat.playerdamagepercent = TUNING.ABIGAIL_DMG_PLAYER_PERCENT
    combat:SetKeepTargetFunction(auratest)

    --
    local debuffable = inst:AddComponent("debuffable")

    --
    local follower = inst:AddComponent("follower")
    follower:KeepLeaderOnAttacked()
    follower.keepdeadleader = true
    follower.keepleaderduringminigame = true

    --
    inst.base_max_health = TUNING.ABIGAIL_HEALTH_LEVEL1

    local health = inst:AddComponent("health")
    health:SetMaxHealth(TUNING.ABIGAIL_HEALTH_LEVEL1)
    inst.components.health:SetCurrentHealth(1)
    health:StartRegen(1, 1)
    health.nofadeout = true
    health.save_maxhealth = true

    --
    local inspectable = inst:AddComponent("inspectable")
    inspectable.getstatus = getstatus

    --
    local locomotor = inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    locomotor.walkspeed = TUNING.ABIGAIL_SPEED*.5
    locomotor.runspeed = TUNING.ABIGAIL_SPEED
    locomotor.pathcaps = { allowocean = true, ignorecreep = true }
    locomotor:SetTriggersCreep(false)

    --
    inst:AddComponent("timer")

    -- Added so you can attempt to give hearts to trigger flavour text when the action fails
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
    --
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("blocked", OnBlocked)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("onremove", OnRemoved)
	inst:ListenForEvent("exitlimbo", OnExitLimbo)
    inst:ListenForEvent("do_ghost_haunt_target", DoGhostHauntTarget)
    inst:ListenForEvent("do_ghost_goto_position", OnGotoCommand)

    --
    inst:WatchWorldState("phase", UpdateDamage)
	inst.UpdateDamage = UpdateDamage
    inst:DoPeriodicTask(1, inst.UpdateDamage, 0)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGabigail")
    inst.sg.OnStart = DoAppear

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    --
	inst._on_ghostlybond_level_change = function(player, data) on_ghostlybond_level_change(inst, player, data) end
	inst._onlostplayerlink = function(player) onlostplayerlink(inst, player) end

    --
    return inst
end

-------------------------------------------------------------------------------

return Prefab("abigail", fn, assets, prefabs)

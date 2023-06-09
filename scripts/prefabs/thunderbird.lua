require "brains/thunderbirdbrain"
require "stategraphs/SGthunderbird"

local assets=
{
	--Asset("ANIM", "anim/perd_basic.zip"),
	Asset("ANIM", "anim/thunderbird.zip"),
    Asset("ANIM", "anim/thunderbird_fx.zip"),
	Asset("SOUND", "sound/perd.fsb"),
}

local prefabs =
{
    "drumstick",
    "feather_thunder",
    "thunderbird_fx",
}

local loot =
{
    "drumstick",
    "drumstick",
    "feather_thunder"
}

local _lightningexcludetags = { "thunderbird", "INLIMBO", "lightningblocker", "player" }
local LIGHTNINGSTRIKE_CANT_TAGS = { "playerghost", "INLIMBO" }
local LIGHTNINGSTRIKE_ONEOF_TAGS = { "lightningrod", "lightningtarget", "lightningblocker" }
local LIGHTNINGSTRIKE_SEARCH_RANGE = 40

local OnSendLightningStrike = function(pos)
    local closest_generic = nil
    local closest_rod = nil
    local closest_blocker = nil

    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, LIGHTNINGSTRIKE_SEARCH_RANGE, nil, LIGHTNINGSTRIKE_CANT_TAGS, LIGHTNINGSTRIKE_ONEOF_TAGS)
    local blockers = nil
    for _, v in pairs(ents) do
        -- Track any blockers we find, since we redirect the strike position later,
        -- and might redirect it into their block range.
        local is_blocker = v.components.lightningblocker ~= nil
        if is_blocker then
            if blockers == nil then
                blockers = {v}
            else
                table.insert(blockers, v)
            end
        end

        if closest_blocker == nil and is_blocker
                and (v.components.lightningblocker.block_rsq + 0.0001) > v:GetDistanceSqToPoint(pos:Get()) then
            closest_blocker = v
        elseif closest_rod == nil and v:HasTag("lightningrod") then
            closest_rod = v
        elseif closest_generic == nil then
            if (v.components.health == nil or not v.components.health:IsInvincible())
                    and not is_blocker -- If we're out of range of the first branch, ignore blocker objects.
                    and (v.components.playerlightningtarget == nil or math.random() <= v.components.playerlightningtarget:GetHitChance()) then
                closest_generic = v
            end
        end
    end

    local strike_position = pos
    local prefab_type = "lightning"

    if closest_blocker ~= nil then
        closest_blocker.components.lightningblocker:DoLightningStrike(strike_position)
        prefab_type = "thunder"
    elseif closest_rod ~= nil then
        strike_position = closest_rod:GetPosition()

        -- Check if we just redirected into a lightning blocker's range.
        if blockers ~= nil then
            for _, blocker in ipairs(blockers) do
                if blocker:GetDistanceSqToPoint(strike_position:Get()) < (blocker.components.lightningblocker.block_rsq + 0.0001) then
                    prefab_type = "thunder"
                    blocker.components.lightningblocker:DoLightningStrike(strike_position)
                    break
                end
            end
        end

        -- If we didn't get blocked, push the event that does all the fx and behaviour.
        if prefab_type == "lightning" then
            closest_rod:PushEvent("lightningstrike")
        end
    else
        if closest_generic ~= nil then
            strike_position = closest_generic:GetPosition()

            -- Check if we just redirected into a lightning blocker's range.
            if blockers ~= nil then
                for _, blocker in ipairs(blockers) do
                    if blocker:GetDistanceSqToPoint(strike_position:Get()) < (blocker.components.lightningblocker.block_rsq + 0.0001) then
                        prefab_type = "thunder"
                        blocker.components.lightningblocker:DoLightningStrike(strike_position)
                        break
                    end
                end
            end

            -- If we didn't redirect, strike the playerlightningtarget if there is one.
            if prefab_type == "lightning" then
                if closest_generic.components.playerlightningtarget ~= nil then
                    closest_generic.components.playerlightningtarget:DoStrike()
                end
            end
        end

        -- If we're doing lightning, light nearby unprotected objects on fire.
        if prefab_type == "lightning" then
            ents = TheSim:FindEntities(strike_position.x, strike_position.y, strike_position.z, 3, nil, _lightningexcludetags)
            for _, v in pairs(ents) do
                if v.components.burnable ~= nil then
                    v.components.burnable:Ignite()
                end
            end
        end
        if prefab_type == "lightning" then
            ents = TheSim:FindEntities(strike_position.x, strike_position.y, strike_position.z, 3, {"plantkin"}, {"playerghost" ,"INLIMBO"})
            for _, v in pairs(ents) do
                if v.components.burnable ~= nil then
                    v.components.burnable:Ignite()
                end
            end
        end
    end

    SpawnPrefab(prefab_type).Transform:SetPosition(strike_position:Get())
end

local function DoLightning(inst, target)
    local LIGHTNING_COUNT = 3
    local COOLDOWN = 60

    if TheWorld.state.isaporkalypse then
        LIGHTNING_COUNT = 10
    end

    for i=1, LIGHTNING_COUNT do
        inst:DoTaskInTime(0.4*i, function ()
            local rad = math.random(4, 8)
            local angle = i*((4*PI)/LIGHTNING_COUNT)
            local pos = Vector3(target.Transform:GetWorldPosition()) + Vector3(rad*math.cos(angle), 0, rad*math.sin(angle))
            OnSendLightningStrike(pos)
        end)
    end

    inst.cooling_down = true
    inst:DoTaskInTime(COOLDOWN, function () inst.cooling_down = false end)
end

local function spawnfx(inst)
    if not inst.fx then
        inst.fx = inst:SpawnChild("thunderbird_fx")
        --local x,y,z = inst.Transform:GetWorldPosition()
        inst.fx.Transform:SetPosition(0,0,0)

      --  self.inst:AddChild(inst.fx)
     --   local follower = inst.fx.entity:AddFollower()
      --  follower:FollowSymbol(inst.GUID, inst.components.combat.hiteffectsymbol, 0, 0, 0 )
       -- inst.fx:FacePoint(inst.Transform:GetWorldPosition())
   end
end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	shadow:SetSize( 1.5, .75 )
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 50, .5)

    local light = inst.entity:AddLight()
    light:SetFalloff(.7)
    light:SetIntensity(.75)
    light:SetRadius(2.5)
    light:SetColour(120/255, 120/255, 120/255)
    light:Enable(true)

    anim:SetBank("thunderbird")
    anim:SetBuild("thunderbird")
    anim:Hide("hat")

    inst:AddTag("character")
    inst:AddTag("berrythief")
    inst:AddTag("thunderbird")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakePoisonableCharacter(inst)

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.THUNDERBIRD_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.THUNDERBIRD_WALK_SPEED

    inst:SetStateGraph("SGthunderbird")

    local brain = require "brains/thunderbirdbrain"
    inst:SetBrain(brain)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.RAW, FOODTYPE.VEGGIE }, { FOODTYPE.RAW })

    inst:AddComponent("sleeper")
    inst.components.sleeper.onlysleepsfromitems = true

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.PERD_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.PERD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PERD_ATTACK_PERIOD)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")

    inst.special_action = function (act)
        inst.sg:GoToState("thunder_attack")
    end

    inst:DoTaskInTime(0.1, function() spawnfx(inst) end)

    inst.DoLightning = DoLightning
    MakeMediumFreezableCharacter(inst, "body")
    MakeMediumBurnableCharacter(inst, "body")

    inst.components.burnable.lightningimmune = true

    return inst
end

local function fx_fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")

    anim:SetBank("thunderbird_fx")
    anim:SetBuild("thunderbird_fx")
    anim:SetSortOrder(2)


    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(math.random()*1,function()
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 0.5)
        local ok = false
        for i, ent in ipairs(ents)do

            if ent.prefab == "thunderbird" then
                ok = true
            end
            if ent.prefab == "thunderbird_fx" and ent ~= inst then
                --print("REMOVING")
                ent:Remove()
            end
        end

    end)
    return inst
end

return Prefab( "forest/animals/thunderbird", fn, assets, prefabs),
       Prefab( "forest/animals/thunderbird_fx", fx_fn, assets, prefabs)

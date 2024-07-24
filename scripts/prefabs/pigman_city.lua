local assets = {
    Asset("ANIM", "anim/pig_usher.zip"),
    Asset("ANIM", "anim/pig_mayor.zip"),
    Asset("ANIM", "anim/pig_miner.zip"),
    Asset("ANIM", "anim/pig_queen.zip"),
    Asset("ANIM", "anim/pig_farmer.zip"),
    Asset("ANIM", "anim/pig_hunter.zip"),
    Asset("ANIM", "anim/pig_banker.zip"),
    Asset("ANIM", "anim/pig_florist.zip"),
    Asset("ANIM", "anim/pig_erudite.zip"),
    Asset("ANIM", "anim/pig_hatmaker.zip"),
    Asset("ANIM", "anim/pig_mechanic.zip"),
    Asset("ANIM", "anim/pig_professor.zip"),
    Asset("ANIM", "anim/pig_collector.zip"),
    Asset("ANIM", "anim/townspig_basic.zip"),
    Asset("ANIM", "anim/pig_beautician.zip"),
    Asset("ANIM", "anim/pig_royalguard.zip"),
    Asset("ANIM", "anim/pig_storeowner.zip"),
    Asset("ANIM", "anim/townspig_attacks.zip"),
    Asset("ANIM", "anim/townspig_actions.zip"),
    Asset("ANIM", "anim/pig_royalguard_2.zip"),
    Asset("ANIM", "anim/townspig_shop_wip.zip"),
}

local prefabs = {
    "meat",
    "poop",
    "tophat",
    "pigskin",
    "halberd",
    "strawhat",
    "monstermeat",
    "pigcrownhat",
    "pig_scepter",
    "pigman_shopkeeper_desk",
    "pedestal_key",
    "firecrackers",
}

local MALE = "MALE"
local FEMALE = "FEMALE"

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function getSpeechType(inst, speech)
    local line = speech.DEFAULT

    if inst.talkertype and speech[inst.talkertype] then
        line = speech[inst.talkertype]
    end

    if type(line) == "table" then
        line = line[math.random(#line)]
    end

    return line
end

local function spawndesk(inst, spawndesk)
    if spawndesk then
        local desklocation = inst:GetPosition()

        inst.desk = SpawnPrefab("pigman_shopkeeper_desk")
        inst.desk.Transform:SetPosition(desklocation.x, desklocation.y, desklocation.z)
        inst:AddComponent("homeseeker")
        inst.components.homeseeker:SetHome(inst.desk)
    else
        if inst.desk then
            inst.components.homeseeker:SetHome()
            inst.desk:Remove()
            inst.desk = nil
        end
    end
end

local function separatedesk(inst, separatedesk)
    if separatedesk then
        inst:RemoveTag("atdesk")
        inst.AnimState:Hide("desk")
        spawndesk(inst, true)
        ChangeToCharacterPhysics(inst)
        inst.Physics:SetMass(50)
    else
        ChangeToObstaclePhysics(inst)
        if inst.desk then
            local x, y, z = inst.desk.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x, y, z)
        end
        spawndesk(inst, false)
        inst:AddTag("atdesk")
        inst.AnimState:Show("desk")
    end
end

local function sayline(inst, line, mood)
    inst.components.talker:Say(line, 1.5, nil, true, mood)
end

local function ontalk(inst, script, mood)
    -- TODO: Make alarmed mood work
    if inst:HasTag("guard") then
        if mood and mood == "alarmed" then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/guard_alert")
        else
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/conversational_talk_gaurd", "talk")
        end
    else
        if inst.female then
            if mood and mood == "alarmed" then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/scream_female")
            else
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/conversational_talk_female", "talk")
            end
        else
            if mood and mood == "alarmed" then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/scream")
            else
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/conversational_talk", "talk")
            end
        end
    end
end

local function GetStatus(inst)
    if inst:HasTag("guard") then
        return "GUARD"
    elseif inst.components.follower.leader then
        return "FOLLOWER"
    end
end

local function CalcSanityAura(inst, observer)
    if inst.components.follower and inst.components.follower.leader == observer then
        return TUNING.SANITYAURA_SMALL
    end

    return 0
end

local function ShouldAcceptItem(inst, item)
    if inst.components.sleeper:IsAsleep() then
        return false
    end

    if item.prefab == "oinc" or item.prefab == "oinc10" or item.prefab == "oinc100" then
        return true
    end

    if inst.components.eater:CanEat(item) then
        if (item.components.edible.foodtype == FOODTYPE.MEAT or item.components.edible.foodtype == FOODTYPE.HORRIBLE)
            and inst.components.follower.leader and inst.components.follower:GetLoyaltyPercent() > 0.9 then

            return false
        end

        if (item.components.edible.foodtype == FOODTYPE.VEGGIE or item.components.edible.foodtype == FOODTYPE.RAW) then

            local econ = TheWorld.components.economy
            local econprefab = inst.econprefab or inst.prefab
            local wanteditems = econ:GetTradeItems(econprefab)
            local wantitem = false
            for i, wanted in ipairs(wanteditems or {}) do
                if wanted == item.prefab then
                    wantitem = true
                    break
                end
            end

            local last_eat_time = inst.components.eater:TimeSinceLastEating()
            if not wantitem and last_eat_time and last_eat_time < TUNING.PIG_MIN_POOP_PERIOD then
                return false
            end

            if inst.components.inventory:Has(item.prefab, 1) then
                return false
            end
        end
    end

    if not inst:HasTag("guard") then
        local city = inst:HasTag("city2") and 2 or 1

        local econ = TheWorld.components.economy
        local econprefab = inst.econprefab or inst.prefab
        local wanteditems = econ:GetTradeItems(econprefab)
        local desc = econ:GetTradeItemDesc(econprefab)
        -- local wantednum =   econ:GetNumberWanted(econprefab,city)

        local wantitem = false
        for i, wanted in ipairs(wanteditems) do
            if wanted == item.prefab then
                wantitem = true
                break
            end
        end

        if item.prefab == "purplegem" and (inst.prefab == "pigman_banker" or inst.prefab == "pigman_banker_shopkeep") then
            inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_REFUSE_PURPLEGEM))
            return false
        end

        if (item.prefab == "trinket_giftshop_1" or item.prefab == "trinket_giftshop_3")
            and inst:HasTag("city1")
            and not inst:HasTag("recieved_trinket") then

            wantitem = true
        end

        if (item.prefab == "relic_4" or item.prefab == "relic_5") and not inst:HasTag("pigqueen") then
            wantitem = false
        end

        if wantitem then
            if item.prefab == "trinket_giftshop_1" or item.prefab == "trinket_giftshop_3" then
                return true
            end

            local delay = econ:GetDelay(econprefab, city, inst)
            if delay > 0 then
                if delay == 1 then
                    inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_REFUSE_GIFT_DELAY_TOMORROW))
                else
                    inst.sayline(inst, string.format(getSpeechType(inst, STRINGS.CITY_PIG_TALK_REFUSE_GIFT_DELAY), tostring(delay)))
                end
                return false
            else
                return true
            end
        else
            if item:HasTag("relic") then
                if item.prefab == "relic_4" or item.prefab == "relic_5" then
                    inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_REFUSE_PRICELESS_GIFT))
                else
                    inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_RELIC_GIFT))
                end
            else
                if item.prefab == "trinket_giftshop_1" or item.prefab == "trinket_giftshop_3" and inst:HasTag("city1") then
                    inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_REFUSE_TRINKET_GIFT))
                else
                    -- HUGO
                    inst.sayline(inst, string.format(getSpeechType(inst, STRINGS.CITY_PIG_TALK_REFUSE_GIFT), desc))
                end
            end
            return false
        end
    end

    return false
end

local function OnGetItemFromPlayer(inst, giver, item)

    if not inst:HasTag("guard") then -- or inst:HasTag("pigqueen")

        local city = 1
        if inst:HasTag("city2") then
            city = 2
        end

        -- I wear hats (but should they? the art doesn't show)
        if inst:HasTag("pigqueen") and item.components.equippable then
            local behappy = false
            if item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
                local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if current then
                    inst.components.inventory:DropItem(current)
                end

                inst.components.inventory:Equip(item)
                inst.AnimState:Show("hat")
                behappy = true
            end

            if item.components.equippable.equipslot == EQUIPSLOTS.HANDS and item.prefab == "pig_scepter" then
                inst.components.inventory:Equip(item)
                behappy = true
            end

            if item.prefab == "relic_4" or item.prefab == "relic_5" then
                behappy = true
            end
            if behappy then
                inst:PushEvent("behappy")
            end
        end

        local econ = TheWorld.components.economy
        local econprefab = inst.econprefab or inst.prefab
        local wanteditems = econ:GetTradeItems(econprefab)
        local desc =        econ:GetTradeItemDesc(econprefab)
        --local wantednum =   econ:GetNumberWanted(econprefab,city)

        local wantitem = false
        local trinket = false
        for i, wanted in ipairs(wanteditems) do
            if wanted == item.prefab then
                wantitem = true
                break
            end
        end

        if item.prefab == "trinket_giftshop_1" or item.prefab == "trinket_giftshop_3" and inst:HasTag("city1") then
            wantitem = true
            trinket = true
        end

        if wantitem then

            if trinket then
                if giver.components.inventory then
                    inst:AddTag("recieved_trinket")
                    inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_GIVE_TRINKET_REWARD))

                    local reward = {
                        "kabobs",
                        "pumpkincookie",
                        "taffy",
                        "oinc",
                        "butterflymuffin",
                        "powcake",
                    }
                    local rewarditem = SpawnPrefab(reward[math.random(1, #reward)])
                    giver.components.inventory:GiveItem(rewarditem, nil, inst:GetPosition())
                    return true
                end
            end

            local reward, qty = econ:MakeTrade(econprefab, city, inst)
            if item.prefab ~= "pig_scepter" and item.prefab ~= "pigcrownhat" then
                item:Remove()
            end
            if reward then
                if giver.components.inventory then
                    inst.sayline(inst, string.format(getSpeechType(inst, STRINGS.CITY_PIG_TALK_GIVE_REWARD), tostring(1), desc))
                    -- inst.components.talker:Say( string.format(getSpeechType(inst,STRINGS.CITY_PIG_TALK_GIVE_REWARD), tostring(1), desc ))--econ:GetNumberWanted(econprefab,city) ), desc ) )

                    for i = 1, qty do
                        local rewarditem = SpawnPrefab(reward)
                        giver.components.inventory:GiveItem(rewarditem, nil, inst:GetPosition())
                    end
                end
            else
                inst.sayline(inst,
                    string.format(getSpeechType(inst, STRINGS.CITY_PIG_TALK_TAKE_GIFT), tostring(1), desc))
                -- inst.components.talker:Say( string.format(getSpeechType(inst,STRINGS.CITY_PIG_TALK_TAKE_GIFT), tostring(1), desc ))--econ:GetNumberWanted(econprefab,city) ), desc ) )
            end
        end
        if item:HasTag("relic") and (inst.prefab == "pigman_collector_shopkeep" or inst.prefab == "pigman_collector") then
            if giver.components.inventory then
                inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_GIVE_RELIC_REWARD))
                -- inst.components.talker:Say( getSpeechType(inst,STRINGS.CITY_PIG_TALK_GIVE_RELIC_REWARD) )
                local rewarditem = SpawnPrefab("oinc10")
                giver.components.inventory:GiveItem(rewarditem, nil, inst:GetPosition())
            end
        end
    end

    if inst:HasTag("guard") and item:HasTag("securitycontract") then
        inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
        giver.components.leader:AddFollower(inst)
        inst.components.follower:AddLoyaltyTime(TUNING.PIG_LOYALTY_MAXTIME)
        item:Remove()
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function OnEat(inst, food)
    if food.components.edible and food.components.edible.foodtype == FOODTYPE.MEAT and inst.components.werebeast and
        not inst.components.werebeast:IsInWereState() then
        if food.components.edible:GetHealth() < 0 then
            inst.components.werebeast:TriggerDelta(1)
        end
    end

    if food.components.edible and (food.components.edible.foodtype == FOODTYPE.VEGGIE) then -- or food.components.edible.foodtype == FOODTYPE.SEEDS) then
        local poop = SpawnPrefab("poop")
        poop.Transform:SetPosition(inst.Transform:GetWorldPosition())

        poop.cityID = inst.components.citypossession.cityID
        TheWorld.components.periodicpoopmanager:OnPoop(poop.cityID, poop)
    end
end

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude)
        return dude:HasTag("pig") and not dude:HasTag("werepig") and not dude:HasTag("guard")
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = nil
    if TheWorld.state.isspring then
        ents = TheSim:FindEntities(x, y, z, (SHARE_TARGET_DIST * TUNING.SPRING_COMBAT_MOD) / 2)
    else
        ents = TheSim:FindEntities(x, y, z, SHARE_TARGET_DIST / 2)
    end

    if ents then
        local num_helpers = 0
        for k, v in pairs(ents) do
            if v ~= inst and v.components.combat and not (v.components.health and v.components.health:IsDead()) and
                fn(v) then
                if v:PushEvent("suggest_tree_target", {
                    tree = attacker,
                }) then
                    num_helpers = num_helpers + 1
                end
            end
            if num_helpers >= MAX_TARGET_SHARES then
                break
            end
        end
    end
end

local function call_guards(inst, attacker)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, {"guard_entrance"})
    if #ents > 0 then
        local guardprefab = "pigman_royalguard"
        local cityID = 1
        if inst:HasTag("city2") then
            guardprefab = "pigman_royalguard_2"
            cityID = 2
        end
        local spawnpt = Vector3(ents[math.random(#ents)].Transform:GetWorldPosition())
        local guard = SpawnPrefab(guardprefab)
        guard.components.citypossession:SetCity(cityID)
        guard.Transform:SetPosition(spawnpt.x, spawnpt.y, spawnpt.z)
        guard:PushEvent("attacked", {
            attacker = attacker,
            damage = 0,
            weapon = nil,
        })
        if attacker then
            attacker:AddTag("wanted_by_guards")
        end

        -- TODO: Get this working
        -- local interior = TheWorld.components.interiorspawner:getPropInterior(inst)
        -- if interior then
        --     TheWorld.components.interiorspawner:injectprefab(guard, interior)
        -- end
    end
end

local function spawn_guard_tasks(inst, attacker)
    if not inst.task_guard1 then
        inst.task_guard1 = inst:DoTaskInTime(math.random(1) + 1, function()
            call_guards(inst, attacker)
            inst.task_guard1:Cancel()
            inst.task_guard1 = nil
        end)
    end
    if not inst.task_guard1 then
        inst.task_guard2 = inst:DoTaskInTime(math.random(1) + 1.5, function()
            call_guards(inst, attacker)
            inst.task_guard2:Cancel()
            inst.task_guard2 = nil
        end)
    end
end

local function OnAttacked(inst, data)
    local attacker = data.attacker
    if attacker then
        inst:ClearBufferedAction()

        if attacker.prefab == "deciduous_root" and attacker.owner then
            OnAttackedByDecidRoot(inst, attacker.owner)
        elseif attacker.prefab ~= "deciduous_root" then
            inst.components.combat:SetTarget(attacker)

            if inst:HasTag("guard") then
                if attacker:HasTag("player") then
                    inst:AddTag("angry_at_player")
                end
                inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude)
                    return dude:HasTag("pig") and (dude:HasTag("guard") or not attacker:HasTag("pig"))
                end, MAX_TARGET_SHARES)
            else
                if not (attacker:HasTag("pig") and attacker:HasTag("guard")) then
                    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude)
                        return dude:HasTag("pig")
                    end, MAX_TARGET_SHARES)
                end
            end
        end

        if not inst:HasTag("guards_called") then
            inst:AddTag("guards_called")
            if inst:HasTag("shopkeep") or inst:HasTag("pigqueen") then
                spawn_guard_tasks(inst, data.attacker)
            end
        end
    end
end

local builds = {"pig_build", "pigspotted_build"}

local function NormalRetargetFn(inst)
    return FindEntity(inst, TUNING.CITY_PIG_GUARD_TARGET_DIST, function(guy)
        if not guy.LightWatcher or guy.LightWatcher:IsInLight() then

            if guy:HasTag("player") and inst:HasTag("angry_at_player") and guy.components.health
                and not guy.components.health:IsDead() and inst.components.combat:CanTarget(guy)
                and not (inst.components.combat.target and inst.components.combat.target:HasTag("player")) then

                inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_GUARD_TALK_ANGRY_PLAYER))
                -- inst.components.talker:Say( getSpeechType(inst,STRINGS.CITY_PIG_GUARD_TALK_ANGRY_PLAYER) )
            end

            return (guy:HasTag("monster") or (guy:HasTag("player") and inst:HasTag("angry_at_player"))) and
                       guy.components.health and not guy.components.health:IsDead() and
                       inst.components.combat:CanTarget(guy) and
                       not (inst.components.follower.leader ~= nil and guy:HasTag("abigail"))
        end
    end)
end

local function NormalKeepTargetFn(inst, target)
    -- give up on dead guys, or guys in the dark, or werepigs
    return inst.components.combat:CanTarget(target) and (not target.LightWatcher or target.LightWatcher:IsInLight()) and
               not (target.sg and target.sg:HasStateTag("transform"))
end

local function NormalShouldSleep(inst)
    if inst.components.follower and inst.components.follower.leader then
        local fire = FindEntity(inst, 6, function(ent)
            return ent.components.burnable and ent.components.burnable:IsBurning()
        end, {
            "campfire",
        })
        return DefaultSleepTest(inst) and fire and (not inst.LightWatcher or inst.LightWatcher:IsInLight())
    else
        return DefaultSleepTest(inst)
    end
end

local function SetNormalPig(inst, brain_id)
    local brain = require "brains/citypigbrain"
    inst:SetBrain(brain)
    inst:SetStateGraph("SGpig_city")

    inst.components.sleeper:SetResistance(2)

    inst.components.combat:SetDefaultDamage(TUNING.PIG_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PIG_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED

    inst.components.sleeper:SetSleepTest(NormalShouldSleep)
    inst.components.sleeper:SetWakeTest(DefaultWakeTest)

    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:AddRandomLoot("meat", 3)
    inst.components.lootdropper:AddRandomLoot("pigskin", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst.components.health:SetMaxHealth(TUNING.PIG_HEALTH)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)
    inst.components.combat:SetTarget(nil)
    inst:ListenForEvent("suggest_tree_target", function(inst, data)
        if data and data.tree and inst:GetBufferedAction() ~= ACTIONS.CHOP then
            inst.tree_target = data.tree
        end
    end)

    inst:ListenForEvent("itemreceived", function(inst, data)
        if data.item.prefab == "oinc" or data.item.prefab == "oinc10" or data.item.prefab == "oinc100" then
            if inst:HasTag("angry_at_player") then
                if not inst.bribe_count then
                    inst.bribe_count = 0
                end

                -- If the item is not an oinc it's obviously an oinc10, so we count the bribe accordingly
                if data.item.prefab == "oinc" then
                    inst.bribe_count = inst.bribe_count + 1
                elseif data.item.prefab == "oinc10" then
                    inst.bribe_count = inst.bribe_count + 10
                elseif data.item.prefab == "oinc100" then
                    inst.bribe_count = inst.bribe_count + 100
                end
                inst.bribe_count = inst.bribe_count * data.item.components.stackable.stacksize

                local bribe_threshold = inst:HasTag("guard") and 10 or 1
                if inst.bribe_count >= bribe_threshold then
                    inst:RemoveTag("angry_at_player")

                    if inst.components.combat and inst.components.combat.target and inst.components.combat.target:HasTag("player") then
                        inst.components.combat:GiveUp()
                    end

                    inst.bribe_count = 0
                    inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_FORGIVE_PLAYER))
                    -- inst.components.talker:Say(getSpeechType(inst, STRINGS.CITY_PIG_TALK_FORGIVE_PLAYER))
                else
                    inst.sayline(inst, getSpeechType(inst, STRINGS.CITY_PIG_TALK_NOT_ENOUGH))
                end
            end
        end
    end)

    inst.components.trader:Enable()
    inst.components.talker:StopIgnoringAll()
end

local function throwcrackers(inst)
    local cracker = SpawnPrefab("firecrackers")
    inst.components.inventory:GiveItem(cracker)
    local pos = inst:GetPosition()
    local start_angle = inst.Transform:GetRotation()
    local radius = 5
    local attempts = 12

    local test_fn = function(offset)
        local ents = TheSim:FindEntities(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, 2, nil, {
            "INLIMBO",
        })

        if #ents == 0 then
            return true
        end
    end
    local _, new_angle = FindValidPositionByFan(start_angle, radius, attempts, test_fn)

    if new_angle then
        inst.Transform:SetRotation(new_angle / DEGREES)
    end

    local rot = inst.Transform:GetRotation() * DEGREES

    local tossdir = Vector3(0, 0, 0)
    tossdir.x = math.cos(rot)
    tossdir.z = -math.sin(rot)

    inst.components.inventory:DropItem(cracker, nil, nil, nil, nil, tossdir)
    cracker.components.fuse:StartFuse()
end

local function OnSave(inst, data)
    data.build = inst.build

    data.children = {}
    -- for the shopkeepers if they have spawned their desk
    if inst.desk then
        table.insert(data.children, inst.desk.GUID)
        data.desk = inst.desk.GUID
    end

    if inst.torch then
        table.insert(data.children, inst.torch.GUID)
        data.torch = inst.torch.GUID
    end
    if inst.axe then
        table.insert(data.children, inst.axe.GUID)
        data.axe = inst.axe.GUID
    end

    if inst:HasTag("atdesk") then
        data.atdesk = true
    end
    if inst:HasTag("guards_called") then
        data.guards_called = true
    end
    if inst.task_guard1 or inst.task_guard2 then
        data.doSpawnGuardTask = true
    end
    -- end shopkeeper stuff

    data.angryatplayer = inst:HasTag("angry_at_player")
    data.equipped = inst.equipped
    data.recieved_trinket = inst:HasTag("recieved_trinket")
    data.paytax = inst:HasTag("paytax")
    data.daily_gift = inst.daily_gift

    if data.children and #data.children > 0 then
        return data.children
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    inst.build = data.build or builds[1]
    if data.atdesk then
        inst.sg:GoToState("desk_pre")
    end

    if data.guards_called then
        inst:AddTag("guards_called")
    end

    if data.doSpawnGuardTask then
        spawn_guard_tasks(inst)
    end

    if data.equipped then
        inst.equipped = true
        inst.equiptask:Cancel()
        inst.equiptask = nil
    end

    if data.angryatplayer then
        inst:AddTag("angry_at_player")
    end

    if data.recieved_trinket then
        inst:AddTag("recieved_trinket")
    end

    if data.paytax then
        inst:AddTag("paytax")
    end

    if data.daily_gift then
        inst.daily_gift = data.daily_gift
    end
end

local function OnLoadPostPass(inst, ents, data)
    if not data or not data.children then
        return
    end

    for _, v in pairs(data.children) do
        local item = ents[v]
        if item then
            if data.desk and data.desk == v then
                inst.desk = item.entity
                inst:AddComponent("homeseeker")
                inst.components.homeseeker:SetHome(inst.desk)
            end
        end
    end
end

local function MakeCityPigman(name, build, sex, tags, common_postinit, master_postinit, econprefab)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddLightWatcher()
        inst.entity:AddNetwork()

        MakeCharacterPhysics(inst, 50, 0.5)

        inst.AnimState:SetBank("townspig")
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:Hide("hat")
        inst.AnimState:Hide("desk")
        inst.AnimState:Hide("ARM_carry")

        inst.DynamicShadow:SetSize(1.5, 0.75)

        inst.Transform:SetFourFaced()

        inst:AddComponent("talker")
        inst.components.talker.ontalk = ontalk
        inst.components.talker.fontsize = 35
        inst.components.talker.font = TALKINGFONT
        inst.components.talker.offset = Vector3(0, -600, 0)
        inst.talkertype = name

        inst.sayline = sayline

        inst:AddTag("character")
        inst:AddTag("pig")
        inst:AddTag("civilized")
        inst:AddTag("scarytoprey")
        inst:AddTag("firecrackerdance")
        inst:AddTag("city_pig")

        -- Sneak these into pristine state for optimization
        inst:AddTag("_named")

        if tags then
            for _, tag in ipairs(tags) do
                inst:AddTag(tag)
            end
        end

        inst.econprefab = econprefab

        if common_postinit then
            common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -- Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_named")

        -- TODO: get this back when string related works are finished @Jerry457
        -- local names = {}
        -- for i, pigname in ipairs(STRINGS.CITYPIGNAMES["UNISEX"]) do
        --     table.insert(names, pigname)
        -- end

        -- if sex then
        --     if sex == MALE then
        --         inst.female = false
        --     else
        --         inst.female = true
        --     end

        --     for i, name in ipairs(STRINGS.CITYPIGNAMES[sex]) do
        --         table.insert(names, name)
        --     end
        -- end

        inst:AddComponent("named")
        -- inst.components.named.possiblenames = names
        inst.components.named.possiblenames = {"placeholder pigman name"}
        inst.components.named:PickNewName()

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED -- 5
        inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED -- 3

        inst:AddComponent("eater")
        inst.components.eater:SetDiet({ FOODGROUP.OMNI })
        inst.components.eater:SetCanEatHorrible()
        inst.components.eater:SetCanEatRaw()
        inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
        inst.components.eater:SetOnEatFn(OnEat)

        inst:AddComponent("combat")
        inst.components.combat.hiteffectsymbol = "pig_torso"

        inst:AddComponent("follower")
        inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
        inst.components.inspectable.nameoverride = econprefab

        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = OnGetItemFromPlayer
        inst.components.trader.onrefuse = OnRefuseItem

        inst:AddComponent("sanityaura")
        inst.components.sanityaura.aurafn = CalcSanityAura

        inst:AddComponent("health")

        inst:AddComponent("sleeper")

        inst:AddComponent("inventory")

        inst:AddComponent("lootdropper")

        inst:AddComponent("knownlocations")

        inst:AddComponent("citypossession")

        inst:AddComponent("citypooper")

        MakePoisonableCharacter(inst)
        MakeMediumBurnableCharacter(inst, "pig_torso")
        MakeMediumFreezableCharacter(inst, "pig_torso")

        inst.throwcrackers = throwcrackers
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnLoadPostPass = OnLoadPostPass

        inst:ListenForEvent("attacked", OnAttacked)

        SetNormalPig(inst)

        if master_postinit then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

--[[ Royal Pig Guard ]]--

local function GetStatus_Guard(inst)
    if inst.components.sleeper:IsAsleep() then
        return "SLEEPING"
    end
end

local function ShouldAcceptItem_Guard(inst, item)
    if inst.components.sleeper:IsAsleep() then
        return false
    end

    if item:HasTag("securitycontract") then
        return true
    end

    return ShouldAcceptItem(inst, item)
end

local function OnChangeArea(inst, data)
    if data and data.tags and table.contains(data.tags, "Gas_Jungle") then
        if inst.components.poisonable then
            inst.components.poisonable:Poison(true, nil, true)
        end
    end
end

local function NormalizeTorch(torch, owner)
    torch.components.fueled.unlimited_fuel = nil

    if not torch.components.citypossession then
        torch:AddComponent("citypossession")
    end
    torch.components.citypossession:SetCity(owner.components.citypossession.cityID)
end

local function NormalizeHalberd(halberd, owner)
    halberd.components.finiteuses.unlimited_uses = nil

    if not halberd.components.citypossession then
        halberd:AddComponent("citypossession")
    end
    halberd.components.citypossession:SetCity(owner.components.citypossession.cityID)
end

local function EquipItems(inst)
    if inst.equipped then
        return
    end

    inst.equipped = true

    local torch = SpawnPrefab("torch")
    inst.components.inventory:GiveItem(torch)
    torch.components.fueled.unlimited_fuel = true

    local axe = SpawnPrefab("halberd")
    inst.components.inventory:GiveItem(axe)
    inst.components.inventory:Equip(axe)
    axe.components.finiteuses.unlimited_uses = true

    local armour = SpawnPrefab("armorwood")
    inst.components.inventory:GiveItem(armour)
    inst.components.inventory:Equip(armour)
end

local function OnDeath_Guard(inst, data)
    local torch = inst.components.inventory:FindItem(function(item)
        if item.prefab == "torch" and item.components.fueled and item.components.fueled.unlimited_fuel then
            return true
        end
    end)
    if torch then
        NormalizeTorch(torch, inst)
    end

    local axe = inst.components.inventory:FindItem(function(item)
        if item.prefab == "halberd" and item.components.finiteuses and item.components.finiteuses.unlimited_uses then
            return true
        end
    end)
    if axe then
        NormalizeHalberd(axe, inst)
    end
end

local function OnDropItem(inst, data)
    local item = data.item
    if not item or not item:IsValid() then
        return
    end

    if item.prefab == "torch" then
        NormalizeTorch(item, inst)
    end

    if item.prefab == "halberd" then
        NormalizeHalberd(item, inst)
    end

    if item.prefab == "armorwood" then
        local citypossession = item.components.citypossession or item:AddComponent("citypossession")
        citypossession:SetCity(inst.components.citypossession.cityID)
    end
end

local function OnIsDay(inst, isday)
    if not isday then
        return
    end

    inst:DoTaskInTime(0.5 + math.random(), function()
        local axe = inst.components.inventory:FindItem(function(item)
            if item.prefab == "halberd" then
                return true
            end
        end)

        if axe then
            inst.components.inventory:Equip(axe)
        end
    end)
end

local function OnIsDusk(inst, isdusk)
    if not isdusk then
        return
    end

    local function getspeech()
        return STRINGS.CITY_PIG_GUARD_LIGHT_TORCH.DEFAULT[math.random(#STRINGS.CITY_PIG_GUARD_LIGHT_TORCH.DEFAULT)]
    end
    inst.sayline(inst, getspeech())
    -- inst.components.talker:Say(getspeech(), 1.5, nil, true)
    inst:DoTaskInTime(0.5 + (math.random() * 1), function()
        local torch = inst.components.inventory:FindItem(function(item)
            if item.prefab == "torch" then
                return true
            end
        end)
        if torch then
            inst.components.inventory:Equip(torch)
        end
    end)
end

local guard_brain = require("brains/royalpigguardbrain")

local function pig_guard_master_postinit(inst)
    inst.components.burnable:SetBurnTime(2)

    inst.components.inspectable.getstatus = GetStatus_Guard

    inst.components.trader:SetAcceptTest(ShouldAcceptItem_Guard)

    inst:AddComponent("areaaware")
    inst:ListenForEvent("changearea", OnChangeArea)

    inst:SetBrain(guard_brain)

    inst.equiptask = inst:DoTaskInTime(0, EquipItems)

    inst:ListenForEvent("death", OnDeath_Guard)
    inst:ListenForEvent("dropitem", OnDropItem)

    inst:WatchWorldState("isday", OnIsDay)
    inst:WatchWorldState("isdusk", OnIsDusk)
end

--[[ Pig Shopkeep ]]--

local SHOP_STAND_TAGS = {"shop_pedestal"}

local function OnDeath_ShopKeep(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    local shops = TheSim:FindEntities(x, y, z, 30, SHOP_STAND_TAGS)
    for _, ent in pairs(shops) do
        ent:AddTag("nodailyrestock")
    end
end

local function shopkeeper_speech(inst, speech)
    if inst:IsValid() and not inst:IsAsleep() and not inst.components.combat.target and not inst:IsInLimbo() then
        inst.sayline(inst, speech)
    end
end

local function CloseShop(inst)
    if inst:IsValid() and not inst:IsAsleep() and not inst.components.combat.target and not inst:IsInLimbo() then
        inst.sg:GoToState("idle")
        shopkeeper_speech(inst, GetRandomItem(STRINGS.CITY_PIG_SHOPKEEPER_CLOSING))
    end
end

local function shopkeeper_common_postinit(inst)
    inst.AnimState:AddOverrideBuild("townspig_shop_wip")
end

local function shopkeeper_master_postinit(inst)
    inst.components.sleeper.onlysleepsfromitems = true

    inst.separatedesk = separatedesk
    inst.shopkeeper_speech = shopkeeper_speech

    -- TheWorld:ListenForEvent("enterroom", function(data)
    --     shopkeeper_speech(inst, getSpeechType(inst,STRINGS.CITY_PIG_SHOPKEEPER_GREETING) )
    -- end)

    inst:ListenForEvent("death", OnDeath_ShopKeep)

    inst:WatchWorldState("isnight", CloseShop)
end

local function MakeShopKeeper(name, build, sex, tags, econprefab)
    tags = shallowcopy(tags or {})
    table.insert(tags, "shopkeep")
    return MakeCityPigman(name, build, sex, tags, shopkeeper_common_postinit, shopkeeper_master_postinit, econprefab)
end

--[[ Pig Mechanic ]]--

local function MechanicMasterPostinit(inst)
    inst:AddComponent("fixer")

    inst:DoTaskInTime(0, function()
        -- Get rid of any hammers we have, cuz bugs
        -- local numHammers = inst.components.inventory:Count("hammer")
        -- local hammers = inst.components.inventory:GetItemByName("hammer", numHammers)
        local hammers = inst.components.inventory:FindItems(function(item) return item.prefab == "hammer" end)
        for _, hammer in pairs(hammers) do
            inst.components.inventory:RemoveItem(hammer, true)
            hammer:Remove()
        end
        -- and give us a brand new one
        local tool = SpawnPrefab("hammer")
        if tool then
            inst.components.inventory:GiveItem(tool)
            inst.components.inventory:Equip(tool)
        end
    end)

end

--[[ Pig Queen ]]--

local function QueenCommonPostinit(inst)
    MakeCharacterPhysics(inst, 50, 0.75)
end

local function QueenMasterPostinit(inst)
    -- TODO: get this back when string related works are finished @Jerry457
    -- inst.components.named.possiblenames = STRINGS.QUEENPIGNAMES
    -- inst.components.named:PickNewName()
end

--[[ Pig Mayor ]]--

local function MayorMasterPostinit(inst)
    -- TODO: get this back when string related works are finished @Jerry457
    -- inst.components.named:SetName(STRINGS.NAMES.PIGMAN_MAYOR)
end

local function MayorShopkeeperMasterPostinit(inst)
    -- TODO: get this back when string related works are finished @Jerry457
    -- inst.components.named:SetName(STRINGS.NAMES.PIGMAN_MAYOR)
end

local NOHAT_TAGS = {"emote_nohat"}
local GUARD_TAGS = {"emote_nocurtsy", "guard", "extinguisher"}

return MakeCityPigman("pigman_beautician", "pig_beautician", FEMALE),
       MakeCityPigman("pigman_florist", "pig_florist", FEMALE),
       MakeCityPigman("pigman_erudite", "pig_erudite", FEMALE),
       MakeCityPigman("pigman_hatmaker", "pig_hatmaker", FEMALE),
       MakeCityPigman("pigman_storeowner", "pig_storeowner", FEMALE, NOHAT_TAGS),
       MakeCityPigman("pigman_banker", "pig_banker", MALE, NOHAT_TAGS),
       MakeCityPigman("pigman_collector", "pig_collector", MALE),
       MakeCityPigman("pigman_hunter", "pig_hunter", MALE),
       MakeCityPigman("pigman_professor", "pig_professor", MALE),
       MakeCityPigman("pigman_usher", "pig_usher", MALE),
       MakeCityPigman("pigman_farmer", "pig_farmer", MALE),
       MakeCityPigman("pigman_miner", "pig_miner", MALE),

       MakeShopKeeper("pigman_beautician_shopkeep", "pig_beautician", FEMALE, nil,        "pigman_beautician"),
       MakeShopKeeper("pigman_florist_shopkeep",    "pig_florist",    FEMALE, nil,        "pigman_florist"),
       MakeShopKeeper("pigman_erudite_shopkeep",    "pig_erudite",    FEMALE, nil,        "pigman_erudite"),
       MakeShopKeeper("pigman_hatmaker_shopkeep",   "pig_hatmaker",   FEMALE, nil,        "pigman_hatmaker"),
       MakeShopKeeper("pigman_storeowner_shopkeep", "pig_storeowner", FEMALE, NOHAT_TAGS, "pigman_storeowner"),
       MakeShopKeeper("pigman_banker_shopkeep",     "pig_banker",     MALE,   NOHAT_TAGS, "pigman_banker"),
       MakeShopKeeper("pigman_shopkeep",            "pig_banker",     MALE,   nil,        "pigman_banker"),
       MakeShopKeeper("pigman_hunter_shopkeep",     "pig_hunter",     MALE,   nil,        "pigman_hunter"),
       MakeShopKeeper("pigman_farmer_shopkeep",     "pig_farmer",     MALE,   nil,        "pigman_farmer"),
       MakeShopKeeper("pigman_miner_shopkeep",      "pig_miner",      MALE,   nil,        "pigman_miner"),
       MakeShopKeeper("pigman_collector_shopkeep",  "pig_collector",  MALE,   nil,        "pigman_collector"),
       MakeShopKeeper("pigman_professor_shopkeep",  "pig_professor",  MALE,   nil,        "pigman_professor"),
       MakeShopKeeper("pigman_mechanic_shopkeep",   "pig_mechanic",   MALE,   nil,        "pigman_mechanic"),

       MakeCityPigman("pigman_royalguard", "pig_royalguard", MALE, GUARD_TAGS, nil, pig_guard_master_postinit),
       MakeCityPigman("pigman_royalguard_2", "pig_royalguard", MALE, GUARD_TAGS, nil, pig_guard_master_postinit),

       MakeCityPigman("pigman_mechanic", "pig_mechanic", MALE, nil, nil, MechanicMasterPostinit),

       MakeCityPigman("pigman_mayor", "pig_mayor", MALE, nil, nil, MayorMasterPostinit),
       MakeCityPigman("pigman_mayor_shopkeep", "pig_mayor", MALE, nil, shopkeeper_common_postinit, MayorShopkeeperMasterPostinit, "pigman_mayor"),
       MakeCityPigman("pigman_queen", "pig_queen", FEMALE, {"pigqueen", "emote_nohat"}, QueenCommonPostinit, QueenMasterPostinit)

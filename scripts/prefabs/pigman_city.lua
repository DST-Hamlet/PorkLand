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

local function GetSpeechType(inst, speech)
    return inst.talkertype and STRINGS[speech][inst.talkertype]
        and speech .. "." .. inst.talkertype
        or speech .. ".DEFAULT"
end

local function resolve_string_from_path(str)
    local strtbl = STRINGS
    local components = string.split(str, ".")
    for _, component in ipairs(components) do
        strtbl = strtbl[component]
        if strtbl == nil then
            print("WARNING: failed to resolve string from path", str)
            return nil
        end
    end
    return strtbl
end

-- line: should be something like "CITY_PIG_TALK_FORGIVE_PLAYER.DEFAULT"
-- format_args: should be something like "a" or {line = "CITY_PIG_BANKER_TRADE"} or nil
local function SayLine(inst, line, ...)
    local format_args = {...}
    local strtbl = resolve_string_from_path(line)
    if strtbl == STRINGS or strtbl == nil then
        print("no line found to say for", inst, line)
        return
    end
    local strid = type(strtbl) == "table" and math.random(#strtbl) or 0
    inst.components.talker:Chatter(json.encode({line = line, format_args = format_args}), strid, 1.5)
end

local function ResolveChatterString(inst, strid, strtbl)
    local strtbl = strtbl:value()
    local strid = strid:value()
    local decoded = json.decode(strtbl)
    local line = resolve_string_from_path(decoded.line)
    if strtbl == STRINGS or strtbl == nil then
        print("no line found to say for", inst, line)
        return
    end
    if strid ~= 0 then
        line = line[strid]
    end

    if decoded.format_args then
        local format_args = {}
        for _, arg in ipairs(decoded.format_args) do
            if type(arg) == "table" then
                table.insert(format_args, resolve_string_from_path(arg.line))
            end
            table.insert(format_args, tostring(arg))
        end
        return string.format(line, unpack(format_args))
    end
    return line
end

local function spawndesk(inst, spawndesk)
    if spawndesk then
        local desklocation = inst:GetPosition()

        inst.desk = SpawnPrefab("pigman_shopkeeper_desk")
        inst.desk.Transform:SetPosition(desklocation.x, desklocation.y, desklocation.z)
        inst.desk:AddComponent("citypossession")
        inst.desk.components.citypossession:SetCity(inst.components.citypossession.cityID)
        if not inst.components.homeseeker then
            inst:AddComponent("homeseeker")
        end
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

local function ondonetalking(inst)
    inst.SoundEmitter:KillSound("talk")
end

local function ontalk(inst, script, mood)
    -- TODO: Make alarmed mood work
    inst.SoundEmitter:KillSound("talk")
    if inst:HasTag("guard") then
        if mood == "alarmed" then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/guard_alert")
        else
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/conversational_talk_gaurd", "talk")
        end
    else
        if inst.female then
            if mood == "alarmed" then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/scream_female")
            else
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/conversational_talk_female", "talk")
            end
        else
            if mood == "alarmed" then
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

    if item:HasTag("oinc") then
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
        for _, wanted in ipairs(wanteditems) do
            if wanted == item.prefab then
                wantitem = true
                break
            end
        end

        if item.prefab == "purplegem" and (inst.prefab == "pigman_banker" or inst.prefab == "pigman_banker_shopkeep") then
            inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_REFUSE_PURPLEGEM"))
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
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_REFUSE_GIFT_DELAY_TOMORROW"))
                else
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_REFUSE_GIFT_DELAY"), delay)
                end
                return false
            else
                return true
            end
        else
            if item:HasTag("relic") then
                if item.prefab == "relic_4" or item.prefab == "relic_5" then
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_REFUSE_PRICELESS_GIFT"))
                else
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_RELIC_GIFT"))
                end
            else
                if item.prefab == "trinket_giftshop_1" or item.prefab == "trinket_giftshop_3" and inst:HasTag("city1") then
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_REFUSE_TRINKET_GIFT"))
                else
                    -- HUGO
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_REFUSE_GIFT"), {line = desc})
                end
            end
            return false
        end
    end

    return false
end

local function OnGetBribe(inst, item)
    if inst:HasTag("angry_at_player") then
        if not inst.bribe_count then
            inst.bribe_count = 0
        end
        inst.bribe_count = inst.bribe_count + item.oincvalue * item.components.stackable.stacksize

        local bribe_threshold = inst:HasTag("guard") and 10 or 1
        if inst.bribe_count >= bribe_threshold then
            inst:RemoveTag("angry_at_player")

            if inst.components.combat and inst.components.combat.target and inst.components.combat.target:HasTag("player") then
                inst.components.combat:GiveUp()
            end

            inst.bribe_count = 0
            inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_FORGIVE_PLAYER"))
        else
            inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_NOT_ENOUGH"))
        end
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    if not inst:HasTag("guard") then -- or inst:HasTag("pigqueen")
        local city = inst:HasTag("city2") and 2 or 1

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
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_GIVE_TRINKET_REWARD"))

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
                    inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_GIVE_REWARD"), 1, {line = desc})

                    for i = 1, qty do
                        local rewarditem = SpawnPrefab(reward)
                        giver.components.inventory:GiveItem(rewarditem, nil, inst:GetPosition())
                    end
                end
            else
                inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_TAKE_GIFT"), 1, {line = desc})
            end
        end
        if item:HasTag("relic") and (inst.prefab == "pigman_collector_shopkeep" or inst.prefab == "pigman_collector") then
            if giver.components.inventory then
                inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_GIVE_RELIC_REWARD"))
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

    if item:HasTag("oinc") then
        OnGetBribe(inst, item)
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
        for _, v in ipairs(ents) do
            if v ~= inst
                and v.components.combat
                and not (v.components.health and v.components.health:IsDead())
                and fn(v) then

                v:PushEvent("suggest_tree_target", {tree = attacker})
                num_helpers = num_helpers + 1
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
        guard.Transform:SetPosition(spawnpt:Get())
        guard:PushEvent("attacked", {
            attacker = attacker,
            damage = 0,
            weapon = nil,
        })
        if attacker then
            attacker:AddTag("wanted_by_guards")
        end
    end
end

local function spawn_guard_tasks(inst, attacker)
    if not inst.task_guard1 then
        inst.task_guard1 = inst:DoTaskInTime(2, function()
            call_guards(inst, attacker)
            inst.task_guard1:Cancel()
            inst.task_guard1 = nil
        end)
    end
    if not inst.task_guard2 then
        inst.task_guard2 = inst:DoTaskInTime(2.5, function()
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

                inst:SayLine(inst:GetSpeechType("CITY_PIG_GUARD_TALK_ANGRY_PLAYER"))
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
        end, {"campfire"})
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

    inst:ListenForEvent("itemget", function(inst, data)
        if data.item:HasTag("oinc") then
            OnGetBribe(inst, data.item)
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
        local ents = TheSim:FindEntities(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, 2, nil, {"INLIMBO"})
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
    cracker.components.burnable:Ignite(nil, nil, inst)
end

local function OnSave(inst, data)
    data.build = inst.build

    data.children = {}
    -- for the shopkeepers if they have spawned their desk
    if inst.desk then
        table.insert(data.children, inst.desk.GUID)
        data.desk = inst.desk.GUID
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
        -- inst.equiptask:Cancel()
        -- inst.equiptask = nil
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

local function MakeCityPigman(name, build, sex, tags, common_postinit, master_postinit, econprefab, name_override)
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
        inst.components.talker.donetalkingfn = ondonetalking
        inst.components.talker.offset = Vector3(0, -600, 0)
        inst.components.talker.resolvechatterfn = ResolveChatterString
        inst.components.talker:MakeChatter()

        inst.SayLine = SayLine
        inst.GetSpeechType = GetSpeechType
        inst.talkertype = name:upper()

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

        if sex == MALE then
            inst.female = false
        else
            inst.female = true
        end

        inst:AddComponent("named")
        if name_override then
           if type(name_override) == "table" then
                inst.components.named.possiblenames = shallowcopy(name_override)
                inst.components.named:PickNewName()
           else
                inst.components.named:SetName(name_override)
            end
        else
            inst.components.named.possiblenames = JoinArrays(STRINGS.CITYPIGNAMES["UNISEX"], STRINGS.CITYPIGNAMES[sex])
            inst.components.named:PickNewName()
        end

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
        inst.components.combat.hiteffectsymbol = "torso"

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
        MakeMediumBurnableCharacter(inst, "torso")
        MakeMediumFreezableCharacter(inst, "torso")
        MakeHauntablePanic(inst)

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
    torch.components.burnable.ignorefuel = false

    if not torch.components.citypossession then
        torch:AddComponent("citypossession")
    end
    torch.components.citypossession:SetCity(owner.components.citypossession.cityID)
end

local function NormalizeHalberd(halberd, owner)
    halberd.components.finiteuses:SetIgnoreCombatDurabilityLoss(false)

    if not halberd.components.citypossession then
        halberd:AddComponent("citypossession")
    end
    halberd.components.citypossession:SetCity(owner.components.citypossession.cityID)
end

local function EquipItems(inst)
    if inst.equipped then
        local torches = inst.components.inventory:FindItems(function(item) return item.prefab == "torch" end)
        for _, torch in ipairs(torches) do
            torch.components.burnable.ignorefuel = true
        end
        local halberds = inst.components.inventory:FindItems(function(item) return item.prefab == "halberd" end)
        for _, axe in ipairs(halberds) do
            axe.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)
        end
    else
        inst.equipped = true

        local torch = SpawnPrefab("torch")
        torch.components.burnable.ignorefuel = true
        inst.components.inventory:GiveItem(torch)

        local axe = SpawnPrefab("halberd")
        axe.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)
        inst.components.inventory:Equip(axe)

        local armour = SpawnPrefab("armorwood")
        inst.components.inventory:Equip(armour)
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

    inst:SayLine(inst:GetSpeechType("CITY_PIG_GUARD_LIGHT_TORCH"))
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

    inst:ListenForEvent("dropitem", OnDropItem)

    inst:WatchWorldState("isday", OnIsDay)
    inst:WatchWorldState("isdusk", OnIsDusk)
end

--[[ Pig Shopkeep ]]--

local SHOP_STAND_TAGS = {"shop_pedestal"}

local function OnDeath_ShopKeep(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    local shops = TheSim:FindEntities(x, y, z, 30, SHOP_STAND_TAGS)
    for _, ent in ipairs(shops) do
        ent:AddTag("nodailyrestock")
    end
end

-- This is different from Don't Starve Hamlet, we use thing like "CITY_PIG_SHOPKEEPER_CLOSING" instead of STRINGS.CITY_PIG_SHOPKEEPER_CLOSING[0]
local function ShopkeeperSpeech(inst, speech)
    if inst:IsValid() and not inst:IsAsleep() and not inst.components.combat.target and not inst:IsInLimbo() then
        inst:SayLine(speech)
    end
end

local function CloseShop(inst)
    if inst:IsValid() and not inst:IsAsleep() and not inst.components.combat.target and not inst:IsInLimbo() then
        inst.sg:GoToState("idle")
        inst:ShopkeeperSpeech("CITY_PIG_SHOPKEEPER_CLOSING")
    end
end

local function shopkeeper_common_postinit(inst)
    inst:AddTag("shopkeep")
    inst.AnimState:AddOverrideBuild("townspig_shop_wip")
end

local function shopkeeper_master_postinit(inst)
    inst.components.sleeper.onlysleepsfromitems = true

    inst.separatedesk = separatedesk
    inst.ShopkeeperSpeech = ShopkeeperSpeech

    -- TODO: Make it greet every new customer
    -- TheWorld:ListenForEvent("enterroom", function(data)
    --     inst:ShopkeeperSpeech(inst:GetSpeechType("CITY_PIG_SHOPKEEPER_GREETING"))
    -- end)
    inst:ListenForEvent("entitywake", function()
        inst:ShopkeeperSpeech(inst:GetSpeechType("CITY_PIG_SHOPKEEPER_GREETING"))
    end)

    inst:ListenForEvent("death", OnDeath_ShopKeep)

    inst:WatchWorldState("isnight", CloseShop)
end

local function MakeShopKeeper(name, build, sex, tags, econprefab, name_override)
    return MakeCityPigman(name, build, sex, tags, shopkeeper_common_postinit, shopkeeper_master_postinit, econprefab, name_override)
end

--[[ Pig Mechanic ]]--

local function MechanicMasterPostinit(inst)
    inst:AddComponent("fixer")

    inst:DoTaskInTime(0, function()
        local tool = SpawnPrefab("hammer")
        if tool then
            inst.components.inventory:GiveItem(tool)
            inst.components.inventory:Equip(tool)
            tool.persists = false
        end
    end)
end

--[[ Pig Queen ]]--

local function QueenCommonPostinit(inst)
    MakeCharacterPhysics(inst, 50, 0.75)
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
       MakeShopKeeper("pigman_mayor_shopkeep",      "pig_mayor",      MALE,   nil,        "pigman_mayor",   STRINGS.NAMES.PIGMAN_MAYOR),

       MakeCityPigman("pigman_royalguard", "pig_royalguard", MALE, GUARD_TAGS, nil, pig_guard_master_postinit),
       MakeCityPigman("pigman_royalguard_2", "pig_royalguard_2", MALE, GUARD_TAGS, nil, pig_guard_master_postinit),

       MakeCityPigman("pigman_mechanic", "pig_mechanic", MALE, nil, nil, MechanicMasterPostinit),

       MakeCityPigman("pigman_mayor", "pig_mayor", MALE, nil, nil, nil, nil, STRINGS.NAMES.PIGMAN_MAYOR),
       MakeCityPigman("pigman_queen", "pig_queen", FEMALE, {"pigqueen", "emote_nohat"}, QueenCommonPostinit, nil, nil, STRINGS.QUEENPIGNAMES)

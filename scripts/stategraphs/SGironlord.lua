require("stategraphs/commonstates")


local actionhandlers =
{
    ActionHandler(ACTIONS.CHOP, "work"),
    ActionHandler(ACTIONS.MINE,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("premine")
                and (inst.sg:HasStateTag("mining") and
                    "mine" or
                    "mine_start")
                or nil
        end),
    ActionHandler(ACTIONS.HAMMER,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("prehammer")
                and (inst.sg:HasStateTag("hammering") and
                    "hammer" or
                    "hammer_start")
                or nil
        end),
    ActionHandler(ACTIONS.TERRAFORM, "terraform"),
    ActionHandler(ACTIONS.DIG,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("predig")
                and (inst.sg:HasStateTag("digging") and
                    "dig" or
                    "dig_start")
                or nil
        end),
    ActionHandler(ACTIONS.NET,
        function(inst)
            return not inst.sg:HasStateTag("prenet")
                and (inst.sg:HasStateTag("netting") and
                    "bugnet" or
                    "bugnet_start")
                or nil
        end),

    ActionHandler(ACTIONS.FISH, "fishing_pre"),
    ActionHandler(ACTIONS.FISH_OCEAN, "fishing_ocean_pre"),
    ActionHandler(ACTIONS.OCEAN_FISHING_POND, "fishing_ocean_pre"),
    ActionHandler(ACTIONS.OCEAN_FISHING_CAST, "oceanfishing_cast"),
    ActionHandler(ACTIONS.OCEAN_FISHING_REEL,
        function(inst, action)
            local fishable = action.invobject ~= nil and action.invobject.components.oceanfishingrod.target or nil
            if fishable ~= nil and fishable.components.oceanfishable ~= nil and fishable:HasTag("partiallyhooked") then
                return "oceanfishing_sethook"
            elseif inst:HasTag("fishing_idle") and not (inst.sg:HasStateTag("reeling") and not inst.sg.statemem.allow_repeat) then
                return "oceanfishing_reel"
            end
            return nil
        end),
    ActionHandler(ACTIONS.FERTILIZE,
        function(inst, action)
            return (((action.target ~= nil and action.target ~= inst) or action:GetActionPoint() ~= nil) and "doshortaction")
                or (action.invobject ~= nil and action.invobject:HasTag("slowfertilize") and "fertilize")
                or "fertilize_short"
        end),
    ActionHandler(ACTIONS.SMOTHER,
        function(inst)
            return inst:HasTag("pyromaniac") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.MANUALEXTINGUISH,
        function(inst)
            return inst:HasTag("pyromaniac") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.TRAVEL, "doshortaction"),
    ActionHandler(ACTIONS.LIGHT, "catchonfire"),
    ActionHandler(ACTIONS.UNLOCK, "give"),
    ActionHandler(ACTIONS.USEKLAUSSACKKEY,
        function(inst)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.TURNOFF, "give"),
    ActionHandler(ACTIONS.TURNON, "give"),
    ActionHandler(ACTIONS.ADDFUEL, "doshortaction"),
    ActionHandler(ACTIONS.ADDWETFUEL, "doshortaction"),
    ActionHandler(ACTIONS.REPAIR, "dolongaction"),
    ActionHandler(ACTIONS.READ,
        function(inst, action)
            return (action.invobject ~= nil and action.invobject.components.simplebook ~= nil and "cookbook_open")
				or (inst.components.reader ~= nil and inst.components.reader:IsAspiringBookworm() and "book_peruse")
				or "book"
        end),
    ActionHandler(ACTIONS.MAKEBALLOON, "makeballoon"),
    ActionHandler(ACTIONS.DEPLOY, "doshortaction"),
    ActionHandler(ACTIONS.DEPLOY_TILEARRIVE, "doshortaction"),
    ActionHandler(ACTIONS.STORE, "doshortaction"),
    ActionHandler(ACTIONS.DROP,
        function(inst)
            return inst.components.inventory:IsHeavyLifting()
                and not inst.components.rider:IsRiding()
                and "heavylifting_drop"
                or "doshortaction"
        end),
    ActionHandler(ACTIONS.MURDER,
        function(inst)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.UPGRADE, "dolongaction"),
    ActionHandler(ACTIONS.ACTIVATE,
        function(inst, action)
            local obj = action.target or action.invobject
            return action.target.components.activatable ~= nil
                and (   (action.target.components.activatable.standingaction and "dostandingaction") or
                        (action.target.components.activatable.quickaction and "doshortaction") or
                        "dolongaction"
                    )
                or nil
        end),
    ActionHandler(ACTIONS.OPEN_CRAFTING, "dostandingaction"),
    ActionHandler(ACTIONS.PICK,
        function(inst, action)
            return (inst.components.rider ~= nil and inst.components.rider:IsRiding() and "dolongaction")
                or (action.target ~= nil
                and action.target.components.pickable ~= nil
                and (   (action.target.components.pickable.jostlepick and "dojostleaction") or
                        (action.target.components.pickable.quickpick and "doshortaction") or
                        (inst:HasTag("fastpicker") and "doshortaction") or
                        (inst:HasTag("quagmire_fasthands") and "domediumaction") or
                        "dolongaction"  ))
                or nil
        end),
    ActionHandler(ACTIONS.CARNIVALGAME_FEED,
        function(inst, action)
            return (inst.components.rider ~= nil and inst.components.rider:IsRiding() and "dolongaction")
				or "doequippedaction"
        end),
    ActionHandler(ACTIONS.SLEEPIN,
        function(inst, action)
            if action.invobject ~= nil then
                if action.invobject.onuse ~= nil then
                    action.invobject:onuse(inst)
                end
                return "bedroll"
            else
                return "tent"
            end
        end),

    ActionHandler(ACTIONS.TAKEITEM,
        function(inst, action)
            return action.target ~= nil
                and action.target.takeitem ~= nil --added for quagmire
                and "give"
                or "dolongaction"
        end),

    ActionHandler(ACTIONS.BUILD,
        function(inst, action)
            local rec = GetValidRecipe(action.recipe)
            return (rec ~= nil and rec.sg_state)
                or (inst:HasTag("hungrybuilder") and "dohungrybuild")
                or (inst:HasTag("fastbuilder") and "domediumaction")
                or (inst:HasTag("slowbuilder") and "dolongestaction")
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.SHAVE, "shave"),
    ActionHandler(ACTIONS.COOK,
        function(inst, action)
            return inst:HasTag("expertchef") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.FILL, "dolongaction"),
    ActionHandler(ACTIONS.FILL_OCEAN, "dolongaction"),
    ActionHandler(ACTIONS.PICKUP,
        function(inst, action)
            return (action.target ~= nil and action.target:HasTag("minigameitem") and "dosilentshortaction")
                or (inst.components.rider ~= nil and inst.components.rider:IsRiding()
                    and (action.target ~= nil and action.target:HasTag("heavy") and "dodismountaction"
                        or "domediumaction")
                    )
                or "doshortaction"
        end),
    ActionHandler(ACTIONS.CHECKTRAP,
        function(inst, action)
            return (inst.components.rider ~= nil and inst.components.rider:IsRiding() and "domediumaction")
                or "doshortaction"
        end),
    ActionHandler(ACTIONS.RUMMAGE, "doshortaction"),
    ActionHandler(ACTIONS.BAIT, "doshortaction"),
    ActionHandler(ACTIONS.HEAL, "dolongaction"),
    ActionHandler(ACTIONS.SEW, "dolongaction"),
    ActionHandler(ACTIONS.TEACH, "dolongaction"),
    ActionHandler(ACTIONS.RESETMINE, "dolongaction"),
    ActionHandler(ACTIONS.EAT,
        function(inst, action)
            if inst.sg:HasStateTag("busy") then
                return
            end
            local obj = action.target or action.invobject
            if obj == nil then
                return
            elseif obj.components.edible ~= nil then
                if not inst.components.eater:PrefersToEat(obj) then
                    inst:PushEvent("wonteatfood", { food = obj })
                    return
                end
            elseif obj.components.soul ~= nil then
                if inst.components.souleater == nil then
                    inst:PushEvent("wonteatfood", { food = obj })
                    return
                end
            else
                return
            end
            return (obj.components.soul ~= nil and "eat")
                or (obj.components.edible.foodtype == FOODTYPE.MEAT and "eat")
                or "quickeat"
        end),
    ActionHandler(ACTIONS.GIVE,
        function(inst, action)
            return action.invobject ~= nil
                and action.target ~= nil
                and (   (action.target:HasTag("moonportal") and action.invobject:HasTag("moonportalkey") and "dochannelaction") or
                        (action.invobject.prefab == "quagmire_portal_key" and action.target:HasTag("quagmire_altar") and "quagmireportalkey") or
                        (action.target:HasTag("give_dolongaction") and "dolongaction")
                    )
                or "give"
        end),
    ActionHandler(ACTIONS.APPRAISE, "give"),
    ActionHandler(ACTIONS.GIVETOPLAYER, "give"),
    ActionHandler(ACTIONS.GIVEALLTOPLAYER, "give"),
    ActionHandler(ACTIONS.FEEDPLAYER, "give"),
    ActionHandler(ACTIONS.DECORATEVASE, "dolongaction"),
    ActionHandler(ACTIONS.PLANT, "doshortaction"),
    ActionHandler(ACTIONS.HARVEST,
        function(inst)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.PLAY,
        function(inst, action)
            if action.invobject ~= nil then
                return (action.invobject:HasTag("flute") and "play_flute")
                    or (action.invobject:HasTag("horn") and "play_horn")
                    or (action.invobject:HasTag("bell") and "play_bell")
                    or (action.invobject:HasTag("whistle") and "play_whistle")
                    or nil
            end
        end),
    ActionHandler(ACTIONS.FAN, "use_fan"),
    ActionHandler(ACTIONS.JUMPIN, "jumpin_pre"),
    ActionHandler(ACTIONS.TELEPORT,
        function(inst, action)
            return action.invobject ~= nil and "dolongaction" or "give"
        end),
    ActionHandler(ACTIONS.DRY, "doshortaction"),
    ActionHandler(ACTIONS.CASTSPELL,
        function(inst, action)
            return action.invobject ~= nil
                and ((action.invobject:HasTag("gnarwail_horn") and "play_gnarwail_horn")
                    or (action.invobject:HasTag("guitar") and "play_strum")
                    or (action.invobject:HasTag("cointosscast") and "cointosscastspell")
                    or (action.invobject:HasTag("quickcast") and "quickcastspell")
                    or (action.invobject:HasTag("veryquickcast") and "veryquickcastspell")
                    )
                or "castspell"
        end),
    ActionHandler(ACTIONS.CASTAOE,
        function(inst, action)
            return action.invobject ~= nil
                and (   (action.invobject:HasTag("aoeweapon_lunge") and "combat_lunge_start") or
                        (action.invobject:HasTag("aoeweapon_leap") and (action.invobject:HasTag("superjump") and "combat_superjump_start" or "combat_leap_start")) or
                        (action.invobject:HasTag("blowdart") and "blowdart_special") or
                        (action.invobject:HasTag("throw_line") and "throw_line") or
                        (action.invobject:HasTag("book") and "book") or
                        (action.invobject:HasTag("parryweapon") and "parry_pre")
                    )
                or "castspell"
        end),
    ActionHandler(ACTIONS.CAST_POCKETWATCH,
        function(inst, action)
            return action.invobject ~= nil
                and (   action.invobject:HasTag("recall_unmarked") and "dolongaction"
						or action.invobject:HasTag("pocketwatch_warp_casting") and "pocketwatch_warpback_pre"
						or action.invobject.prefab == "pocketwatch_portal" and "pocketwatch_openportal"
                    )
                or "pocketwatch_cast"
        end),
    ActionHandler(ACTIONS.BLINK,
        function(inst, action)
            return action.invobject == nil and inst:HasTag("soulstealer") and "portal_jumpin_pre" or "quicktele"
        end),
    ActionHandler(ACTIONS.BLINK_MAP,
        function(inst, action)
            return action.invobject == nil and inst:HasTag("soulstealer") and "portal_jumpin_pre" or "quicktele"
        end),
    ActionHandler(ACTIONS.CASTSUMMON,
        function(inst, action)
            return action.invobject ~= nil and action.invobject:HasTag("abigail_flower") and "summon_abigail" or "castspell"
        end),
    ActionHandler(ACTIONS.CASTUNSUMMON,
        function(inst, action)
            return action.invobject ~= nil and action.invobject:HasTag("abigail_flower") and "unsummon_abigail" or "castspell"
        end),
    ActionHandler(ACTIONS.COMMUNEWITHSUMMONED,
        function(inst, action)
            return action.invobject ~= nil and action.invobject:HasTag("abigail_flower") and "commune_with_abigail" or "dolongaction"
        end),
    ActionHandler(ACTIONS.SING, "sing_pre"),
    ActionHandler(ACTIONS.SING_FAIL, "sing_fail"),
    ActionHandler(ACTIONS.COMBINESTACK, "doshortaction"),
    ActionHandler(ACTIONS.FEED, "dolongaction"),
    -- ActionHandler(ACTIONS.ATTACK,
        -- function(inst, action)
            -- inst.sg.mem.localchainattack = not action.forced or nil
            -- if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or inst.components.health:IsDead()) then
                -- local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
                -- return (weapon == nil and "attack")
                    -- or (weapon:HasTag("blowdart") and "blowdart")
					-- or (weapon:HasTag("slingshot") and "slingshot_shoot")
                    -- or (weapon:HasTag("thrown") and "throw")
                    -- or (weapon:HasTag("propweapon") and "attack_prop_pre")
                    -- or (weapon:HasTag("multithruster") and "multithrust_pre")
                    -- or (weapon:HasTag("helmsplitter") and "helmsplitter_pre")
                    -- or "attack"
            -- end
        -- end),
	ActionHandler(ACTIONS.ATTACK, "power_punch"),
	-- ActionHandler(ACTIONS.ATTACK, "attack"),
    ActionHandler(ACTIONS.TOSS, "throw"),
    ActionHandler(ACTIONS.UNPIN, "doshortaction"),
    ActionHandler(ACTIONS.CATCH, "catch_pre"),

    ActionHandler(ACTIONS.CHANGEIN, "usewardrobe"),
    ActionHandler(ACTIONS.HITCHUP, "usewardrobe"),
    ActionHandler(ACTIONS.UNHITCH, "usewardrobe"),
    ActionHandler(ACTIONS.MARK, "doshortaction"),
    ActionHandler(ACTIONS.WRITE, "doshortaction"),
    ActionHandler(ACTIONS.ATTUNE, "dolongaction"),
    ActionHandler(ACTIONS.MIGRATE, "migrate"),
    ActionHandler(ACTIONS.MOUNT, "doshortaction"),
    ActionHandler(ACTIONS.SADDLE, "doshortaction"),
    ActionHandler(ACTIONS.UNSADDLE, "unsaddle"),
    ActionHandler(ACTIONS.BRUSH, "dolongaction"),
    ActionHandler(ACTIONS.ABANDON, "dolongaction"),
    ActionHandler(ACTIONS.PET, "dolongaction"),
    ActionHandler(ACTIONS.DRAW, "dolongaction"),
    ActionHandler(ACTIONS.BUNDLE, "bundle"),
    ActionHandler(ACTIONS.RAISE_SAIL, "dostandingaction" ),
    ActionHandler(ACTIONS.LOWER_SAIL_BOOST,
        function(inst, action)
            inst.sg.statemem.not_interrupted = true
            return "furl_boost"
        end),
    ActionHandler(ACTIONS.LOWER_SAIL_FAIL,
        function(inst, action)
            inst.sg.statemem.not_interrupted = true
            return "furl_fail"
        end),
    ActionHandler(ACTIONS.RAISE_ANCHOR, "raiseanchor"),
    ActionHandler(ACTIONS.LOWER_ANCHOR, "doshortaction"),
    ActionHandler(ACTIONS.REPAIR_LEAK, "dolongaction"),
    ActionHandler(ACTIONS.STEER_BOAT, "steer_boat_idle_pre"),
    ActionHandler(ACTIONS.SET_HEADING, "steer_boat_turning"),
    ActionHandler(ACTIONS.ROTATE_BOAT_CLOCKWISE, "doshortaction"),
    ActionHandler(ACTIONS.ROTATE_BOAT_COUNTERCLOCKWISE, "doshortaction"),
    ActionHandler(ACTIONS.ROTATE_BOAT_STOP, "doshortaction"),
    ActionHandler(ACTIONS.BOAT_MAGNET_ACTIVATE, "doshortaction"),
    ActionHandler(ACTIONS.BOAT_MAGNET_DEACTIVATE, "doshortaction"),
    ActionHandler(ACTIONS.BOAT_MAGNET_BEACON_TURN_ON, "doshortaction"),
    ActionHandler(ACTIONS.BOAT_MAGNET_BEACON_TURN_OFF, "doshortaction"),
    ActionHandler(ACTIONS.ROW_FAIL, "row_fail"),
    ActionHandler(ACTIONS.ROW, "row"),
    ActionHandler(ACTIONS.ROW_CONTROLLER, "row"),
    ActionHandler(ACTIONS.EXTEND_PLANK, "doshortaction"),
    ActionHandler(ACTIONS.RETRACT_PLANK, "doshortaction"),
    ActionHandler(ACTIONS.ABANDON_SHIP, "abandon_ship_pre"),
    ActionHandler(ACTIONS.MOUNT_PLANK, "mount_plank"),
    ActionHandler(ACTIONS.DISMOUNT_PLANK, "doshortaction"),
    ActionHandler(ACTIONS.CAST_NET, "cast_net"),
    ActionHandler(ACTIONS.BOAT_CANNON_LOAD_AMMO, "doshortaction"),
    ActionHandler(ACTIONS.BOAT_CANNON_START_AIMING, "aim_cannon_pre"),
    ActionHandler(ACTIONS.BOAT_CANNON_SHOOT,
        function(inst)
            inst.sg.statemem.aiming = true
            return "shoot_cannon"
        end),
    ActionHandler(ACTIONS.OCEAN_TRAWLER_LOWER, "doshortaction"),
    ActionHandler(ACTIONS.OCEAN_TRAWLER_RAISE, "doshortaction"),
    ActionHandler(ACTIONS.OCEAN_TRAWLER_FIX, "dolongaction"),

    ActionHandler(ACTIONS.UNWRAP,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.BREAK, "dolongaction"),
    ActionHandler(ACTIONS.CONSTRUCT,
        function(inst, action)
            return (action.target == nil or action.target.components.constructionsite == nil) and "startconstruct" or "construct"
        end),
    ActionHandler(ACTIONS.STARTCHANNELING, function(inst,action)
        if action.target and action.target.components.channelable and action.target.components.channelable.use_channel_longaction then
                return "channel_longaction"
            else
                return "startchanneling"
            end
        end),
    ActionHandler(ACTIONS.REVIVE_CORPSE, "revivecorpse"),
    ActionHandler(ACTIONS.DISMANTLE, "dolongaction"),
    ActionHandler(ACTIONS.TACKLE, "tackle_pre"),
    ActionHandler(ACTIONS.HALLOWEENMOONMUTATE, "give"),

    --Quagmire
    ActionHandler(ACTIONS.TILL, "till_start"),
    ActionHandler(ACTIONS.PLANTSOIL,
        function(inst, action)
            return (inst:HasTag("quagmire_farmhand") and "doshortaction")
                or (inst:HasTag("quagmire_fasthands") and "domediumaction")
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.INSTALL,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.TAPTREE,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.SLAUGHTER,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.REPLATE,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.SALT,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.BATHBOMB, "doshortaction"),
    ActionHandler(ACTIONS.APPLYPRESERVATIVE, "doshortaction"),
    ActionHandler(ACTIONS.COMPARE_WEIGHABLE, "give"),
    ActionHandler(ACTIONS.WEIGH_ITEM, "use_pocket_scale"),
    ActionHandler(ACTIONS.GIVE_TACKLESKETCH, "give"),
    ActionHandler(ACTIONS.REMOVE_FROM_TROPHYSCALE, "dolongaction"),
    ActionHandler(ACTIONS.CYCLE, "give"),
    ActionHandler(ACTIONS.OCEAN_TOSS, "throw"),

    ActionHandler(ACTIONS.WINTERSFEAST_FEAST,
        function(inst, action)
            if not inst.sg:HasStateTag("feasting") then
                TheWorld:PushEvent("feasterstarted",{player=inst,target=action.target})
            end
            return "winters_feast_eat"
        end),

    ActionHandler(ACTIONS.START_CARRAT_RACE, "give"),

    ActionHandler(ACTIONS.BEGIN_QUEST, "doshortaction"),
    ActionHandler(ACTIONS.ABANDON_QUEST, "dolongaction"),

    ActionHandler(ACTIONS.TELLSTORY, "dostorytelling"),

    ActionHandler(ACTIONS.POUR_WATER,
        function(inst, action)
            return action.invobject ~= nil
                and (action.invobject:HasTag("wateringcan") and "pour")
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.POUR_WATER_GROUNDTILE,
        function(inst, action)
            return action.invobject ~= nil
                and (action.invobject:HasTag("wateringcan") and "pour")
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.INTERACT_WITH,
        function(inst, action)
            return inst:HasTag("plantkin") and "domediumaction" or
                   action.target:HasTag("yotb_stage") and "doshortaction" or
                   "dolongaction"
        end),
    ActionHandler(ACTIONS.PLANTREGISTRY_RESEARCH_FAIL, "dolongaction"),
    ActionHandler(ACTIONS.PLANTREGISTRY_RESEARCH, "dolongaction"),
    ActionHandler(ACTIONS.ASSESSPLANTHAPPINESS, "dolongaction"),
    ActionHandler(ACTIONS.ADDCOMPOSTABLE, "give"),
    ActionHandler(ACTIONS.WAX, "dolongaction"),

    ActionHandler(ACTIONS.USEITEMON, function(inst, action)
        if action.invobject == nil then
            return "dolongaction"
        elseif action.invobject:HasTag("bell") then
            return "use_beef_bell"
        else
            return "dolongaction"
        end
    end),
    ActionHandler(ACTIONS.STOPUSINGITEM, "dolongaction"),
    ActionHandler(ACTIONS.YOTB_STARTCONTEST, "doshortaction"),
    ActionHandler(ACTIONS.YOTB_UNLOCKSKIN, "dolongaction"),
    ActionHandler(ACTIONS.YOTB_SEW, "dolongaction"),
    ActionHandler(ACTIONS.CARNIVAL_HOST_SUMMON, "give"),

    ActionHandler(ACTIONS.MUTATE_SPIDER, "give"),

    ActionHandler(ACTIONS.HERD_FOLLOWERS, "herd_followers"),
    ActionHandler(ACTIONS.BEDAZZLE, "dolongaction"),
    ActionHandler(ACTIONS.REPEL, "repel_followers"),
    ActionHandler(ACTIONS.UNLOAD_WINCH, "give"),
    ActionHandler(ACTIONS.USE_HEAVY_OBSTACLE, "dolongaction"),
    ActionHandler(ACTIONS.ADVANCE_TREE_GROWTH, "dolongaction"),

    ActionHandler(ACTIONS.HIDEANSEEK_FIND, "dolongaction"),
    ActionHandler(ACTIONS.RETURN_FOLLOWER, "dolongaction"),

    ActionHandler(ACTIONS.DISMANTLE_POCKETWATCH, "dolongaction"),

    ActionHandler(ACTIONS.UNLOAD_GYM, "doshortaction"),

    ActionHandler(ACTIONS.LIFT_DUMBBELL, function(inst, action)
        if inst.components.dumbbelllifter:IsLifting(action.invobject) then
            return "use_dumbbell_pst"
        else
            return "use_dumbbell_pre"
        end
    end),

    ActionHandler(ACTIONS.APPLYMODULE, "applyupgrademodule"),
    ActionHandler(ACTIONS.APPLYMODULE_FAIL, "applyupgrademodule_fail"),
    ActionHandler(ACTIONS.REMOVEMODULES, "removeupgrademodules"),
    ActionHandler(ACTIONS.REMOVEMODULES_FAIL, "removeupgrademodules_fail"),
    ActionHandler(ACTIONS.CHARGE_FROM, "doshortaction"),

    ActionHandler(ACTIONS.ROTATE_FENCE, "doswipeaction"),
    ActionHandler(ACTIONS.CHARGE_UP, "charge"),
}

-- Copied from SGwilson
local function UpdateActionMeter(inst, starttime)
    inst.player_classified.actionmeter:set_local(math.min(255, math.floor((GetTime() - starttime) * 10 + 2.5)))
end

local function StartActionMeter(inst, duration)
    if inst.HUD ~= nil then
        inst.HUD:ShowRingMeter(inst:GetPosition(), duration)
    end
    inst.player_classified.actionmetertime:set(math.min(255, math.floor(duration * 10 + .5)))
    inst.player_classified.actionmeter:set(2)
    if inst.sg.mem.actionmetertask == nil then
        inst.sg.mem.actionmetertask = inst:DoPeriodicTask(.1, UpdateActionMeter, nil, GetTime())
    end
end

local function StopActionMeter(inst, flash)
    if inst.HUD ~= nil then
        inst.HUD:HideRingMeter(flash)
    end
    if inst.sg.mem.actionmetertask ~= nil then
        inst.sg.mem.actionmetertask:Cancel()
        inst.sg.mem.actionmetertask = nil
        inst.player_classified.actionmeter:set(flash and 1 or 0)
    end
end

local function shoot(inst)
	print("DS - Inside Shooting function")
    if inst.fullcharge then
		print("Full charge, do big ball?")
        -- local player = GetPlayer()
        local player = inst
        local rotation = player.Transform:GetRotation()
        local beam = SpawnPrefab("ancient_hulk_orb")
        beam.components.complexprojectile.yOffset = 1
        local pt = Vector3(player.Transform:GetWorldPosition())
        local angle = rotation * DEGREES
        local radius = 2.5
        local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin( angle ))
        local newpt = pt+offset

        beam.Transform:SetPosition(newpt.x,newpt.y,newpt.z)
        beam.host = player
        beam.AnimState:PlayAnimation("spin_loop",true)

        local targetpos = TheInput:GetWorldPosition()
        local controller_mode = TheInput:ControllerAttached()
        if controller_mode then
            targetpos = Vector3(player.livingartifact.components.reticule.reticule.Transform:GetWorldPosition())     
        end  
    
        local speed =  60 --  easing.linear(rangesq, 15, 3, maxrange * maxrange)
        beam.components.complexprojectile:SetHorizontalSpeed(speed)
        beam.components.complexprojectile:SetGravity(-1)
        beam.components.complexprojectile:Launch(targetpos, player)
        beam.components.combat.proxy = inst
        beam.owner = inst    
    else
		print("Not full charge, small ball it is!")
        -- local player = GetPlayer()
        local player = inst
        local rotation = player.Transform:GetRotation()
        local beam = SpawnPrefab("ancient_hulk_orb_small")
        local pt = Vector3(player.Transform:GetWorldPosition())
        local angle = rotation * DEGREES
        local radius = 2.5
        local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin( angle ))
        local newpt = pt+offset

        beam.Transform:SetPosition(newpt.x,1,newpt.z)
        beam.host = player
        beam.Transform:SetRotation(rotation)
        beam.AnimState:PlayAnimation("spin_loop",true) 
        beam.components.combat.proxy = inst
    end
	print("Either ball should have fired by now")
end

local events=
{
    CommonHandlers.OnLocomote(true,false),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    EventHandler("transform_person", function(inst) inst.sg:GoToState("revert") end),
    EventHandler("freeze", 
        function(inst)
            if inst.components.health and inst.components.health:GetPercent() > 0 then
                inst.sg:GoToState("frozen")
            end
        end),    
    EventHandler("beginchargeup", 
        function(inst) 
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("charge")
            end
        end),
    EventHandler("rightbuttonup", 
        function(inst) 
            --if inst.sg:HasStateTag("waitforbutton") then
                inst.rightbuttonup = true
                inst.rightbuttondown = nil
                print("UP")
            --end
        end),   
    EventHandler("rightbuttondown", 
        function(inst) 
            --if inst.sg:HasStateTag("waitforbutton") then
                inst.rightbuttonup = nil
                inst.rightbuttondown = true
                print("DOWN")
           -- end
        end),   
    EventHandler("ontalk", function(inst, data)
        if inst.sg:HasStateTag("idle") then
            if inst.prefab == "wes" then
                inst.sg:GoToState("mime")
            else
                inst.sg:GoToState("talk", data.noanim)
            end
        end
        
    end),                 
}

local states=
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            local anim = "idle_loop"
               
            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation(anim, true)
            else
                inst.AnimState:PlayAnimation(anim, true)
            end

            if inst.rightbuttondown then
                inst.sg:GoToState("charge")    
            end
        end,
        
       events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")                                    
            end),
        }, 
    },

    State {
        name = "morph",
        tags = {"busy"},
        onenter = function(inst)

            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("morph_idle")
            inst.AnimState:PushAnimation("morph_complete",false)            
        end,
        
        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/music/iron_lord")
            end),
            TimeEvent(15*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/morph")
            end),
            TimeEvent(105*FRAMES, function(inst) 
                -- inst.components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, .5, 40)
				
				-- I don't understand all this math. It seems to be attenuating the intensity of the shake based on distance.
				-- Copied from lightning.lua
				for i, v in ipairs(AllPlayers) do
					local distSq = v:GetDistanceSqToInst(inst)
					local k = math.max(0, math.min(1, distSq / LIGHTNING_MAX_DIST_SQ))
					local intensity = -(k-1)*(k-1)*(k-1)				--k * 0.8 * (k - 2) + 0.8

					--print("StartFX", k, intensity)
					if intensity > 0 then
						-- v:ScreenFlash(intensity <= 0.05 and 0.05 or intensity)
						v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 3)
					end
				end
            end),

            TimeEvent(105*FRAMES, function(inst) 
                inst.AnimState:Hide("beard")
            end),

            TimeEvent(152*FRAMES, function(inst) 
                -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/music/iron_lord_suit", "ironlord_music") -- DS - Need to move this to after the seamless swap, otherwise it stops
            end),
        },

        
        onexit = function(inst)
            -- inst.livingartifact.BecomeIronLord_post(inst.livingartifact)
            inst.BecomeIronLord_post(inst)
        end,

        events=
        {
            EventHandler("animqueueover", function(inst) 
                inst.sg:GoToState("idle")                                    
            end),
        },         
    },

    State{
        name = "revert",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()            
            inst.AnimState:PlayAnimation("death")
            inst.sg:SetTimeout(3)
            --inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/death_beaver")
            inst.components.beaverness.doing_transform = true
        end,

        -- timeline =
        -- {
        --     TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams ("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intesity= .2}) end),
        --     TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intesity= .4}) end),
        --     TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intesity= .6}) end),
        --     TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intesity= 1}) end),
        --     TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/explosion") end),
        -- },
        
        ontimeout = function(inst) 
            TheFrontEnd:Fade(false,2)
            inst:DoTaskInTime(2, function() 
                
                -- GetClock():MakeNextDay()
                
                inst.components.beaverness.makeperson(inst)
                inst.components.sanity:SetPercent(.25)
                inst.components.health:SetPercent(.33)
                inst.components.hunger:SetPercent(.25)
                inst.components.beaverness.doing_transform = false
                inst.sg:GoToState("wakeup")
                TheFrontEnd:Fade(true,1)
            end)
        end
    },

    State{
        name = "transform_pst",
        tags = {"busy"},
        onenter = function(inst)
			inst.components.playercontroller:Enable(false)
            inst.Physics:Stop()            
            inst.AnimState:PlayAnimation("transform_pst")
            inst.components.health:SetInvincible(true)
            if TUNING.DO_SEA_DAMAGE_TO_BOAT and (inst.components.driver and inst.components.driver.vehicle and inst.components.driver.vehicle.components.boathealth) then
                inst.components.driver.vehicle.components.boathealth:SetInvincible(true)
            end
        end,
        
        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            if TUNING.DO_SEA_DAMAGE_TO_BOAT and (inst.components.driver and inst.components.driver.vehicle and inst.components.driver.vehicle.components.boathealth) then
                inst.components.driver.vehicle.components.boathealth:SetInvincible(false)
            end
            inst.components.playercontroller:Enable(true)
        end,
        
        events=
        {
            EventHandler("animover", function(inst)
				-- TheCamera:SetDistance(30)
				inst.sg:GoToState("idle")
			end ),
        },        
    },    

    State{
        name = "work",
        tags = {"busy", "working"},
        
        onenter = function(inst)
            inst.Physics:Stop()            
            inst.AnimState:PlayAnimation("power_punch")
            inst.sg.statemem.action = inst:GetBufferedAction()
        end,
        
        timeline=
        {
            TimeEvent(8*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/punch",nil,.5)
            end),
            TimeEvent(6*FRAMES, function(inst) inst:PerformBufferedAction() end),
            TimeEvent(14*FRAMES, function(inst) inst.sg:RemoveStateTag("working") inst.sg:RemoveStateTag("busy") inst.sg:AddStateTag("idle") end),
            TimeEvent(15*FRAMES, function(inst)
                if (TheInput:IsMouseDown(MOUSEBUTTON_LEFT) or
                   TheInput:IsKeyDown(KEY_SPACE)) and 
                    inst.sg.statemem.action and 
                    inst.sg.statemem.action:IsValid() and 
                    inst.sg.statemem.action.target and 
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and 
                    (inst.sg.statemem.action.target.components.workable or inst.sg.statemem.action.target.components.hackable) then
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),            

        },
    },

    State{
        name = "frozen",
        tags = {"busy", "frozen"},
        
        onenter = function(inst)
            inst.components.playercontroller:Enable(false)

            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("frozen")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
        end,
        
        onexit = function(inst)
            inst.components.playercontroller:Enable(true)

            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
        
        events=
        {   
            EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),        
        },
    },

    State{
        name = "usedoor",
        tags = {"doing", "canrotate"},
        
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.components.locomotor:Stop()
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle") 
        end,
    },

    State{
        name = "charge",
        tags = {"busy", "doing", "waitforbutton"},
        
        onenter = function(inst)            
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("charge_pre")
            inst.AnimState:PushAnimation("charge_grow")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/charge_up_LP", "chargedup")    
        end,
        onexit = function(inst)
			-- local pc = ThePlayer.components.playercontroller
            -- inst.rightbuttonup = nil
            inst.components.playercontroller.RMBaction = nil
            inst:ClearBufferedAction()
            inst.shoot=nil
            inst.readytoshoot = nil
        end,
        onupdate = function(inst)        
            -- if inst.rightbuttonup then
                -- inst.rightbuttonup = nil
				-- print("DS - RMBAction is ", inst.components.playercontroller.RMBaction)
            -- if inst.components.playercontroller.RMBaction == nil then
                -- inst.components.playercontroller.RMBaction = nil
			print("DS - buffered action is ", inst.bufferedaction)
			if inst.bufferedaction == nil then
                inst.shoot = true          
			-- else
				-- print("DS - RMBAction is ", inst.components.playercontroller.RMBaction)
            end
            if inst.shoot and inst.readytoshoot then
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/smallshot", {timeoffset=math.random()})
                inst.SoundEmitter:KillSound("chargedup")
                inst.sg:GoToState("shoot")
            end

            local controller_mode = TheInput:ControllerAttached()
            if controller_mode then
                local reticulepos = Vector3(inst.livingartifact.components.reticule.reticule.Transform:GetWorldPosition())
                -- inst:ForceFacePoint(reticulepos)        
            else
                -- local mousepos = TheInput:GetWorldPosition()             
                -- inst:ForceFacePoint(mousepos)      
				-- local buffaction = inst:GetBufferedAction()
				-- local facepos = buffaction:GetActionPoint():Get()		
				-- print("DS - Face pos should be ", facepos)
                -- inst:ForceFacePoint(facepos)          
            end  
        end,        
        timeline=
        {
            TimeEvent(15*FRAMES, function(inst) inst.readytoshoot = true end),
            TimeEvent(20*FRAMES, function(inst) inst.sg:GoToState("chagefull") end),            
        },        
    },

    State{
        name = "chagefull",
        tags = {"busy", "doing","waitforbutton"},
        
        onenter = function(inst)           
            -- inst.rightbuttonup = nil   
            inst.components.playercontroller.RMBaction = nil 
            inst.components.locomotor:Stop()
            
            inst.AnimState:PlayAnimation("charge_super_pre")
            inst.AnimState:PushAnimation("charge_super_loop",true)
            inst.fullcharge = true

            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/electro")
            
        end,        

        onexit = function(inst)
            -- inst.rightbuttonup = nil
            inst.components.playercontroller.RMBaction = nil
            inst:ClearBufferedAction()     
            if not inst.shooting then
                inst.fullcharge = nil
            end
            inst.shoot = nil
            inst.shooting = nil
            inst.SoundEmitter:KillSound("chargedup")
        end,

        onupdate = function(inst)
            -- if inst.components.playercontroller.RMBaction == nil then
                -- inst.components.playercontroller.RMBaction = nil
			-- if inst.bufferedaction == nil then -- This was uncommented before the bottom rightbuttonup line
            -- if inst.rightbuttonup then
                -- inst.rightbuttonup = nil
                inst.shoot = true 
            -- end

			-- Hacking it because I want to see this thing shoot at all
            -- if inst.shoot and inst.readytoshoot then
            if inst.shoot then --and inst.readytoshoot then
                inst.shooting = true
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser",  {intensity = math.random(0.7, 1)})---jason can i use a random number from .7 to 1 instead of a static number (.8)?

				print("DS - Firing the ball thing!")
                inst.sg:GoToState("shoot")
            end

            local controller_mode = TheInput:ControllerAttached()
            if controller_mode then
                local reticulepos = Vector3(inst.livingartifact.components.reticule.reticule.Transform:GetWorldPosition())
                -- inst:ForceFacePoint(reticulepos)        
            else
                -- local mousepos = TheInput:GetWorldPosition()     
                -- inst:ForceFacePoint(mousepos)        		
				-- local buffaction = inst:GetBufferedAction()
				-- local facepos = buffaction:GetActionPoint():Get()				
				-- print("DS - Face pos should be ", facepos)
                -- inst:ForceFacePoint(facepos)        
            end    
        end,  
        timeline=
        {
            TimeEvent(5*FRAMES, function(inst) inst.readytoshoot = true end),      
        },  
    },    

    State{
        name = "shoot",
        tags = {"busy"},
        
        onenter = function(inst)       
            inst.components.locomotor:Stop()
			-- shoot(inst) -- Testing random stuff, I dunno
			inst.Shoot(inst, inst.fullcharge) -- Still testing, trying to make the ball appear and do something. Why it isn't already, I'm not sure
            if inst.fullcharge then
                inst.AnimState:PlayAnimation("charge_super_pst")
            else
                inst.AnimState:PlayAnimation("charge_pst")
            end
        end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) shoot(inst)  end),   
            TimeEvent(5*FRAMES, function(inst) inst.sg:RemoveStateTag("busy")  end),   
            
        }, 
        
        onexit = function(inst)
            inst.fullcharge = nil   
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },             
    },

    State{
        name = "explode",
        tags = {"busy"},
        
        onenter = function(inst)     
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("suit_destruct")            
        end,
        
        timeline=
        {   ---- death explosion
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intensity= .2}) end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intensity= .4}) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intensity= .6}) end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/small_explosion", {intensity= 1}) end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/electro",nil,.5) end),
            TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/electro",nil,.5) end),
            TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/explosion") end),
            
            TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:KillSound("ironlord_music") end), --- jason i put the music here and commented out the living_artifact.lua lines                           
            
            TimeEvent(52*FRAMES, function(inst) 
                local explosion = SpawnPrefab("living_suit_explode_fx")
                explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())  
                -- inst.livingartifact.DoDamage(inst.livingartifact, 5)
                inst.DoDamage(inst, 5)
            end),
        }, 
        
        onexit = function(inst)
             -- inst.livingartifact.Revert(inst.livingartifact)
             inst.Revert(inst)
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },             
    },        
	State{
        name = "power_punch",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
            end
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = inst.components.combat.min_attack_period + .5 * FRAMES


            -- inst.sg:SetTimeout(cooldown)
            -- inst.sg:SetTimeout(cooldown)

            if target ~= nil then
                inst.components.combat:BattleCry()
                if target:IsValid() then
                    inst:FacePoint(target:GetPosition())
                    inst.sg.statemem.attacktarget = target
                    inst.sg.statemem.retarget = target
                end
            end
        end,

        timeline =
        {
			TimeEvent(0*FRAMES, function(inst) 
					inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/punch_pre") 
					inst.AnimState:PlayAnimation("power_punch")
				end),
			TimeEvent(8*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/punch") end),
			TimeEvent(6*FRAMES, function(inst) 
				print("Attack part thing go, please hurt something")
				-- local buffaction = inst:GetBufferedAction()
				-- local target = buffaction ~= nil and buffaction.target or nil
				-- inst.components.combat:DoAttack(inst.sg.statemem.target) 
				-- inst.components.combat:SetTarget(target)
				-- inst.components.combat:StartAttack()
				inst.components.combat:DoAttack()
			end),
			TimeEvent(7*FRAMES, function(inst)
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:AddStateTag("idle")
			end),
        },


        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },
}

CommonStates.AddCombatStates(states,
{
    ---- 
    hittimeline =
    {
        -- TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/hit") end),
    },
    
    attacktimeline = 
    {
    
        TimeEvent(0*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/punch_pre") end),
        TimeEvent(8*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/punch") end),
        TimeEvent(6*FRAMES, function(inst) 
			print("Attack part thing go, please hurt something")
			-- local buffaction = inst:GetBufferedAction()
            -- local target = buffaction ~= nil and buffaction.target or nil
			-- inst.components.combat:DoAttack(inst.sg.statemem.target) 
			-- inst.components.combat:SetTarget(target)
			-- inst.components.combat:StartAttack()
			inst.components.combat:DoAttack()
		end),
        TimeEvent(7*FRAMES, function(inst)
			inst.sg:RemoveStateTag("attack")
			inst.sg:RemoveStateTag("busy")
			inst.sg:AddStateTag("idle")
		end),
    },

    deathtimeline=
    {
    },
},
{attack="power_punch"}
)

CommonStates.AddRunStates(states,
{
	runtimeline = {
		TimeEvent(0*FRAMES, PlayFootstep ),
		TimeEvent(10*FRAMES, PlayFootstep ),
	},
})

CommonStates.AddFrozenStates(states)

return StateGraph("ironlord", states, events, "idle", actionhandlers)
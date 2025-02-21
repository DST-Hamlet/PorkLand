local AddAction = AddAction
local AddComponentAction = AddComponentAction
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

if not rawget(_G, "HotReloading") then
    _G.PL_ACTIONS = {
        HACK = Action({mindistance = 1.75, silent_fail = true}),
        SHEAR = Action({distance = 1.75}),
        PAN = Action({distance = 1}),
        PANGOLDEN_DRINK = Action({distance = 1.2}),
        PANGOLDEN_POOP = Action({distance = 1.2}),
        PEAGAWK_TRANSFORM = Action({}),
        DIGDUNG = Action({mount_valid = true}),
        MOUNTDUNG = Action({}),
        CUREPOISON = Action({mount_valid = true}),
        EMBARK = Action({priority = 1, distance = 6}),
        DISEMBARK = Action({priority = 1, distance = 2.5, invalid_hold_action = true}),
        RETRIEVE = Action({priority = 1, distance = 3}),
        TOGGLEON = Action({priority = 2, mount_valid = true}),
        TOGGLEOFF = Action({priority = 2, mount_valid = true}),
        REPAIRBOAT = Action({distance = 3}),
        DISLODGE = Action({}),
        USEDOOR = Action({priority = 1, mount_valid = true, ghost_valid = true, encumbered_valid = true}),
        VAMPIREBAT_FLYAWAY = Action({distance = 1}),
        WEIGHDOWN = Action({distance = 1.5}),
        DISARM = Action({priority = 1, distance = 1.5}),
        REARM = Action({priority = 1, distance = 1.5}),
        SPY = Action({distance = 2, mount_enabled = true}),
        PUTONSHELF = Action({ distance = 1.5 }),
        TAKEFROMSHELF = Action({ distance = 1.5, priority = 1 }),
        ASSEMBLE_ROBOT = Action({}),
        CHARGE_UP = Action({priority = 2, rmb = true, distance = 36}),
        CHARGE_RELEASE = Action({priority = 2, rmb = true, distance = 36}),
        USE_LIVING_ARTIFACT = Action({priority = 2, invalid_hold_action = true, mount_enabled = false, rmb = true}),
        BARK = Action({distance = 3}),
        RANSACK = Action({distance = 0.5}),
        MAKEHOME = Action({distance = 1}),
        THUNDERBIRD_CAST = Action({distance = 1.2}),
        GAS = Action({distance = 2.5, mount_enabled = true}),
        INFEST = Action({distance = 0.5}),
        BUILD_MOUND = Action({}),

        -- For City Pigs
        POOP_TIP = Action({distance = 1.2}), -- Replacing SPECIAL_ACTION
        PAY_TAX = Action({distance = 1.2}), -- Replacing SPECIAL_ACTION
        DAILY_GIFT = Action({distance = 1.2}), -- Replacing SPECIAL_ACTION
        SIT_AT_DESK = Action({distance = 1.2}), -- Replacing SPECIAL_ACTION
        FIX = Action({distance = 2}), -- for pigs reparing broken pig town structures
        STOCK = Action({}),
        PIG_BANDIT_EXIT = Action({}),

        SHOP = Action({ distance = 1.5 }),
        RENOVATE = Action({}),
        BUILD_ROOM = Action({}),
        DEMOLISH_ROOM = Action({}),

        SEARCH_MYSTERY = Action({priority = -1, distance = 1}),

        THROW = Action({priority = 0, instant = false, rmb = true, distance = 20, mount_valid = true}),

        DODGE = Action({priority = -5, instant = false, distance = math.huge}),
    }

    for name, ACTION in pairs(_G.PL_ACTIONS) do
        ACTION.id = name
        ACTION.str = STRINGS.ACTIONS[name] or name
        AddAction(ACTION)
    end
end

----set up the action functions
local _ValidToolWork = ToolUtil.GetUpvalue(ACTIONS.CHOP.validfn, "ValidToolWork")
local _DoToolWork = ToolUtil.GetUpvalue(ACTIONS.CHOP.fn, "DoToolWork")
local function DoToolWork(act, workaction, ...)
    if act.doer and act.doer.player_classified then
        act.doer.player_classified._last_work_target:set(act.target)
        act.doer.player_classified:ClearLastTarget()
    end
    if workaction == ACTIONS.HACK and act.target.components.hackable ~= nil and act.target.components.hackable:CanBeWorked() then
        if act.invobject and act.invobject.components.obsidiantool then
            act.invobject.components.obsidiantool:Use(act.doer, act.target)
        end
        act.target.components.hackable:WorkedBy(act.doer,
            (
                (act.invobject ~= nil and act.invobject.components.tool ~= nil and act.invobject.components.tool:GetEffectiveness(workaction)) or
                (act.doer ~= nil and act.doer.components.worker ~= nil and act.doer.components.worker:GetEffectiveness(workaction)) or
                1
            ) *
            (
                act.doer.components.workmultiplier ~= nil and
                act.doer.components.workmultiplier:GetMultiplier(workaction) or
                1
            )
        )
        return true
    elseif act.target.components.workable ~= nil and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == workaction then
        if act.invobject and act.invobject.components.obsidiantool then
            act.invobject.components.obsidiantool:Use(act.doer, act.target)
        end
    end
    return _DoToolWork(act, workaction, ...)
end
ToolUtil.SetUpvalue(ACTIONS.CHOP.fn, DoToolWork, "DoToolWork")

ACTIONS.HACK.fn = function(act)
    DoToolWork(act, ACTIONS.HACK)
    return true
end

ACTIONS.HACK.validfn = function(act) -- this fixes hacking a nonvalid target when holding the mouse
    return (act.target.components.hackable and act.target.components.hackable:CanBeWorked())
        or (act.target.components.workable and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == ACTIONS.HACK)
end

ACTIONS.PAN.fn = function(act)
    DoToolWork(act, ACTIONS.PAN)
    return true
end

ACTIONS.PAN.validfn = function(act)
    return _ValidToolWork(act, ACTIONS.PAN)
end

ACTIONS.SHEAR.fn = function(act)
    if act.target and act.target.components.shearable then
        act.target.components.shearable:Shear(act.doer)
        return true
    end
end

ACTIONS.SHEAR.validfn = function(act)
    return (act.target.components.shearable and act.target.components.shearable:CanShear())
        or (act.target.components.workable and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == ACTIONS.SHEAR)
end

ACTIONS.PEAGAWK_TRANSFORM.fn = function(act)
    return true -- Dummy action for flup hiding
end

ACTIONS.PANGOLDEN_DRINK.fn = function(act)
    if act.target and act.target.components.workable and act.target.components.workable:CanBeWorked() then
        act.target:Shrink()
        act.doer:OnDrunk()
        return true
    end

    return false
end

ACTIONS.PANGOLDEN_POOP.fn = function(act)
    local x, y, z = act.doer.Transform:GetWorldPosition()
    SpawnPrefab("goldnugget").Transform:SetPosition(x, y, z)
    return true
end

ACTIONS.FISH.strfn = function(act)
    if act.target and (act.target:HasTag("sink") or act.target:HasTag("sunkencontainer")) then
        return "RETRIEVE"
    else
        return "GENERIC"
    end
end

ACTIONS.DIGDUNG.fn = function(act)
    act.target.components.workable:WorkedBy(act.doer, 1)
    return true
end

ACTIONS.DIGDUNG.validfn = function(act)
    if act.doer and act.target and act.doer:IsValid() and act.target:IsValid() then
        return not act.doer:HasTag("hasdung") and act.target:HasTag("dungpile")
    end
end

ACTIONS.MOUNTDUNG.fn = function(act)
    if act.doer and act.target and act.doer:IsValid() and act.target:IsValid() then
        act.target:Remove()
        act.doer:AddTag("hasdung")
        return true
    end
end

ACTIONS.MOUNTDUNG.validfn = function(act)
    if act.doer and act.target and act.doer:IsValid() and act.target:IsValid() then
        return not act.doer:HasTag("hasdung") and act.target:HasTag("dungball")
    end
end

ACTIONS.CUREPOISON.strfn = function(act)
    if act.invobject and act.invobject:HasTag("venomgland") then
        return "GLAND"
    end
end

ACTIONS.CUREPOISON.fn = function(act)
    if act.invobject and act.invobject.components.poisonhealer then
        local target = act.target or act.doer
        return act.invobject.components.poisonhealer:Cure(target)
    end
end

ACTIONS.EMBARK.strfn = function(act)
    local obj = act.target
    if obj:HasTag("surfboard") then
        return "SURF"
    end
end

ACTIONS.EMBARK.fn = function(act)
    if act.target and act.target.components.sailable and act.target.components.sailable.sailor == nil then
        act.doer.components.sailor:Embark(act.target)
        return true
    end
end

ACTIONS.DISEMBARK.fn = function(act)
    if act.doer.components.sailor then
        if act.doer.components.sailor:IsSailing() then
            local pos = act.GetActionPoint and act:GetActionPoint() or act.pos
            act.doer.components.sailor:Disembark(pos)
            return true
        end
    end
end

ACTIONS.RETRIEVE.fn = function(act)
    if act.doer.components.inventory and act.target and act.target.components.pickupable and not act.target:IsInLimbo() then
        act.doer:PushEvent("onpickup", {item = act.target})
        return act.target.components.pickupable:OnPickup(act.doer)
    end
    return ACTIONS.PICKUP.fn(act)
end

ACTIONS.TOGGLEON.fn = function(act)
    local tar = act.target or act.invobject
    if tar and tar.components.equippable and tar.components.equippable:IsEquipped() and tar.components.equippable.togglable and not tar.components.equippable:IsToggledOn() then
        tar.components.equippable:ToggleOn()
        return true
    end
end

ACTIONS.TOGGLEOFF.fn = function(act)
    local tar = act.target or act.invobject
    if tar and tar.components.equippable and tar.components.equippable:IsEquipped() and tar.components.equippable.togglable and tar.components.equippable:IsToggledOn() then
        tar.components.equippable:ToggleOff()
        return true
    end
end

ACTIONS.REPAIRBOAT.fn = function(act)
    if act.target and act.target ~= act.invobject and act.target.components.repairable and act.invobject and act.invobject.components.repairer then
        return act.target.components.repairable:Repair(act.doer, act.invobject)
    elseif act.doer.components.sailor and act.doer.components.sailor.boat and act.doer.components.sailor.boat.components.repairable and act.invobject and act.invobject.components.repairer then
        return act.doer.components.sailor.boat.components.repairable:Repair(act.doer, act.invobject)
    end
end

ACTIONS.DISLODGE.fn = function(act)
    if act.target and act.target.components.dislodgeable then
        act.target.components.dislodgeable:Dislodge(act.doer)
        return true
    end
end

ACTIONS.DISLODGE.validfn = function(act)
    return (act.target.components.dislodgeable and act.target.components.dislodgeable:CanBeDislodged()) or
        (act.target.components.workable and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == ACTIONS.DISLODGE)
end

ACTIONS.DISARM.fn = function(act)
    if act.target and act.target.components.disarmable and act.invobject and act.invobject.components.disarming then
        return act.invobject.components.disarming:DoDisarming(act.target, act.doer)
    end
end

ACTIONS.REARM.fn = function(act)
    if act.target and act.target.components.disarmable and not act.target.components.disarmable.armed and act.target.components.disarmable.rearmable then
        return act.target.components.disarmable:DoRearming(act.target, act.doer)
    end
end

ACTIONS.SPY.fn = function(act)
    if act.target and act.target.components.mystery then
        act.target.components.mystery:Investigate(act.doer)
        return true
    elseif act.target and act.target.components.mystery_door then
        act.target.components.mystery_door:Investigate(act.doer)
        return true
    end
end

ACTIONS.SEARCH_MYSTERY.fn = function(act)
    if act.target and act.target.components.mystery then
        return act.target.components.mystery:SearchTest(act.doer)
    end
end

ACTIONS.SEARCH_MYSTERY.validfn = function(act)
    if act.target then
        return act.target:HasTag("mystery")
    end
end

ACTIONS.USEDOOR.fn = function(act)
    local door = act.target
    if not door or not door.components.door then
        return false
    end
    if door.components.door:IsLocked() then
        return false, "LOCKED"
    end
    return door.components.door:Activate(act.doer)
end

ACTIONS.VAMPIREBAT_FLYAWAY.fn = function(act)
    if not act.target or not act.doer then
        return false
    end
    act.doer:Remove()
    return true
end

ACTIONS.WEIGHDOWN.fn = function(act)
    if act.target == nil then
        return false
    end
    if act.doer.components.inventory then
        return act.doer.components.inventory:DropItem(act.invobject, false, false, act.target:GetPosition())
    end
end

ACTIONS.PUTONSHELF.fn = function(act)
    local shelf = act.target.components.visualslot:GetShelf()

    if shelf.components.container ~= nil and act.invobject.components.inventoryitem ~= nil then
        local item = act.invobject.components.inventoryitem:RemoveFromOwner(shelf.components.container.acceptsstacks)
        local success = shelf.components.container:GiveItem(item, act.target.components.visualslot:GetSlot(), nil, false)
        if item:HasTag("small_livestock") then -- TODO: 需要加一个对容器所属的展示柜的检测，使得生物无法离开带有罩子的展示柜
            if act.doer and item:HasTag("canbetrapped") then -- 鸟类之外的可被抓的生物都有 canbetrapped 标签
                local d_pos = act.doer:GetPosition()
                local s_pos = shelf:GetPosition()
                shelf.components.container:DropItemBySlot(act.target.components.visualslot:GetSlot(), (d_pos + s_pos) / 2)
            else
                shelf.components.container:DropItemBySlot(act.target.components.visualslot:GetSlot(), shelf:GetPosition())
            end
        end
        return success
    end
end

ACTIONS.PUTONSHELF.stroverridefn = function(act)
    return STRINGS.ACTIONS.STORE.GENERIC
end

ACTIONS.TAKEFROMSHELF.fn = function(act)
    local shelf = act.target.components.visualslot:GetShelf()

    if shelf.components.lock and shelf.components.lock:IsLocked() then
        return false
    end

    if shelf.components.container then
        local item = shelf.components.container:RemoveItemBySlot(act.target.components.visualslot:GetSlot())
        act.doer.components.inventory:GiveItem(item, nil, act.doer:GetPosition())

        return true
    end
end

ACTIONS.ASSEMBLE_ROBOT.fn = function(act)
    act.doer.components.mechassembly:Assemble(act.target)
    return true
end

ACTIONS.CHARGE_UP.fn = function(act)
    act.doer:PushEvent("beginchargeup")
    return true
end

ACTIONS.USE_LIVING_ARTIFACT.fn = function(act)
    local target = act.target or act.invobject
    if target and target.components.livingartifact and not target:HasTag("active") then
        target.components.livingartifact:Activate(act.doer, false)
        return true
    end
end

ACTIONS.BARK.fn = function(act)
    return true
end

ACTIONS.RANSACK.fn = function(act)
    return true
end

ACTIONS.MAKEHOME.fn = function(act)
    if act.doer and act.target then
        return act.doer:MakeHomeAction(act.target)
    end
    return false
end

ACTIONS.POOP_TIP.fn = function(act)
    act.target.components.inventory:GiveItem(SpawnPrefab("oinc"), nil, act.doer:GetPosition())
    return true
end

ACTIONS.PAY_TAX.fn = function(act)
    act.doer:RemoveTag("paytax")
    act.doer.taxing = false
    act.target.components.inventory:GiveItem(SpawnPrefab("oinc"), nil, act.doer:GetPosition())
    return true
end

ACTIONS.DAILY_GIFT.fn = function(act)
    local resources = {"flint", "log", "rocks", "cutgrass", "seeds", "twigs"}
    act.target.components.inventory:GiveItem(SpawnPrefab(resources[math.random(#resources)]), nil, act.doer:GetPosition())
    return true
end

ACTIONS.SIT_AT_DESK.fn = function(act)
    return true
end

ACTIONS.FIX.fn = function(act)
    if act.target then
        local target = act.target
        local numworks = 1
        target.components.workable:WorkedBy(act.doer, numworks)
    --    return target:fix(act.doer)
    end
end

ACTIONS.STOCK.fn = function(act)
    if act.target then
        act.target:Restock(true)
        act.doer.changestock = nil
        return true
    end
end

ACTIONS.SHOP.stroverridefn = function(act)
    if not (act.target and act.target:IsValid()) then
        return ""
    end
    local shelf = act.target.replica.visualslot:GetShelf()
    local item = act.target.replica.visualslot:GetItem()
    if not (shelf and item and shelf.replica.shopped) then
        return ""
    end

    if not shelf.replica.shopped:IsBeingWatched() then
        return subfmt(STRINGS.ACTIONS.SHOP_TAKE, { wantitem = item:GetBasicDisplayName() })
    end

    local cost_prefab = shelf.replica.shopped:GetCostPrefab()
    local cost = shelf.replica.shopped:GetCost()
    local payitem = STRINGS.NAMES[string.upper(cost_prefab)]
    local qty = ""
    if cost_prefab == "oinc" then
        qty = cost
        if cost > 1 then
            payitem = STRINGS.NAMES.OINC_PL
        end
    end
    return subfmt(STRINGS.ACTIONS.SHOP_LONG, { wantitem = item:GetBasicDisplayName(), qty = qty, payitem = payitem })
end

ACTIONS.SHOP.fn = function(act)
    local doer = act.doer
    local shelf = act.target.components.visualslot:GetShelf()
    local slot = act.target.components.visualslot:GetSlot()

    if not (shelf and shelf.components.shopped and doer:HasTag("player") and doer.components.inventory and doer.components.shopper) then
        return false
    end

    if shelf.components.lock and shelf.components.lock:IsLocked() then
        return false
    end

    if not shelf.components.shopped:IsBeingWatched() then
        shelf.components.shopped:GetRobbed(doer, slot)
        return true
    end

    local sell = true
    local reason = nil

    if shelf:HasTag("shopclosed") or TheWorld.state.isnight then
        reason = "closed"
        sell = false
    elseif not doer.components.shopper:CanPayFor(shelf, slot) then
        local prefab_wanted = shelf.components.shopped:GetCostPrefab()
        if prefab_wanted == "oinc" then
            reason = "money"
        else
            reason = "goods"
        end
        sell = false
    end

    if sell then
        doer.components.shopper:Buy(shelf, slot)
        if shelf.MakeShopkeeperSpeech then
            shelf:MakeShopkeeperSpeech("CITY_PIG_SHOPKEEPER_SALE")
        end
        return true
    else
        if reason == "money" then
            if shelf.MakeShopkeeperSpeech then
                shelf:MakeShopkeeperSpeech("CITY_PIG_SHOPKEEPER_NOT_ENOUGH")
            end
        elseif reason == "goods" then
            if shelf.MakeShopkeeperSpeech then
                shelf:MakeShopkeeperSpeech("CITY_PIG_SHOPKEEPER_DONT_HAVE")
            end
        elseif reason == "closed" then
            if shelf.MakeShopkeeperSpeech then
                shelf:MakeShopkeeperSpeech("CITY_PIG_SHOPKEEPER_CLOSING")
            end
        end
        return true -- Shouldn't this be false?
    end
end

ACTIONS.GAS.fn = function(act)
    if act.doer and act.invobject and act.invobject.components.gasser then
        local pos = act:GetActionPoint() or (act.target and act.target:GetPosition())
        local doer_pos = act.doer:GetPosition()
        pos.y = doer_pos.y
        pos = doer_pos + (pos - doer_pos):Normalize() * act.action.distance
        act.invobject.components.gasser:Gas(pos)
        return true
    end
end
ACTIONS.INFEST.fn = function(act)
    if not act.doer.components.infester.infested then
        act.doer.components.infester:Infest(act.target)
        return true
    end

    return false
end

ACTIONS.INFEST.validfn = function(act)
    local AGRO_STOP_DIST = 7
    return act.doer:GetDistanceSqToInst(act.target) <= AGRO_STOP_DIST * AGRO_STOP_DIST
end

ACTIONS.BUILD_MOUND.fn = function(act)
    if act.doer.build_mound_action then
        return act.doer:build_mound_action()
    end
end

ACTIONS.THUNDERBIRD_CAST.fn = function(act)
    act.doer.sg:GoToState("thunder_attack")
    return true
end

ACTIONS.PIG_BANDIT_EXIT.fn = function(act)
    return true
end

ACTIONS.RENOVATE.fn = function(act)
    if act.target:HasTag("renovatable") then
        if act.invobject.components.renovator then
            act.invobject.components.renovator:Renovate(act.target)
        end

        act.invobject:Remove()

        return true
    end
end

ACTIONS.BUILD_ROOM.fn = function(act)
    if act.invobject.components.roombuilder and act.target:HasTag("predoor") then
        return act.invobject.components.roombuilder:BuildRoom(act.target, act.invobject)
    end
    return false
end

ACTIONS.DEMOLISH_ROOM.fn = function(act)
    if act.invobject.components.roomdemolisher and act.target:HasTag("house_door") and act.target:HasTag("interior_door") then
        return act.invobject.components.roomdemolisher:DemolishRoom(act.doer, act.target, act.invobject)
    end
    return false
end

ACTIONS.THROW.fn = function(act)
    local thrown = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if act.target and not act.pos then
        act:SetActionPoint(act.target:GetPosition())
    end
    if thrown and thrown.components.throwable then
        local pos = act.GetActionPoint and act:GetActionPoint() or act.pos or act.doer:GetPosition()  --act.doer:GetPosition() Prevent error from monkey when throwing  -jerry
        thrown.components.throwable:Throw(pos, act.doer)
        return true
    end
end

local _EQUIP_fn = ACTIONS.EQUIP.fn
function ACTIONS.EQUIP.fn(act, ...)
    if act.doer.components.inventory and act.invobject.components.equippable.equipslot then
        return _EQUIP_fn(act, ...)
    end
    -- Boat equip slots
    if act.doer.components.sailor and act.doer.components.sailor.boat and act.invobject.components.equippable.boatequipslot then
        local boat = act.doer.components.sailor.boat
        if boat.components.container and boat.components.container.hasboatequipslots then
            boat.components.container:Equip(act.invobject)
        end
    end
end

local _ExtraDropDist = ACTIONS.DROP.extra_arrive_dist
local ExtraDropDist = function (doer, dest, bufferedaction, ...) -- copied from scripts/actions.lua
    if not TheWorld:HasTag("porkland") then
        return _ExtraDropDist(doer, dest, bufferedaction, ...)
    end
    if dest ~= nil then
        local dx, dy, dz = dest:GetPoint()
        if TheWorld.Map:ReverseIsVisualGroundAtPoint(doer.Transform:GetWorldPosition()) ~= TheWorld.Map:ReverseIsVisualGroundAtPoint(dx, dy, dz) then
            return 1.75
        end

        local invobject = bufferedaction and bufferedaction.invobject or nil

        -- Extra drop dist to items that collide with doer.
        if invobject ~= nil and doer ~= nil and invobject.Physics ~= nil and doer.Physics ~= nil then
            if not checkbit(invobject.Physics:GetCollisionMask(), doer.Physics:GetCollisionGroup()) then
                return 0
            end

            local physics_rad = invobject:GetPhysicsRadius(0)

            if physics_rad > 0 then
                return physics_rad + 0.5
            end
        end
    end

    return 0
end

ACTIONS.DROP.extra_arrive_dist = ExtraDropDist
ACTIONS.COMBINESTACK.extra_arrive_dist = ExtraDropDist

local _ExtraPickupRange = ACTIONS.PICK.extra_arrive_dist
local function ExtraPickupRange(doer, dest, ...)
    if not TheWorld:HasTag("porkland") then
        return _ExtraPickupRange(doer, dest, ...)
    end
    if dest ~= nil then
        local dx, dy, dz = dest:GetPoint()
        if TheWorld.Map:ReverseIsVisualGroundAtPoint(doer.Transform:GetWorldPosition()) ~= TheWorld.Map:ReverseIsVisualGroundAtPoint(dx, dy, dz) then
            return 0.75
        end
    end
    return 0
end

ACTIONS.PICK.extra_arrive_dist = ExtraPickupRange
ACTIONS.PICKUP.extra_arrive_dist = ExtraPickupRange

local _HAMMERextra_arrive_dist = ACTIONS.HAMMER.extra_arrive_dist
function ACTIONS.HAMMER.extra_arrive_dist(inst, dest, bufferedaction)
    local distance = _HAMMERextra_arrive_dist and _HAMMERextra_arrive_dist(inst, dest, bufferedaction) or 0
    if inst ~= nil and dest ~= nil then
        local dx, dy, dz = dest:GetPoint()
        if TheWorld.Map:ReverseIsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) ~= TheWorld.Map:ReverseIsVisualGroundAtPoint(dx, dy, dz) then
            distance = distance + 1
        end
    end
    return distance
end

local _RUMMAGEextra_arrive_dist = ACTIONS.RUMMAGE.extra_arrive_dist
ACTIONS.RUMMAGE.extra_arrive_dist = function(doer, dest, ...)
    local ret = _RUMMAGEextra_arrive_dist ~= nil and _RUMMAGEextra_arrive_dist(doer, dest, ...) or 0
    if dest ~= nil then
        local target_x, target_y, target_z = dest:GetPoint()

        if TheWorld.Map:ReverseIsVisualGroundAtPoint(doer.Transform:GetWorldPosition()) ~= TheWorld.Map:ReverseIsVisualGroundAtPoint(target_x, target_y, target_z) then
            -- 2 with the ARRIVE_STEP (0.15), player radius (0.5) and boat radius (0.25) subtracted from it is aproximatly 1.1
            return 1.1 + ret
        end
    end
    return ret
end

local _RUMMAGE_strfn = ACTIONS.RUMMAGE.strfn
function ACTIONS.RUMMAGE.strfn(act, ...)
    local target = act.target or act.invobject
    if target and target.replica.container and target.replica.container.type == "boat" then
        return target.replica.container:IsOpenedBy(act.doer) and "CLOSE" or "INSPECT"
    end
    return _RUMMAGE_strfn(act, ...)
end

local _RUMMAGE_fn = ACTIONS.RUMMAGE.fn
function ACTIONS.RUMMAGE.fn(act, ...)
    local ret = {_RUMMAGE_fn(act, ...)}
    if ret[1] == nil then
        local targ = act.target or act.invobject

        if targ ~= nil and targ.components.container ~= nil then
            if not targ.components.container.canbeopened and targ.components.container.type == "boat" then
                if CanEntitySeeTarget(act.doer, targ) then
                    act.doer:PushEvent("opencontainer", { container = targ })
                    targ.components.container:Open(act.doer)
                end
                return true
            end
        end
    end
    return unpack(ret)
end

local _UNEQUIP_fn = ACTIONS.UNEQUIP.fn
function ACTIONS.UNEQUIP.fn(act, ...)
    if act.invobject.components.equippable.boatequipslot and act.invobject.parent then
        local boat = act.invobject.parent
        if boat.components.container then
            boat.components.container:Unequip(act.invobject.components.equippable.boatequipslot)
            if act.invobject.components.inventoryitem.cangoincontainer and not GetGameModeProperty("non_item_equips") then
                act.doer.components.inventory:GiveItem(act.invobject)
            else
                act.doer.components.inventory:DropItem(act.invobject, true, true)
            end
        elseif boat.components.inventory and act.invobject.components.equippable.equipslot then
            return _UNEQUIP_fn(act, ...)
        end
        return true
    else
        return _UNEQUIP_fn(act, ...)
    end
end

local _UNEQUIPstrfn = ACTIONS.UNEQUIP.strfn
ACTIONS.UNEQUIP.strfn = function(act, ...)
    return ((act.invobject ~= nil and
        act.invobject:HasTag("trawlnet") or
        GetGameModeProperty("non_item_equips") or
        act.doer.replica.inventory:GetNumSlots() <= 0)
        and "TRAWLNET") or _UNEQUIPstrfn(act, ...)
end

ACTIONS.STORE.priority = -1

local _STORE_stroverridefn = ACTIONS.STORE.stroverridefn
function ACTIONS.STORE.stroverridefn(act, ...)
    if act.target and act.target:HasTag("smelter") then
        return STRINGS.ACTIONS.SMELT
    elseif _STORE_stroverridefn then
        return _STORE_stroverridefn(act, ...)
    end
end

local _COOK_stroverridefn = ACTIONS.COOK.stroverridefn
function ACTIONS.COOK.stroverridefn(act, ...)
    if act.target and act.target:HasTag("smelter") then
        return STRINGS.ACTIONS.SMELT
    elseif _COOK_stroverridefn then
        return _COOK_stroverridefn(act, ...)
    end
end

local _PICK_strfn = ACTIONS.PICK.strfn
ACTIONS.PICK.strfn = function(act, ...)
    if act.target and act.target:HasTag("pickable_digin_str") then
        return "DIGIN"
    elseif _PICK_strfn then
        return _PICK_strfn(act, ...)
    end
end

local function TryToSoulhop(act, act_target, consumeall)
    return act.doer ~= nil
        and act.doer.sg ~= nil
        and act.doer.sg.currentstate.name == "portal_jumpin_pre"
        and act_target ~= nil
        and act.doer.TryToPortalHop ~= nil
        and act.doer:TryToPortalHop(act.distancecount, consumeall)
end

local _BLINK_fn = ACTIONS.BLINK.fn
ACTIONS.BLINK.fn = function(act, ...)
    if act.target then
        if act.target.components.sailable and not act.target.components.sailable:IsOccupied() then
            if act.invobject ~= nil then
                return act.invobject.components.blinkstaff:BlinkToBoat(act.target, act.doer)
            elseif TryToSoulhop(act, act.target) then
                act.doer.sg:GoToState("portal_jumpin_boat", {dest_target = act.target,})
                return true
            end
        end
    else
        return _BLINK_fn(act, ...)
    end
end

-- For pig guards
local _MANUALEXTINGUISH_fn = ACTIONS.MANUALEXTINGUISH.fn
ACTIONS.MANUALEXTINGUISH.fn = function(act, ...)
    if act.doer:HasTag("extinguisher") then
        if act.target.components.burnable and act.target.components.burnable:IsBurning() then
            act.target.components.burnable:Extinguish(true, TUNING.SMOTHERER_EXTINGUISH_HEAT_PERCENT)
            return true
        end
    end
    if act.invobject == nil then
        return false
    end
    return _MANUALEXTINGUISH_fn(act, ...)
end

ACTIONS.MANUALEXTINGUISH.validfn = function(act)
    return act.target and act.target:IsValid() and act.target.components.burnable and act.target.components.burnable:IsBurning()
end

local _UNWRAPstrfn = ACTIONS.UNWRAP.strfn
function ACTIONS.UNWRAP.strfn(act, ...)
    local tunacan = act.target or act.invobject
    if tunacan ~= nil and tunacan:HasTag("tincan") then
        return "OPENCAN"
    end
    return _UNWRAPstrfn and _UNWRAPstrfn(act, ...)
end

local _LIGHTfn = ACTIONS.LIGHT.fn
function ACTIONS.LIGHT.fn(act, ...)
    if act.invobject ~= nil and act.invobject:HasTag("magnifying_glass") and act.target then
        local x, y, z = act.target.Transform:GetWorldPosition()
        if TheSim:GetLightAtPoint(x, y, z) < TUNING.MAGNIFYING_GLASS_LIGHT then
            return false, "TOODARK"
        end
    end
    return _LIGHTfn(act, ...)
end

local _ROTATE_FENCEfn = ACTIONS.ROTATE_FENCE.fn
ACTIONS.ROTATE_FENCE.fn = function(act)
    if act.invobject ~= nil and act.target ~= nil and act.target:HasTag("furniture") then
        if not (act.invobject.components.itemmimic and act.invobject.components.itemmimic.fail_as_invobject) then
            local fencerotator = act.invobject.components.fencerotator
            if fencerotator then
                fencerotator:Rotate(act.target, TUNING.FENCE_FURNITURE_ROTATION)
                return true
            end
        end
    end

    return _ROTATE_FENCEfn(act)
end

-- SCENE        using an object in the world
-- USEITEM      using an inventory item on an object in the world
-- POINT        using an inventory item on a point in the world
-- EQUIPPED     using an equiped item on yourself or a target object in the world
-- INVENTORY    using an inventory item
-- ISVALID      using an equiped item or an inventory item with tool component on a target
local PL_COMPONENT_ACTIONS =
{
    SCENE = { -- args: inst, doer, actions, right
        sailable = function(inst, doer, actions, right)
            if inst:HasTag("sailable") and not (doer.replica.rider and doer.replica.rider:IsRiding()) then
                if not right then
                    table.insert(actions, ACTIONS.EMBARK)
                end
            end
        end,
        door = function(inst, doer, actions, right)
            if not inst:HasTag("door_hidden") and not inst:HasTag("door_disabled") then
                table.insert(actions, ACTIONS.USEDOOR)
            end
        end,
        disarmable = function(inst, doer, actions, right)
            if not inst:HasTag("armed") and inst:HasTag("rearmable") then
                table.insert(actions, ACTIONS.REARM)
            end
        end,
        livingartifact = function(inst, doer, actions, right)
            if not inst:HasTag("enabled") and right then
                table.insert(actions, ACTIONS.USE_LIVING_ARTIFACT)
            end
        end,
        mystery = function(inst, doer, actions, right)
            if right and inst:HasTag("mystery") then
                table.insert(actions, ACTIONS.SEARCH_MYSTERY)
            end
        end,
        visualslot = function(inst, doer, actions, right)
            if not inst:HasTag("empty") then
                local shelf = inst.replica.visualslot:GetShelf()
                if not shelf:HasTag("locked")
                    and inst.replica.visualslot:GetItem() ~= nil
                    and inst.replica.visualslot:GetItem():IsValid() then

                    if shelf and shelf.replica.shopped then
                        table.insert(actions, ACTIONS.SHOP)
                    else
                        table.insert(actions, ACTIONS.TAKEFROMSHELF)
                    end
                end
            end
        end,
        -- shopped = function(inst, doer, actions, right)
        --     if inst:HasTag("has_item_to_sell") then
        --         table.insert(actions, ACTIONS.SHOP)
        --     end
        -- end,
    },

    USEITEM = { -- args: inst, doer, target, actions, right
        disarming = function(inst, doer, target, actions, right)
            if target:HasTag("disarmable") and target:HasTag("armed") then
                table.insert(actions, ACTIONS.DISARM)
            end
        end,
        explosive = function(inst, doer, target, actions, right)
            if target:HasTag("blunderbuss") then
                table.insert(actions, ACTIONS.GIVE)
            end
        end,
        poisonhealer = function(inst, doer, target, actions, right)
            if right and target and target:HasTag("poisonable") then
                table.insert(actions, ACTIONS.CUREPOISON)
            end
        end,
        renovator = function(inst, doer, target, actions, right)
            if target:HasTag("renovatable") then
                table.insert(actions, ACTIONS.RENOVATE)
            end
        end,
        roombuilder = function(inst, doer, target, actions, right)
            if target:HasTag("predoor") then
                table.insert(actions, ACTIONS.BUILD_ROOM)
            end
        end,
        roomdemolisher = function(inst, doer, target, actions, right)
            if target:HasTag("interior_door") and target:HasTag("house_door") then
                table.insert(actions, ACTIONS.DEMOLISH_ROOM)
            end
        end,
    },

    POINT = { -- args: inst, doer, pos, actions, right, target
        gasser = function (inst, doer, pos, actions, right, target)
            if right and doer ~= target then
                table.insert(actions, ACTIONS.GAS)
            end
        end,
        throwable = function(inst, doer, pos, actions, right, target)
            if right and not TheWorld.Map:IsGroundTargetBlocked(pos) and not (inst.replica.equippable and not inst.replica.equippable:IsEquipped()) then
                table.insert(actions, ACTIONS.THROW)
            end
        end,
    },

    EQUIPPED = { -- args: inst, doer, target, actions, right
        -- ziwbi: added gasser to EQUIPPED. why wouldn't you just spray on gnats directly?
        gasser = function(inst, doer, target, actions, right)
            if right and doer ~= target then
                table.insert(actions, ACTIONS.GAS)
            end
        end,
        throwable = function(inst, doer, target, actions, right)
            if right
                and not (doer.components.playercontroller ~= nil
                and doer.components.playercontroller.isclientcontrollerattached)
                and not TheWorld.Map:IsGroundTargetBlocked(target:GetPosition())
                and not (inst.replica.equippable and not inst.replica.equippable:IsEquipped())
                and target ~= doer then

                table.insert(actions, ACTIONS.THROW)
            end
        end,

        investigater = function(inst, doer, target, actions, right)
            if not right then
                if target and (target:HasTag("mystery") or target:HasTag("secret_room")) then
                    table.insert(actions, ACTIONS.SPY)
                end
            else
                if target and target:HasTag("mystery") then
                    table.insert(actions, ACTIONS.SEARCH_MYSTERY)
                end
            end
        end,
    },

    INVENTORY = { -- args: inst, doer, actions, right
        livingartifact = function (inst, doer, actions, right)
            if not (inst.replica.inventoryitem and inst.replica.inventoryitem:IsHeldBy(doer)) then
                return
            end

            if not inst:HasTag("enabled") then
                table.insert(actions, ACTIONS.USE_LIVING_ARTIFACT)
            end
        end,
        poisonhealer = function(inst, doer, actions, right)
            if (doer:HasTag("poisonable") or doer:HasTag("player")) then
                table.insert(actions, ACTIONS.CUREPOISON)
            end
        end,
        repairer = function(inst, doer, actions, right)
            if doer and doer.replica.sailor and doer.replica.sailor:GetBoat() and inst and inst:HasTag("boat_repairer") then
                local boat = doer.replica.sailor:GetBoat()
                if boat:HasTag("repairable_boat") and boat.replica.boathealth and not boat.replica.boathealth:IsFull() then
                    table.insert(actions, ACTIONS.REPAIRBOAT)
                end
            end
        end,
    },

    ISVALID = { -- args: inst, action, right
        hackable = function(inst, action, right)
            return action == ACTIONS.HACK and inst:HasTag("HACK_workable")
        end,
        shearable = function(inst, action, right)
            return action == ACTIONS.SHEAR and inst:HasTag("SHEAR_workable")
        end,
        dislodgeable = function(inst, action, right)
            return action == ACTIONS.DISLODGE and inst:HasTag("DISLODGE_workable")
        end,
    },
}

for actiontype, actons in pairs(PL_COMPONENT_ACTIONS) do
    for component, fn in pairs(actons) do
        AddComponentAction(actiontype, component, fn)
    end
end

-- hack
local COMPONENT_ACTIONS = ToolUtil.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local SCENE = COMPONENT_ACTIONS.SCENE
local USEITEM = COMPONENT_ACTIONS.USEITEM
local POINT = COMPONENT_ACTIONS.POINT
local EQUIPPED = COMPONENT_ACTIONS.EQUIPPED
local INVENTORY = COMPONENT_ACTIONS.INVENTORY

local _SCENE_container = SCENE.container
function SCENE.container(inst, doer, actions, right, ...)
    if not inst:HasTag("bundle") and not inst:HasTag("burnt") and not inst:HasTag("noslot")
        and doer.replica.inventory
        and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())
        and right and inst.replica.container.type == "boat" then

        table.insert(actions, ACTIONS.RUMMAGE)
    else
        _SCENE_container(inst, doer, actions, right, ...)
    end
end

local _SCENE_rideable = SCENE.rideable
SCENE.rideable = function(inst, doer, actions, right)
    if doer:IsSailing() then
        return
    end
    return _SCENE_rideable(inst, doer, actions, right)
end

local _SCENE_inventoryitem = SCENE.inventoryitem
function SCENE.inventoryitem(inst, doer, actions, right, ...)
    if TheWorld.items_pass_ground and not inst:IsOnPassablePoint() and doer:IsOnPassablePoint()
        and not TheWorld.Map:IsLandTileAtPoint(inst.Transform:GetWorldPosition()) then --让物品在靠近岸边时被捡起而不是回收

        if inst.replica.inventoryitem:CanBePickedUp()
            and doer.replica.inventory and (doer.replica.inventory:GetNumSlots() > 0 or inst.replica.equippable)
            and not (inst:HasTag("catchable") or (not inst:HasTag("ignoreburning") and (inst:HasTag("fire") or inst:HasTag("smolder"))))
            and (not inst:HasTag("spider") or (doer:HasTag("spiderwhisperer") and right))
            and (right or not inst:HasTag("heavy"))
            and not (right and inst.replica.container and not inst.replica.equippable) then  -- copied from SCENE.inventoryitem

            table.insert(actions, ACTIONS.RETRIEVE)
        end
    else
       _SCENE_inventoryitem(inst, doer, actions, right, ...)
    end
end

local _SCENE_inspectable = SCENE.inspectable
function SCENE.inspectable(inst, ...)
    if inst:HasTag("inspectable") then
        _SCENE_inspectable(inst, ...)
    end
end

local _USEITEM_repairer = USEITEM.repairer
function USEITEM.repairer(inst, doer, target, actions, right, ...)
    if right then
        _USEITEM_repairer(inst, doer, target, actions, right, ...)
    else
        if target:HasTag("repairable_boat") and target.replica.boathealth and not target.replica.boathealth:IsFull() then
            table.insert(actions, ACTIONS.REPAIRBOAT)
        end
    end
end

local _USEITEM_inventoryitem = USEITEM.inventoryitem
function USEITEM.inventoryitem(inst, doer, target, actions, right, ...)
    if inst.replica.inventoryitem ~= nil then
        if not inst.replica.inventoryitem:CanOnlyGoInPocket() then
            if target:HasTag("weighdownable") then
                table.insert(actions, ACTIONS.WEIGHDOWN)
                return
            elseif target:HasTag("visual_slot") then
                if target:HasTag("empty") then
                    local shelf = target.replica.visualslot:GetShelf()
                    if not (shelf and shelf.replica.shopped) then
                        table.insert(actions, ACTIONS.PUTONSHELF)
                        return
                    end
                end
            end
        end
    end
    return _USEITEM_inventoryitem(inst, doer, target, actions, right, ...)
end

local _USEITEM_tool = USEITEM.tool
function USEITEM.tool(inst, doer, target, actions, right, ...)
    if inst:HasTag("fixable_crusher")
        and inst:HasTag(ACTIONS.HAMMER.id .. "_tool")
        and target:IsActionValid(ACTIONS.HAMMER, right)
        and not target:HasTag("fixable") then
        return
    end
    return _USEITEM_tool(inst, doer, target, actions, right, ...)
end

function EQUIPPED.blinkstaff(inst, doer, target, actions, right, ...)
    if right and target and target:HasTag("sailable") then
        table.insert(actions, ACTIONS.BLINK)
    end
end

local _EQUIPPED_tool = EQUIPPED.tool
function EQUIPPED.tool(inst, doer, target, actions, right, ...)
    if inst:HasTag("fixable_crusher")
        and inst:HasTag(ACTIONS.HAMMER.id .. "_tool")
        and target:IsActionValid(ACTIONS.HAMMER, right)
        and not target:HasTag("fixable") then
        return
    end
    return _EQUIPPED_tool(inst, doer, target, actions, right, ...)
end

local _INVENTORY_equippable = INVENTORY.equippable
function INVENTORY.equippable(inst, doer, actions, ...)
    local canEquip = true
    if inst.replica.equippable:BoatEquipSlot() ~= "INVALID" and inst.replica.equippable:EquipSlot() == "INVALID" then --Can only be equipped on a boat
        canEquip = false

        local sailor = doer.replica.sailor
        local boat = sailor and sailor:GetBoat()
        if boat and boat.replica.container.hasboatequipslots and boat.replica.container.enableboatequipslots then
            canEquip = true
        end
    end

    if not inst.replica.equippable:IsEquipped() and canEquip then
        _INVENTORY_equippable(inst, doer, actions, ...)
    elseif inst.replica.equippable:IsEquipped() then
        if inst:HasTag("togglable") then
            if inst:HasTag("toggled") then
                table.insert(actions, ACTIONS.TOGGLEOFF)
            else
                table.insert(actions, ACTIONS.TOGGLEON)
            end
        else
            _INVENTORY_equippable(inst, doer, actions, ...)
        end
    end
end

local _SCENE_pickable = SCENE.pickable
function SCENE.pickable(inst, doer, actions, ...)
    if not inst:HasTag("unsuited") then
        return _SCENE_pickable(inst, doer, actions, ...)
    end
end

local _USEITEM_weapon = USEITEM.weapon
function USEITEM.weapon(inst, doer, target, actions, right, ...)
    if target and target:HasTag("civilized") then
        if right then
            return _USEITEM_weapon(inst, doer, target, actions, false, ...)
        else
            return
        end
    end
    return _USEITEM_weapon(inst, doer, target, actions, right, ...)
end

local _EQUIPPED_weapon = EQUIPPED.weapon
function EQUIPPED.weapon(inst, doer, target, actions, right, ...)
    if target and target:HasTag("civilized") then
        if right then
            return _EQUIPPED_weapon(inst, doer, target, actions, false, ...)
        else
            return
        end
    end
    return _EQUIPPED_weapon(inst, doer, target, actions, right, ...)
end

local _USEITEM_healer = USEITEM.healer
function USEITEM.healer(inst, doer, target, actions, right, ...)
    if target and target:HasTag("trader") then
        if right then
            return _USEITEM_healer(inst, doer, target, actions, false, ...)
        else
            return
        end
    end
    return _USEITEM_healer(inst, doer, target, actions, right, ...)
end

local _USEITEM_lighter = USEITEM.lighter
function USEITEM.lighter(inst, doer, target, actions, ...)
    local wasLimbo = false
    if target:HasTag("allowinventoryburning") and target:HasTag("INLIMBO") then
        target:RemoveTag("INLIMBO")
        wasLimbo = true
    end
    _USEITEM_lighter(inst, doer, target, actions, ...)
    if wasLimbo and target:IsValid() and target.inlimbo then
        target:AddTag("INLIMBO")
    end
end

local _POINT_fishingrod = POINT.fishingrod
function POINT.fishingrod(inst, doer, pos, actions, right, target, ...)
    if TheWorld:HasTag("porkland") then
        return
    end
    return _POINT_fishingrod(inst, doer, pos, actions, right, target, ...)
end

local PlayerController = require("components/playercontroller")

local NON_AUTO_EQUIP_ACTIONS = {
    [ACTIONS.PUTONSHELF] = true,
    [ACTIONS.WEIGHDOWN] = true,
}

local do_action_auto_equip = PlayerController.DoActionAutoEquip
function PlayerController:DoActionAutoEquip(buffaction, ...)
    if NON_AUTO_EQUIP_ACTIONS[buffaction.action] then
        return
    end
    return do_action_auto_equip(self, buffaction, ...)
end

function PLENV.OnHotReload()
    ToolUtil.SetUpvalue(ACTIONS.CHOP.fn, _DoToolWork, "DoToolWork")

    ACTIONS.FERTILIZE.fn = _FERTILIZE_fn
    ACTIONS.EQUIP.fn = _EQUIP_fn
    ACTIONS.DROP.extra_arrive_dist = _ExtraDropDist
    ACTIONS.DROP.extra_arrive_dist = ExtraDropDist
    ACTIONS.COMBINESTACK.extra_arrive_dist = ExtraDropDist
    ACTIONS.PICK.extra_arrive_dist = _ExtraPickupRange
    ACTIONS.PICKUP.extra_arrive_dist = _ExtraPickupRange
    ACTIONS.HAMMER.extra_arrive_dist = _HAMMERextra_arrive_dist
    ACTIONS.RUMMAGE.extra_arrive_dist = _RUMMAGEextra_arrive_dist
    ACTIONS.RUMMAGE.strfn = _RUMMAGE_strfn
    ACTIONS.RUMMAGE.fn = _RUMMAGE_fn
    ACTIONS.UNEQUIP.fn = _UNEQUIP_fn
    ACTIONS.STORE.stroverridefn = _STORE_stroverridefn
    ACTIONS.COOK.stroverridefn = _COOK_stroverridefn
    ACTIONS.PICK.strfn = _PICK_strfn
    ACTIONS.BLINK.fn = _BLINK_fn

    SCENE.container = _SCENE_container
    SCENE.rideable = _SCENE_rideable
    USEITEM.repairer = _USEITEM_repairer
    INVENTORY.equippable = _INVENTORY_equippable
    USEITEM.inventoryitem = _USEITEM_inventoryitem
    SCENE.inventoryitem = _SCENE_inventoryitem
end

local AddAction = AddAction
local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local PL_ACTIONS = {
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
    DISEMBARK = Action({priority = 1, distance = 2.5, invalid_hold_action=true}),
    RETRIEVE = Action({priority = 1, distance = 3}),
    TOGGLEON = Action({priority = 2, mount_valid = true}),
    TOGGLEOFF = Action({priority = 2, mount_valid = true}),
    REPAIRBOAT = Action({distance = 3}),
    DISLODGE = Action({}),
    USEDOOR = Action({priority = 1, mount_valid = true, ghost_valid = false, encumbered_valid = true}), -- TODO ghost_valid
    VAMPIREBAT_FLYAWAY = Action({distance = 1}),
}

for name, ACTION in pairs(PL_ACTIONS) do
    ACTION.id = name
    ACTION.str = STRINGS.ACTIONS[name] or name
    AddAction(ACTION)
end




----set up the action functions
local _ValidToolWork = ToolUtil.GetUpvalue(ACTIONS.CHOP.validfn, "ValidToolWork")
local _DoToolWork = ToolUtil.GetUpvalue(ACTIONS.CHOP.fn, "DoToolWork")
local function DoToolWork(act, workaction, ...)
    if act.target.components.hackable ~= nil and act.target.components.hackable:CanBeHacked() and workaction == ACTIONS.HACK then
        if act.invobject and act.invobject.components.obsidiantool then
            act.invobject.components.obsidiantool:Use(act.doer, act.target)
        end
        act.target.components.hackable:Hack(act.doer,
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
    return (act.target.components.hackable and act.target.components.hackable:CanBeHacked()) or
        (act.target.components.workable and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == ACTIONS.HACK)
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
    return (act.target.components.shearable and act.target.components.shearable:CanShear()) or
        (act.target.components.workable and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == ACTIONS.SHEAR)
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
    if act.target and act.target:HasTag("sink") then
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

local function DoTeleport(player, pos)
    player:StartThread(function()
        local invincible = player.components.health.invincible
        player.components.health:SetInvincible(true)
        player:ScreenFade(false, 0.4)
        Sleep(0.5)
        -- recheck interior
        if not TheWorld.components.interiorspawner:IsInInteriorRegion(pos.x, pos.z)
            or TheWorld.components.interiorspawner:IsInInterior(pos.x, pos.z) then
            player.Physics:Teleport(pos:Get())
        end
        player.components.interiorvisitor:UpdateExteriorPos()
        player.components.health:SetInvincible(invincible)
        Sleep(0)
        player:SnapCamera()
        player:ScreenFade(true, 0.4)
        player.sg:GoToState("idle")
    end)
end

local function OnTeleportFailed(player)
    print("teleportfailed_event failed")
    -- if player.player_classified then
    --     player.player_classified.teleportfailed_event:push()
    -- end
end

ACTIONS.USEDOOR.fn = function(act)
    local door = act.target
    if door.components.door.disabled or door.components.door.hidden then
        return false, "DISABLED"
    end
    local target_interior = door.components.door.target_interior
    local target_door_id = door.components.door.target_door_id

    local function PlayDoorSound()
        door:PushEvent("usedoor", {doer = act.doer})
    end

    if target_interior == "EXTERIOR" then
        -- use `target_exterior` firstly, then use current room id as default
        local index = door.components.door.target_exterior or door.components.door.interior_name
        local house = TheWorld.components.interiorspawner:GetExteriorByInteriorIndex(index)
        -- print(index, type(index), house)
        if house ~= nil then
            DoTeleport(act.doer, house:GetPosition() + Vector3(house:GetPhysicsRadius(1), 0, 0))
            PlayDoorSound()
            act.doer:PushEvent("used_door", {door = door})
            return true
        end
    else
        local room = TheWorld.components.interiorspawner:GetInteriorByIndex(target_interior)

        local target_door = room and room:GetDoorById(target_door_id)
        if target_door then
            -- don't throw player directly on door
            -- instead, give a slight offset to room center
            local door_pos = target_door:GetPosition()
            local room_pos = room:GetPosition()
            local offset = (room_pos - door_pos):GetNormalized() * 1.0
            DoTeleport(act.doer, door_pos + offset)
            PlayDoorSound()
            act.doer:PushEvent("used_door", {door = door})
            return true
        end
    end

    OnTeleportFailed(act.doer)
    return false, "ERROR"
end

ACTIONS.VAMPIREBAT_FLYAWAY.fn = function(act)
    if not act.target or not act.doer then
        return false
    end
    act.doer:Remove()
    return true
end

-- Patch for hackable things
local _FERTILIZEfn = ACTIONS.FERTILIZE.fn
function ACTIONS.FERTILIZE.fn(act, ...)
    if _FERTILIZEfn(act, ...) then
        return true
    end

    if act.target.components.hackable and act.target.components.hackable:CanBeFertilized()
        and act.invobject and act.invobject.components.fertilizer then

        act.target.components.hackable:Fertilize(act.invobject, act.doer)
        return true
    end
end

local _EQUIPfn = ACTIONS.EQUIP.fn
function ACTIONS.EQUIP.fn(act, ...)
    if act.doer.components.inventory and act.invobject.components.equippable.equipslot then
        return _EQUIPfn(act, ...)
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
local ExtraDropDist = function (doer, dest, bufferedaction, ...)--copy from scripts/actions.lua
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

local _RUMMAGEstrfn = ACTIONS.RUMMAGE.strfn
function ACTIONS.RUMMAGE.strfn(act, ...)
    local targ = act.target or act.invobject

    return targ ~= nil and targ.replica.container and targ.replica.container.type == "boat" and
        (targ.replica.container:IsOpenedBy(act.doer) and "CLOSE" or "INSPECT") or _RUMMAGEstrfn(act, ...)
end

local _RUMMAGEfn = ACTIONS.RUMMAGE.fn
function ACTIONS.RUMMAGE.fn(act, ...)
    local ret = {_RUMMAGEfn(act, ...)}
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

local _UNEQUIPfn = ACTIONS.UNEQUIP.fn
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
            return _UNEQUIPfn(act, ...)
        end
        return true
    else
        return _UNEQUIPfn(act, ...)
    end
end

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
    },

    USEITEM = { -- args: inst, doer, target, actions, right
        poisonhealer = function (inst, doer, target, actions, right)
            if target and target:HasTag("poisonable") then
                if target:HasTag("poison") or (target:HasTag("player") and
                    ((target.components.poisonable and target.components.poisonable:IsPoisoned()) or
                    (target.player_classified and target.player_classified.ispoisoned:value()))) then
                    table.insert(actions, ACTIONS.CUREPOISON)
                end
            end
        end,
    },

    POINT = { -- args: inst, doer, pos, actions, right, target

    },

    EQUIPPED = { -- args: inst, doer, target, actions, right

    },

    INVENTORY = { -- args: inst, doer, actions, right
        poisonhealer = function(inst, doer, actions, right)
            if doer:HasTag("poisonable") and (doer:HasTag("player") and
                ((doer.components.poisonable and doer.components.poisonable:IsPoisoned()) or
                (doer.player_classified and doer.player_classified.ispoisoned:value()))) then
                table.insert(actions, ACTIONS.CUREPOISON)
            end
        end,
        repairer = function(inst, doer, actions, right)
            if doer and doer.replica.sailor and doer.replica.sailor:GetBoat() then
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

local _SCENEcontainer = SCENE.container
function SCENE.container(inst, doer, actions, right, ...)
    if not inst:HasTag("bundle") and not inst:HasTag("burnt")
        and doer.replica.inventory
        and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())
        and right and inst.replica.container.type == "boat" then

        table.insert(actions, ACTIONS.RUMMAGE)
    else
        _SCENEcontainer(inst, doer, actions, right, ...)
    end
end

local _SCENErideable = SCENE.rideable
SCENE.rideable = function(inst, doer, actions, right)
    if doer:IsSailing() then
        return
    end
    return _SCENErideable(inst, doer, actions, right)
end

local _USEITEMrepairer = USEITEM.repairer
function USEITEM.repairer(inst, doer, target, actions, right, ...)
    if right then
        _USEITEMrepairer(inst, doer, target, actions, right, ...)
    else
        if target:HasTag("repairable_boat") and target.replica.boathealth and not target.replica.boathealth:IsFull() then
            table.insert(actions, ACTIONS.REPAIRBOAT)
        end
    end
end

function EQUIPPED.blinkstaff(inst, doer, target, actions, right, ...)
    if right and target and target:HasTag("sailable") then
        table.insert(actions, ACTIONS.BLINK)
    end
end

local _INVENTORYequippable = INVENTORY.equippable
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
        _INVENTORYequippable(inst, doer, actions, ...)
    elseif inst.replica.equippable:IsEquipped() then
        if inst:HasTag("togglable") then
            if inst:HasTag("toggled") then
                table.insert(actions, ACTIONS.TOGGLEOFF)
            else
                table.insert(actions, ACTIONS.TOGGLEON)
            end
        else
            _INVENTORYequippable(inst, doer, actions, ...)
        end
    end
end

local _SCENEinventoryitem = SCENE.inventoryitem
function SCENE.inventoryitem(inst, doer, actions, right, ...)
   if TheWorld.items_pass_ground and not inst:IsOnPassablePoint() and doer:IsOnPassablePoint() and
        not TheWorld.Map:IsLandTileAtPoint(inst.Transform:GetWorldPosition()) then --让物品在靠近岸边时被捡起而不是回收
        if inst.replica.inventoryitem:CanBePickedUp() and
        doer.replica.inventory ~= nil and (doer.replica.inventory:GetNumSlots() > 0 or inst.replica.equippable ~= nil) and
        not (inst:HasTag("catchable") or (not inst:HasTag("ignoreburning") and (inst:HasTag("fire") or inst:HasTag("smolder")))) and
        (not inst:HasTag("spider") or (doer:HasTag("spiderwhisperer") and right)) and
        (right or not inst:HasTag("heavy")) and
        not (right and inst.replica.container ~= nil and inst.replica.equippable == nil) then  --coryfrom SCENE.inventoryitem
            table.insert(actions, ACTIONS.RETRIEVE)
        end
    else
       _SCENEinventoryitem(inst, doer, actions, right, ...)
    end
end

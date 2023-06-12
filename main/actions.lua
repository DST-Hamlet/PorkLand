local AddAction = AddAction
local AddComponentAction = AddComponentAction
GLOBAL.setfenv(1, GLOBAL)

local PL_ACTIONS = {
    HACK = Action({mindistance = 1.75, silent_fail = true}),
    SHEAR = Action({distance = 1.75}),
    PEAGAWK_TRANSFORM = Action({}),
    DIGDUNG = Action({mount_valid=true}),
    MOUNTDUNG = Action({}),
    DISLODGE = Action({distance = 1,priority = 1}),
    SPECIAL_ACTION = Action({distance = 1.2}),
    SPECIAL_ACTION2 = Action({distance = 1.2}),
    BARK = Action({distance = 3}),
    RANSACK = Action({distance = 0.5}),
	INFEST = Action({distance = 0.5}),
}

for name, ACTION in pairs(PL_ACTIONS) do
    ACTION.id = name
    ACTION.str = STRINGS.ACTIONS[name] or "PL_ACTION"
    AddAction(ACTION)
end

----set up the action functions
local _DoToolWork = Pl_Util.GetUpvalue(ACTIONS.CHOP.fn, "DoToolWork")
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
Pl_Util.SetUpvalue(ACTIONS.CHOP.fn, DoToolWork, "DoToolWork")

ACTIONS.HACK.fn = function(act)
    DoToolWork(act, ACTIONS.HACK)
    return true
end

ACTIONS.HACK.validfn = function(act) -- this fixes hacking a nonvalid target when holding the mouse
    return (act.target.components.hackable and act.target.components.hackable:CanBeHacked()) or
        (act.target.components.workable and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == ACTIONS.HACK)
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

ACTIONS.DIGDUNG.fn = function(act)
	act.target.components.workable:WorkedBy(act.doer, 1)
	return true
end

ACTIONS.MOUNTDUNG.fn = function(act)
	act.doer.dung_target:Remove()
	act.doer:AddTag("hasdung") 
	act.doer.dung_target = nil
	return true
end

-----------------------------------------------------------------------------------------
ACTIONS.DISLODGE.fn = function(act)
	if act.target.components.dislodgeable then
		act.target.components.dislodgeable:Dislodge(act.doer)
		-- action with inventory object already explicitly calls OnUsedAsItem
		if not act.invobject and act.doer and act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
			local invobject = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if invobject.components.finiteuses then
				invobject.components.finiteuses:OnUsedAsItem(ACTIONS.DISLODGE)
			end
		end
		return true
	end
end

AddComponentAction("EQUIPPED", "dislodger", function(inst, doer, target, actions, right)
    -- if target.components.dislodgeable then
    if target:HasTag("dislodgeable") then
        if not right then
            table.insert(actions, ACTIONS.DISLODGE)
        end
    end
end)

ACTIONS.DISLODGE.validfn = function(act)
    return (act.target.components.dislodgeable and act.target.components.dislodgeable:CanBeDislodged()) or
        (act.target.components.workable and act.target.components.workable:CanBeWorked() and act.target.components.workable:GetWorkAction() == ACTIONS.DISLODGE)
end

-- AddComponentAction("SCENE", "dislodgable", function(inst, doer, actions, right)
    -- -- if target.components.dislodgeable then
        -- if not right then
            -- table.insert(actions, ACTIONS.DISLODGE)
        -- end
    -- -- end
-- end)
-----------------------------------------------------------------------------------------
ACTIONS.INFEST.fn = function(act)
	if not act.doer.infesting then
		act.doer.components.infester:Infest(act.target)
	end
	return true
end

ACTIONS.SPECIAL_ACTION.fn = function(act)
	if act.doer.SpecialAction then
		act.doer.SpecialAction(act)
		return true
	end
end

ACTIONS.SPECIAL_ACTION2.fn = function(act)
	if act.doer.special_action2 then
		act.doer.special_action2(act)
		return true
	end
end
-----------------------------------------------------------------------------------------

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
-----------------------------------------------------------------------------------------
function ACTIONS.COOK.strfn(act)
	local obj = act.target
	if obj.components.melter then
		return "SMELT"
	end
end 

-- Patch for smelter things
local _COOKfn = ACTIONS.COOK.fn
function ACTIONS.COOK.fn(act)
    if act.target.components.melter then
		if act.target.components.melter:IsCooking() then
            --Already cooking
            return true
        end
        local container = act.target.components.container
        if container ~= nil and container:IsOpenedByOthers(act.doer) then
            return false, "INUSE"
        elseif not act.target.components.melter:CanCook() then
            return false
        end
        act.target.components.melter:StartCooking(act.doer)
        return true
	end
	
	return _COOKfn(act)
end

local _HARVESTvalidfn = ACTIONS.HARVEST.validfn
function ACTIONS.HARVEST.validfn(act, ...)
    if act.target and act.target.components.melter then --Dont continue to harvest if it cannot be harvested, fixes a crash trying to spawn a nil -Half
		return act.target:HasTag("donecooking")
    else
        return (_HARVESTvalidfn and _HARVESTvalidfn(act, ...)) or true --if a validfn is added use that or send back true so everything works normally
    end
end

local _HARVESTfn = ACTIONS.HARVEST.fn
function ACTIONS.HARVEST.fn(act)
     if act.target.components.melter then
        return act.target.components.melter:Harvest(act.doer)	
	else
		return _HARVESTfn(act)
	end
end

AddComponentAction("SCENE", "melter", function(inst, doer, actions, right)
    if inst:HasTag("donecooking") and doer.replica.inventory then
        table.insert(actions, ACTIONS.HARVEST)
    end
end)

-----------------------------------------------------------------------------------------

-- SCENE        using an object in the world
-- USEITEM      using an inventory item on an object in the world
-- POINT        using an inventory item on a point in the world
-- EQUIPPED     using an equiped item on yourself or a target object in the world
-- INVENTORY    using an inventory item
local PL_COMPONENT_ACTIONS =
{
    SCENE = { -- args: inst, doer, actions, right

    },

    USEITEM = { -- args: inst, doer, target, actions, right
    },

    POINT = { -- args: inst, doer, pos, actions, right, target

    },

    EQUIPPED = { -- args: inst, doer, target, actions, right

    },

    INVENTORY = { -- args: inst, doer, actions, right


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
		end
    },
}

for actiontype, actons in pairs(PL_COMPONENT_ACTIONS) do
    for component, fn in pairs(actons) do
        AddComponentAction(actiontype, component, fn)
    end
end




-- hack
local COMPONENT_ACTIONS = Pl_Util.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local SCENE = COMPONENT_ACTIONS.SCENE
local USEITEM = COMPONENT_ACTIONS.USEITEM
local POINT = COMPONENT_ACTIONS.POINT
local EQUIPPED = COMPONENT_ACTIONS.EQUIPPED
local INVENTORY = COMPONENT_ACTIONS.INVENTORY

_wateryprotection = COMPONENT_ACTIONS.EQUIPPED.wateryprotection
function EQUIPPED.wateryprotection(inst, doer, target, actions, right, ...)
    if right and target:HasTag("waterneeded") then
        table.insert(actions, ACTIONS.POUR_WATER)
    else
        _wateryprotection(inst, doer, target, actions, right, ...)
    end
end
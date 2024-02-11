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
    DIGDUNG = Action({mount_enabled = true}),
    MOUNTDUNG = Action({}),
}

for name, ACTION in pairs(PL_ACTIONS) do
    ACTION.id = name
    ACTION.str = STRINGS.ACTIONS[name] or "PL_ACTION"
    AddAction(ACTION)
end




----set up the action functions
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

ACTIONS.PAN.fn = function(act)
    if act.target.components.workable and
        act.target.components.workable:CanBeWorked() and
        act.target.components.workable:GetWorkAction() == ACTIONS.PAN then

        local effectiveness = (act.invobject
            and act.invobject.components.tool
            and act.invobject.components.tool:GetEffectiveness(ACTIONS.PAN))
            or (act.doer
            and act.doer.components.worker
            and act.doer.components.worker:GetEffectiveness(ACTIONS.PAN))
            or 1
        local multiplier = act.doer.components.workmultiplier
            and act.doer.components.workmultiplier:GetMultiplier(ACTIONS.PAN) or 1

		local numworks = effectiveness * multiplier
        act.target.components.workable:WorkedBy(act.doer, numworks)

        return true
    end

	return false
end

local DRUNK_GOLD = 1/8
ACTIONS.PANGOLDEN_DRINK.fn = function(act)
    if act.doer.puddle and act.doer.puddle:IsValid() and act.doer.puddle.stage > 0 then
        act.doer.puddle:Shrink()
        act.doer.gold_level = act.doer.gold_level + DRUNK_GOLD
        return true
    end

    return false
end

ACTIONS.PANGOLDEN_POOP.fn = function(act)
    local x, y, z = act.doer.Transform:GetWorldPosition()
    SpawnPrefab("goldnugget").Transform:SetPosition(x, y, z)

    return true
end

ACTIONS.DIGDUNG.fn = function(act)
    act.target.components.workable:WorkedBy(act.doer, 1)
    return true
end

ACTIONS.MOUNTDUNG.fn = function(act)
    local doer = act.doer
    doer.dung_target:Remove()
    doer:AddTag("hasdung")
    doer.dung_target = nil
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
        end
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

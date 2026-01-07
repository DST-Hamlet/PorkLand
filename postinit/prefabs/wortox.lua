local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function WortoxRightClickPicker(inst, target, pos)
    local canblink = false
    local _rightclickoverride = inst.components.playeractionpicker.rightclickoverride
    inst.components.playeractionpicker.rightclickoverride = nil
    local actions = inst.components.playeractionpicker:GetRightClickActions(pos, target, nil)--如果未来小恶魔可以打开轮盘菜单，那么需要传递第三个参数spell
    inst.components.playeractionpicker.rightclickoverride = _rightclickoverride

    if (target ~= nil and target:HasTag("sailable")) and
        not (inst.components.playercontroller ~= nil and inst.components.playercontroller.isclientcontrollerattached) and
        inst.CanSoulhop and inst:CanSoulhop() then
            canblink = true
    else
        return actions
    end

    if actions ~= nil and #actions > 0
        and not (actions[1].action.code == ACTIONS.LOOKAT.code or actions[1].action.code == ACTIONS.WALKTO.code or actions[1].action.code == ACTIONS.RUMMAGE.code) then
            return actions
    end
    if target ~= nil then
        local tx, ty, tz = target.Transform:GetWorldPosition()
        if actions ~= nil and #actions > 0
            and actions[1].action.code == ACTIONS.RUMMAGE.code
            and TheWorld.Map:IsCloseToLand(tx, ty, tz, 2) and inst:GetDistanceSqToInst(target) < 6 * 6 then
                return actions
        end
    end

    return canblink and inst.components.playeractionpicker:SortActionList({ ACTIONS.BLINK }, target, nil) or {},
        not canblink
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.rightclickoverride = WortoxRightClickPicker
    end
end

local _CLIENT_Wortox_HostileTest = nil

local function CLIENT_Wortox_HostileTest(inst, target, ...)
	if target.HostileToPlayerTest == nil 
        and (not inst:HasTag("playermonster") and target:HasAnyTag("pig", "catcoon"))
        and not target:HasTag("hostile") then

		return false
	end
    return _CLIENT_Wortox_HostileTest(inst, target, ...)
end

AddPrefabPostInit("wortox", function(inst)
    inst:ListenForEvent("setowner", OnSetOwner)

    if _CLIENT_Wortox_HostileTest == nil then
        _CLIENT_Wortox_HostileTest = inst.HostileTest
    end

    inst.HostileTest = CLIENT_Wortox_HostileTest
end)

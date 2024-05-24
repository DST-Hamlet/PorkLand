local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function WortoxRightClickPicker(inst, target, pos)
    local canblink = false
    if (target ~= nil and target:HasTag("sailable")) and
        not (inst.components.playercontroller ~= nil and inst.components.playercontroller.isclientcontrollerattached) and
        inst.CanSoulhop and inst:CanSoulhop() then
            canblink = true
    end

    local _rightclickoverride = inst.components.playeractionpicker.rightclickoverride
    inst.components.playeractionpicker.rightclickoverride = nil
    local actions = inst.components.playeractionpicker:GetRightClickActions(pos, target, nil)--如果未来小恶魔可以打开轮盘菜单，那么需要传递第三个参数spell
    inst.components.playeractionpicker.rightclickoverride = _rightclickoverride
    if actions ~= nil and #actions > 0 and not (#actions == 1 and (actions[1].action.code == ACTIONS.LOOKAT.code or actions[1].action.code == ACTIONS.WALKTO.code)) then
        return actions
    end

    return canblink and inst.components.playeractionpicker:SortActionList({ ACTIONS.BLINK }, target, nil) or {},
        not canblink
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.rightclickoverride = WortoxRightClickPicker
    end
end

AddPrefabPostInit("wortox", function(inst)
    inst:ListenForEvent("setowner", OnSetOwner)
end)

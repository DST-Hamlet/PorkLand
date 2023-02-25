--------------------------------------------------------------------------
--[[ Aporkalypse class definition ]]
--------------------------------------------------------------------------

-- 毁灭季前7天是预警期
-- 毁灭季60天一个周期，并且只会在上一个毁灭季结束后计时，第一次毁灭季时间无限，第一次之后是20天
-- 进入毁灭季节前记录上一个季节，及其进展，毁灭季结束后恢复该季节
-- 毁灭季季节温度恒温40，只有晚上，月亮ui变成血月
-- 毁灭季节后5天是嘉年华

-- 是否毁灭季 需要网络变量，用于通知客户端UI

-- 预警期
-- 一些生物的脑子使用

-- 嘉年华
-- 一些食物图标改变
-- 商店有变化？

return Class(function(self, inst)
    -- Public
    self.inst = inst
    local _world = TheWorld

    -- Private
    local _ismastersim = _world.ismastersim
    local APORKALYPSE_LENGTH = TUNING.APORKALYPSE_LENGTH
    local NEAR_TIME = TUNING.APORKALYPSE_NEAR_TIME
    local APORKALYPSE_PERIOD_LENGTH = TUNING.APORKALYPSE_PERIOD_LENGTH

    local first_aporkalypse = true
    local near_aporkalypse = false
    local time_until_aporkalypse = APORKALYPSE_PERIOD_LENGTH
    local remainingtime_in_aporkalypse = APORKALYPSE_LENGTH

    -- Network
    local isaporkalypse = net_bool(inst.GUID, "isaporkalypse", "aporkalypsedirty")

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local ForceResync = _ismastersim and function(netvar, value)
        netvar:set_local(value ~= nil and value or netvar:value())
        netvar:set(value ~= nil and value or netvar:value())
    end or nil

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnAporkalypseaDirty()
        _world:PushEvent("aporkalypschange", isaporkalypse:value())
    end

    local BeginAporkalypse = _ismastersim and function()
        if isaporkalypse:value() then
            return
        end

        print("开始毁灭季")

        if first_aporkalypse then

        else
            remainingtime_in_aporkalypse = APORKALYPSE_LENGTH
        end

        isaporkalypse:set(true)
    end or nil

    local EndAporkalypse = _ismastersim and function()
        if not isaporkalypse:value() then
            return
        end

        print("结束毁灭季")

        time_until_aporkalypse = APORKALYPSE_PERIOD_LENGTH

        isaporkalypse:set(false)
    end or nil

    local ScheduleAporkalypse = _ismastersim and function(src, delta)
        local daytime = APORKALYPSE_PERIOD_LENGTH
        while delta > daytime do
            delta = delta % daytime
        end

        while delta < 0 do
            delta = delta + daytime
        end

        time_until_aporkalypse = delta
    end

    local OnSimUnpaused = _ismastersim and function()
        ForceResync(isaporkalypse)  -- Force resync values
    end or nil

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    -- Initialize network variables
    isaporkalypse:set(false)

    -- Register events
    inst:ListenForEvent("aporkalypsedirty", OnAporkalypseaDirty)

    if _ismastersim then
        -- Register master events
        inst:ListenForEvent("beginaporkalypse", BeginAporkalypse, _world)
        inst:ListenForEvent("endaporkalypse", EndAporkalypse, _world)
        inst:ListenForEvent("scheduleaporkalypse", ScheduleAporkalypse, _world)
        inst:ListenForEvent("ms_simunpaused", OnSimUnpaused, _world)
    end

    if _ismastersim then
        inst:StartUpdatingComponent(self)
    end

    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnUpdate(dt)
        if isaporkalypse:value() then

            if first_aporkalypse then

            else
                remainingtime_in_aporkalypse = remainingtime_in_aporkalypse - dt

                if remainingtime_in_aporkalypse <= 0 then
                    _world:PushEvent("endaporkalypse")

                    self:OnUpdate(-remainingtime_in_aporkalypse)
                    return
                end
            end

        else

            time_until_aporkalypse = time_until_aporkalypse - dt

            if time_until_aporkalypse > 0 then
                if time_until_aporkalypse <= NEAR_TIME then
                    near_aporkalypse = true
                end
            else
                near_aporkalypse = false
                _world:PushEvent("beginaporkalypse")

                self:OnUpdate(-time_until_aporkalypse)
                return
            end

        end

        _world:PushEvent("aporkalypseclocktick", {time_until_aporkalypse = time_until_aporkalypse, remainingtime_in_aporkalypse = remainingtime_in_aporkalypse, dt = dt})
    end end

    self.LongUpdate = self.OnUpdate

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnSave()
        return {
            first_aporkalypse = first_aporkalypse,
            isaporkalypse = isaporkalypse:value(),
            time_until_aporkalypse = time_until_aporkalypse,
            remainingtime_in_aporkalypse = remainingtime_in_aporkalypse
        }
    end end

    if _ismastersim then function self:OnLoad(data)
        -- can be false, so don't nil check
        if data.FIRST == false then
            first_aporkalypse = false
        end

        if data.isaporkalypse == true then
            ForceResync(isaporkalypse, true)
        end

        remainingtime_in_aporkalypse = data.remainingtime_in_aporkalypse
        time_until_aporkalypse = data.time_until_aporkalypse
    end end

end)

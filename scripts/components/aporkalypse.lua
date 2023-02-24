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
    local aporkalypse_active = net_bool(inst.GUID, "aporkalypse.active", "aporkalypseactivedirty")

    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    function self:IsActive()
        return aporkalypse_active:value()
    end

    if _ismastersim then function self:GetTimeUntilAporkalypse()
        return time_until_aporkalypse
    end end

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local BeginAporkalypse = _ismastersim and function()
        if aporkalypse_active:value() then
            return
        end

        print("开始毁灭季")

        if first_aporkalypse then

        else
            remainingtime_in_aporkalypse = APORKALYPSE_LENGTH
        end

        aporkalypse_active:set(true)

        _world:PushEvent("beginaporkalypse")
    end or nil

    local EndAporkalypse = _ismastersim and function()
        if not aporkalypse_active:value() then
            return
        end

        print("结束毁灭季")

        time_until_aporkalypse = APORKALYPSE_PERIOD_LENGTH

        aporkalypse_active:set(false)

        _world:PushEvent("endaporkalypse")
    end or nil

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------


    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    -- Initialize network variables
    aporkalypse_active:set(false)

    -- Register events
    -- inst:ListenForEvent("beginaporkalypse", OnBeginAporkalypse, _world)
    -- inst:ListenForEvent("endaporkalypse", OnClockTick, _world)

    if _ismastersim then
        inst:StartUpdatingComponent(self)
    end

    --------------------------------------------------------------------------
    --[[ Update ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnUpdate(dt)
        if aporkalypse_active:value() then

            if first_aporkalypse then

            else
                remainingtime_in_aporkalypse = remainingtime_in_aporkalypse - dt

                if remainingtime_in_aporkalypse <= 0 then
                    EndAporkalypse()

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
                BeginAporkalypse()

                self:OnUpdate(-time_until_aporkalypse)
                return
            end

        end
    end end

    self.LongUpdate = self.OnUpdate

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

    if _ismastersim then function self:OnSave()
        return {
            first_aporkalypse = first_aporkalypse,
            remainingtime_in_aporkalypse = remainingtime_in_aporkalypse,
            aporkalypse_active = aporkalypse_active:value()
        }
    end end

    if _ismastersim then function self:OnLoad(data)
        -- can be false, so don't nil check
        if data.FIRST == false then
            first_aporkalypse = false
        end

        if data.remainingtime_in_aporkalypse then
            remainingtime_in_aporkalypse = data.remainingtime_in_aporkalypse
        end

        if data.aporkalypse_active == true then
            aporkalypse_active:set(true)
        end
    end end

end)

-- 让客户端可以得知服务器当前的时间, 与上一次同步的时间相比来进行延迟预测
local WorldTimeSync = Class(function(self, inst)
    self.inst = inst

    self._time = net_float(inst.GUID, "worldtimesync._time", "onworldtimesyncdirty")
    self._time:set(GetTime())
    self._static_time = net_float(inst.GUID, "worldtimesync._static_time", "onworldtimesyncdirty")
    self._static_time:set(GetStaticTime())

    self.last_sync_time = GetTime()
    self.last_static_sync_time = GetStaticTime()

    self.delta_time = 0
    self.static_delta_time = 0

    inst:StartWallUpdatingComponent(self)

    inst:ListenForEvent("onworldtimesyncdirty", function()
        self.delta_time = GetTime() - self.last_sync_time
        self.static_delta_time = GetStaticTime() - self.last_static_sync_time

        self.last_sync_time = GetTime()
        self.last_static_sync_time = GetStaticTime()
    end)
end)

function WorldTimeSync:OnWallUpdate()
    if TheWorld.ismastersim then
        self._time:set(GetTime())
        self._static_time:set(GetStaticTime())
    end
end

function WorldTimeSync:GetServerTime()
    return self._time:value()
end

function WorldTimeSync:GetServerStaticTime()
    return self._static_time:value()
end

function WorldTimeSync:IsCurrentFrameSynced() -- 本帧是否发生过同步
    return self.last_static_sync_time == GetStaticTime()
end

function WorldTimeSync:GetDeltaTime() -- 和上一次同步得到的服务器数据之间的本地时间差
    return self.delta_time
end

function WorldTimeSync:GetStaticDeltaTime()
    return self.static_delta_time
end

return WorldTimeSync

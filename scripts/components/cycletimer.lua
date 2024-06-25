local Cycletimer = Class(function(self, inst)
    self.inst = inst
end)

function Cycletimer:StartCycle1(settime)
    if self.inst.cycletask2 then
        self.inst.cycletask2:Cancel()
        self.inst.cycletask2 = nil
    end

    self.cyclefn1(self.inst)
    local time = self.cycletime1
    if settime then
        time = settime
    end

    self.inst.cycletask1, self.inst.cycletask1info = self.inst:ResumeTask(time, function() self:StartCycle2() end)
end

function Cycletimer:StartCycle2(settime)
    if self.inst.cycletask1 then
        self.inst.cycletask1:Cancel()
        self.inst.cycletask1 = nil
    end

    self.cyclefn2(self.inst)
    local time = self.cycletime2
    if settime then
        time = settime
    end
    self.inst.cycletask2, self.inst.cycletask2info = self.inst:ResumeTask(time,function() self:StartCycle1() end)
end

function Cycletimer:SetUp(time1, time2, time1fn, time2fn)
    if not time1 or not time2 or not time1fn or not time2fn then
        print("Missing argument for Cycletimer:SetUp!")
        return
    end

    self.cycletime1 = time1
    self.cyclefn1 = time1fn

    self.cycletime2 = time2
    self.cyclefn2 = time2fn
end

function Cycletimer:Start(initialdelay)
    self.inst.cycletask2, self.inst.cycletask2info = self.inst:ResumeTask(initialdelay,function() self:StartCycle1() end)
end

function Cycletimer:OnSave()
    local data = {}

    if self.inst.cycletask1 then
        data.task1time = self.inst:TimeRemainingInTask(self.inst.cycletask1info)
    end
    if self.inst.cycletask2 then
        data.task2time = self.inst:TimeRemainingInTask(self.inst.cycletask2info)
    end
    if self.started then
        data.started = self.started
    end

    if self.task1time then
        data.pasuetask1time = self.task1time
    end
       if self.task2time then
        data.pasuetask2time = self.task2time
    end

    return data
end

function Cycletimer:OnLoad(data)
    if data then
        if data.task1time then
            self.inst.cycletask1, self.inst.cycletask1info = self.inst:ResumeTask(data.task1time, function() self:StartCycle2() end)
        end
        if data.task2time then
            self.inst.cycletask2, self.inst.cycletask2info = self.inst:ResumeTask(data.task2time, function() self:StartCycle1() end)
        end
        if data.started then
            self.started = data.started
        end

        if data.pasuetask1time then
            self.task1time = data.pasuetask1time
        end
        if data.pasuetask2time then
            self.task2time = data.pasuetask2time
        end
    end
end

function Cycletimer:Pause()
    if self.inst.cycletask1 then
        self.task1time = self.inst:TimeRemainingInTask(self.inst.cycletask1info)
        self.inst.cycletask1:Cancel()
        self.inst.cycletask1 = nil
    end
    if self.inst.cycletask2 then
        self.task2time = self.inst:TimeRemainingInTask(self.inst.cycletask2info)
        self.inst.cycletask2:Cancel()
        self.inst.cycletask2 = nil
    end
end

function Cycletimer:Resume()
    if self.task1time then
        self.inst.cycletask1, self.inst.cycletask1info = self.inst:ResumeTask(self.task1time, function() self:StartCycle2() end)
        self.task1time = nil
    end
    if self.task2time then
        self.inst.cycletask2, self.inst.cycletask2info = self.inst:ResumeTask(self.task2time, function() self:StartCycle1() end)
        self.task2time = nil
    end
end

return Cycletimer

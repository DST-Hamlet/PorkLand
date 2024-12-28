-- Modified based on Workable
-- This is used for having multiple workable actions on the same entity
-- If a thing has only hackable as workable action, it should set everything in workable, but also add hackable component for our handlers
-- If a thing has both hackable and another workable action (like ACTIONS.DIG), it can setup things on both components for different handlers

local function onworkable(self)
    if self.inst.components.workable and self.inst.components.workable.action == self.action then
        return
    end
    if self.workleft > 0 then
        self.inst:AddTag(self.action.id.."_workable")
    else
        self.inst:RemoveTag(self.action.id.."_workable")
    end
end

local Hackable = Class(function(self, inst)
    self.inst = inst
    self.onwork = nil
    self.onfinish = nil
    self.workleft = 10
    self.action = ACTIONS.HACK
end,
nil,
{
    workleft = onworkable,
    workable = onworkable,
})

function Hackable:OnRemoveFromEntity()
    if self.inst.components.workable and self.inst.components.workable.action == self.action then
        return
    end
    self.inst:RemoveTag(self.action.id.."_workable")
end

function Hackable:Destroy(destroyer)
    if self:CanBeWorked() then
        self:WorkedBy(destroyer, self.workleft)
    end
end

function Hackable:SetWorkLeft(work)
    self.workleft = math.max(1, work or 10)
end

function Hackable:GetWorkLeft()
    if self.inst.components.workable and self.inst.components.workable.action == self.action then
        return self.inst.components.workable:GetWorkLeft()
    end
    return self.workleft or 0
end

function Hackable:CanBeWorked()
    if self.inst.components.workable and self.inst.components.workable.action == self.action then
        return self.inst.components.workable:CanBeWorked()
    end
    return self.workleft > 0
end

function Hackable:SetOnWorkCallback(fn)
    self.onwork = fn
end

function Hackable:SetOnFinishCallback(fn)
    self.onfinish = fn
end

function Hackable:WorkedBy(worker, numworks)
    if self.inst.components.workable and self.inst.components.workable.action == self.action then
        return self.inst.components.workable:WorkedBy(worker, numworks)
    end

    numworks = numworks or 1
    if self.workmultiplierfn ~= nil then
        numworks = numworks * (self.workmultiplierfn(self.inst, worker, numworks) or 1)
    end
    if numworks > 0 then
        if self.workleft <= 1 then -- if there is less that one full work remaining, then just finish it. This is to handle the case where objects are set to only one work and not planned to handled something like 0.5 numworks
            self.workleft = 0
        else
            self.workleft = self.workleft - numworks
            if self.workleft < 0.01 then -- NOTES(JBK): Floating points are possible with work efficiency modifiers so cut out the epsilon.
                self.workleft = 0
            end
        end
    end
    self.lastworktime = GetTime()

    worker:PushEvent("working", { target = self.inst })
    self.inst:PushEvent("worked", { worker = worker, workleft = self.workleft })

    if self.onwork ~= nil then
        self.onwork(self.inst, worker, self.workleft, numworks)
    end

    if self.workleft <= 0 then
        local isplant =
            self.inst:HasTag("plant") and
            not self.inst:HasTag("burnt") and
            not (self.inst.components.diseaseable ~= nil and self.inst.components.diseaseable:IsDiseased())
        local pos = isplant and self.inst:GetPosition() or nil

        if self.onfinish ~= nil then
            self.onfinish(self.inst, worker)
        end
        self.inst:PushEvent("workfinished", { worker = worker })
        worker:PushEvent("finishedwork", { target = self.inst, action = self.action })
        if isplant then
            TheWorld:PushEvent("plantkilled", { doer = worker, pos = pos, workaction = self.action }) --this event is pushed in other places too
        end
    end
end

return Hackable

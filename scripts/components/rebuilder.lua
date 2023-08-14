local Rebuilder = Class(function(self, inst)
    self.inst = inst

end)

function Rebuilder:Init(setdelay,randdelay)
    self.setdelay = setdelay
    self.randdelay = randdelay
    self.inst:DoPeriodicTask(self.setdelay+(math.random()*self.randdelay),function() print("CHECK") self:Rebuild() end)
end

function Rebuilder:Rebuild()
    print("TEST",self.inst.components.workable.workleft,"<",self.inst.components.workable.maxwork)
    if self.inst.components.workable and self.inst.components.workable.workleft < self.inst.components.workable.maxwork then
        self.inst.components.workable:SetWorkLeft(self.inst.components.workable.workleft +1)
        print("work update")
        if self.rebuildfn then
            print("DO FUNCTIOn")
            self.rebuildfn(self.inst)
        end
    end
end


return Rebuilder

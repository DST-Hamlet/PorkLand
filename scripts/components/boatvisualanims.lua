local BoatVisualAnims = Class(function(self, inst)
    self.inst = inst

    self.prerowanimation = "row_pre"
    self.rowanimation = "row_loop"
    self.postrowanimation = "row_pst"

    self.presailanim = "sail_pre"
    self.sailanim = "sail_loop"
    self.postsailanim = "sail_pst"

    self.trawlover = "trawlover"

    self.idleanim = "idle_loop"
end)

function BoatVisualAnims:OnUpdate(dt)
    if self.update then
        self.update(self.inst, dt)
    end
end

function BoatVisualAnims:PlayPreRowAnims()
    self.inst.AnimState:PlayAnimation(self.prerowanimation)
    if self.prerow then
        self.prerow(self.inst)
    end
end

function BoatVisualAnims:PlayRowAnims()
    if not self.inst.AnimState:IsCurrentAnimation(self.rowanimation) then
        self.inst.AnimState:PlayAnimation(self.rowanimation, true)
    end
    if self.row then
        self.row(self.inst)
    end
end

function BoatVisualAnims:PlayPostRowAnims()
    self.inst.AnimState:PlayAnimation(self.postrowanimation)
    if self.postrow then
        self.postrow(self.inst)
    end
end

function BoatVisualAnims:PlayPreSailAnims()
    self.inst.AnimState:PlayAnimation(self.presailanim)
    if self.presail then
        self.presail(self.inst)
    end
end

function BoatVisualAnims:PlaySailAnims()
    if not self.inst.AnimState:IsCurrentAnimation(self.sailanim) then
        self.inst.AnimState:PlayAnimation(self.sailanim, true)
    end
    if self.sail then
        self.sail(self.inst)
    end
end

function BoatVisualAnims:PlayPostSailAnims()
    self.inst.AnimState:PlayAnimation(self.postsailanim)
    if self.postsail then
        self.postsail(self.inst)
    end
end

function BoatVisualAnims:PlayTrawlOverAnims()
    self.inst.AnimState:PlayAnimation(self.trawlover)
    if self.trawl then
        self.trawl(self.inst)
    end
end

function BoatVisualAnims:PlayIdleAnims(push)
    if push then
        self.inst.AnimState:PushAnimation(self.idleanim, true)
        if self.idle then
            self.idle(self.inst)
        end
        return
    end
    if not self.inst.AnimState:IsCurrentAnimation(self.idleanim) then
        self.inst.AnimState:PlayAnimation(self.idleanim, true)
    end
    if self.idle then
        self.idle(self.inst)
    end
end

return BoatVisualAnims

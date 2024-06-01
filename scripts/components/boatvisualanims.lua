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

    self.hitanim = "hit"

    self.runanim = "run_loop"
end)

function BoatVisualAnims:OnUpdate(dt)
    if self.update then
        self.update(self.inst, dt)
    end
end

function BoatVisualAnims:PlayPreRowAnims()
    self.inst.visualchild.AnimState:PlayAnimation(self.prerowanimation)
    if self.prerow then
        self.prerow(self.inst)
    end
end

function BoatVisualAnims:PlayRowAnims()
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(self.rowanimation) then
        self.inst.visualchild.AnimState:PlayAnimation(self.rowanimation, true)
    end
    if self.row then
        self.row(self.inst)
    end
end

function BoatVisualAnims:PlayPostRowAnims()
    self.inst.visualchild.AnimState:PlayAnimation(self.postrowanimation)
    if self.postrow then
        self.postrow(self.inst)
    end
end

function BoatVisualAnims:PlayPreSailAnims()
    self.inst.visualchild.AnimState:PlayAnimation(self.presailanim)
    if self.presail then
        self.presail(self.inst)
    end
end

function BoatVisualAnims:PlaySailAnims()
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(self.sailanim) then
        self.inst.visualchild.AnimState:PlayAnimation(self.sailanim, true)
    end
    if self.sail then
        self.sail(self.inst)
    end
end

function BoatVisualAnims:PlayPostSailAnims()
    self.inst.visualchild.AnimState:PlayAnimation(self.postsailanim)
    if self.postsail then
        self.postsail(self.inst)
    end
end

function BoatVisualAnims:PlayTrawlOverAnims()
    self.inst.visualchild.AnimState:PlayAnimation(self.trawlover)
    if self.trawl then
        self.trawl(self.inst)
    end
end

function BoatVisualAnims:PlayIdleAnims(push)
    if push then
        self.inst.visualchild.AnimState:PushAnimation(self.idleanim, true)
        if self.idle then
            self.idle(self.inst)
        end
        return
    end
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(self.idleanim) then
        self.inst.visualchild.AnimState:PlayAnimation(self.idleanim, true)
    end
    if self.idle then
        self.idle(self.inst)
    end
end

function BoatVisualAnims:PlayOnHitAnims()
    self.inst.visualchild.AnimState:PlayAnimation(self.hitanim)
    if self.hit then
        self.hit(self.inst)
    end
end

function BoatVisualAnims:PlayRunAnims(push)
    if push then
        self.inst.visualchild.AnimState:PushAnimation(self.runanim, true)
        if self.run then
            self.run(self.inst)
        end
        return
    end
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(self.runanim) then
        self.inst.visualchild.AnimState:PlayAnimation(self.runanim, true)
    end
    if self.run then
        self.run(self.inst)
    end
end

return BoatVisualAnims

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
    self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.prerowanimation)
    if self.prerow then
        self.prerow(self.inst)
    end
end

function BoatVisualAnims:PlayRowAnims()
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.rowanimation) then
        self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.rowanimation, true)
    end
    if self.row then
        self.row(self.inst)
    end
end

function BoatVisualAnims:PlayPostRowAnims()
    self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.postrowanimation)
    if self.postrow then
        self.postrow(self.inst)
    end
end

function BoatVisualAnims:PlayPreSailAnims()
    self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.presailanim)
    if self.presail then
        self.presail(self.inst)
    end
end

function BoatVisualAnims:PlaySailAnims()
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.sailanim) then
        self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.sailanim, true)
    end
    if self.sail then
        self.sail(self.inst)
    end
end

function BoatVisualAnims:PlayPostSailAnims()
    self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.postsailanim)
    if self.postsail then
        self.postsail(self.inst)
    end
end

function BoatVisualAnims:PlayTrawlOverAnims()
    self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.trawlover)
    if self.trawl then
        self.trawl(self.inst)
    end
end

function BoatVisualAnims:PlayIdleAnims(push)
    if push then
        self.inst.visualchild.AnimState:PushAnimation(BOAT_ANIM_NAMES.idleanim, true)
        if self.idle then
            self.idle(self.inst)
        end
        return
    end
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.idleanim) then
        self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.idleanim, true)
    end
    if self.idle then
        self.idle(self.inst)
    end
end

function BoatVisualAnims:PlayOnHitAnims()
    self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.hitanim)
    if self.hit then
        self.hit(self.inst)
    end
end

function BoatVisualAnims:PlayRunAnims(push)
    if push then
        self.inst.visualchild.AnimState:PushAnimation(BOAT_ANIM_NAMES.runanim, true)
        if self.run then
            self.run(self.inst)
        end
        return
    end
    if not self.inst.visualchild.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.runanim) then
        self.inst.visualchild.AnimState:PlayAnimation(BOAT_ANIM_NAMES.runanim, true)
    end
    if self.run then
        self.run(self.inst)
    end
end

function BoatVisualAnims:SetHauntFx(enable)
    self.inst.visualchild.AnimState:SetHaunted(enable)
end

return BoatVisualAnims

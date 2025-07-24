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

function BoatVisualAnims:PlayAnim(animname)
    if LOOP_BOAT_ANIMS[animname] then
        self.inst.visualchild.AnimState:PlayAnimation(animname, true)
    else
        self.inst.visualchild.AnimState:PlayAnimation(animname)
    end
end

function BoatVisualAnims:SetHauntFx(enable)
    self.inst.visualchild.AnimState:SetHaunted(enable)
end

return BoatVisualAnims

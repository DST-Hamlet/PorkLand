local Sailable = Class(function(self, inst)
    self.inst = inst

    self.prerowanimation = "row_pre"
    self.rowanimation = "row_loop"
    self.postrowanimation = "row_pst"

    self.presailanim = "sail_pre"
    self.sailanim = "sail_loop"
    self.postsailanim = "sail_pst"

    self.trawlover = "trawlover"

    self.idleanim = "idle_loop"

    self.creaksound = "dontstarve_DLC002/common/boat/creaks/creaks"

    self.alwayssail = false

    self.basicspeedbonus = 1
end)

function Sailable:PlayPreRowAnims()
    self.inst.AnimState:PlayAnimation(self.prerowanimation)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPreRowAnims()
    end
end

function Sailable:PlayRowAnims()
    if not self.inst.AnimState:IsCurrentAnimation(self.rowanimation) then
        self.inst.AnimState:PlayAnimation(self.rowanimation, true)
    end
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayRowAnims()
    end
end

function Sailable:PlayPostRowAnims()
    self.inst.AnimState:PlayAnimation(self.postrowanimation)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPostRowAnims()
    end
    self:PlayIdleAnims(true)
end

function Sailable:PlayPreSailAnims()
    self.inst.AnimState:PlayAnimation(self.presailanim)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPreSailAnims()
    end
end

function Sailable:PlaySailAnims()
    if not self.inst.AnimState:IsCurrentAnimation(self.sailanim) then
        self.inst.AnimState:PlayAnimation(self.sailanim, true)
    end
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlaySailAnims()
    end
end

function Sailable:PlayPostSailAnims()
    self.inst.AnimState:PlayAnimation(self.postsailanim)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPostSailAnims()
    end
    self:PlayIdleAnims(true)
end

function Sailable:PlayTrawlOverAnims()
    self.inst.AnimState:PlayAnimation(self.trawlover)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayTrawlOverAnims()
    end
    self:PlayIdleAnims(true)
end

function Sailable:PlayIdleAnims(push)
    if push then
        self.inst.AnimState:PushAnimation(self.idleanim, true)
        for k, v in pairs(self.inst.boatvisuals) do
            k.components.boatvisualanims:PlayIdleAnims(true)
        end
        return
    end
    if not self.inst.AnimState:IsCurrentAnimation(self.idleanim) then
        self.inst.AnimState:PlayAnimation(self.idleanim, true)
    end
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayIdleAnims(false)
    end
end

function Sailable:GetIsSailEquipped()
    if self.inst.components.sailable then
        return self.inst.components.sailable:GetIsSailEquipped()
    else
        if self.alwayssail then return true end

        if self.inst.replica.container then
            local equipped = self.inst.replica.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
            if equipped and equipped:HasTag("sail") then
                return true
            end
        end
        return false
    end
end

return Sailable

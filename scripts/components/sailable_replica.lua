local Sailable = Class(function(self, inst)
    self.inst = inst

    self._sailor = net_entity(inst.GUID, "sailable._sailor", "sailordirty")

    self._currentboatanim = net_smallbyte(inst.GUID, "sailable._currentboatanim", "animdirty")
    self._currentboatanim:set_local(BOAT_ANIM_IDS.runanim)
    self._animevent = net_event(inst.GUID, "animeventdirty")
    self._haunt = net_bool(inst.GUID, "sailable._haunt", "hauntdirty")
    self._haunt:set_local(false)
    if not TheWorld.ismastersim then
        inst:ListenForEvent("animeventdirty", function()
            if not (self:GetSailor() and self:GetSailor().sg ~= nil) then -- 无延迟补偿情况下通过这部分代码同步动画
                local boatanim = self._currentboatanim:value()
                if boatanim == BOAT_ANIM_IDS.prerowanimation then
                    self:PlayPreRowAnims()
                elseif boatanim == BOAT_ANIM_IDS.rowanimation then
                    self:PlayRowAnims()
                elseif boatanim == BOAT_ANIM_IDS.postrowanimation then
                    self:PlayPostRowAnims()
                elseif boatanim == BOAT_ANIM_IDS.presailanim then
                    self:PlayPreSailAnims()
                elseif boatanim == BOAT_ANIM_IDS.sailanim then
                    self:PlaySailAnims()
                elseif boatanim == BOAT_ANIM_IDS.postsailanim then
                    self:PlayPostSailAnims()
                elseif boatanim == BOAT_ANIM_IDS.trawlover then
                    self:PlayTrawlOverAnims()
                elseif boatanim == BOAT_ANIM_IDS.hitanim then
                    self:PlayOnHitAnims()
                elseif boatanim == BOAT_ANIM_IDS.runanim then
                    self:PlayRunAnims()
                elseif boatanim == BOAT_ANIM_IDS.runanim_push then
                    self:PlayRunAnims(true)
                elseif boatanim == BOAT_ANIM_IDS.idleanim then
                    self:PlayIdleAnims()
                elseif boatanim == BOAT_ANIM_IDS.idleanim_push then
                    self:PlayIdleAnims(true)
                end
            end
        end)
        inst:ListenForEvent("hauntdirty", function()
            self:UpdateHaunt()
        end)
    end

    self.creaksound = "dontstarve_DLC002/common/boat_creaks"

    self.alwayssail = false

    self.basicspeedbonus = 1
end)

function Sailable:GetSailor()
    if self.inst.components.sailable then
        return self.inst.components.sailable.sailor
    else
        return self._sailor:value()
    end
end

function Sailable:PlayPreRowAnims()
    if TheWorld.ismastersim then
        self._currentboatanim:set(BOAT_ANIM_IDS.prerowanimation)
        self._animevent:push()
    end
    self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.prerowanimation)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPreRowAnims()
    end
end

function Sailable:PlayRowAnims()
    if not self.inst.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.rowanimation) then
        if TheWorld.ismastersim then
            self._currentboatanim:set(BOAT_ANIM_IDS.rowanimation)
            self._animevent:push()
        end
        self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.rowanimation, true)
    end
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayRowAnims()
    end
end

function Sailable:PlayPostRowAnims()
    if TheWorld.ismastersim then
        self._currentboatanim:set(BOAT_ANIM_IDS.postrowanimation)
        self._animevent:push()
    end
    self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.postrowanimation)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPostRowAnims()
    end
    self:PlayIdleAnims(true)
end

function Sailable:PlayPreSailAnims()
    if TheWorld.ismastersim then
        self._currentboatanim:set(BOAT_ANIM_IDS.presailanim)
        self._animevent:push()
    end
    self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.presailanim)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPreSailAnims()
    end
end

function Sailable:PlaySailAnims()
    if TheWorld.ismastersim then
        self._currentboatanim:set(BOAT_ANIM_IDS.sailanim)
        self._animevent:push()
    end
    if not self.inst.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.sailanim) then
        self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.sailanim, true)
    end
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlaySailAnims()
    end
end

function Sailable:PlayPostSailAnims()
    if TheWorld.ismastersim then
        self._currentboatanim:set(BOAT_ANIM_IDS.postsailanim)
        self._animevent:push()
    end
    self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.postsailanim)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayPostSailAnims()
    end
    self:PlayIdleAnims(true)
end

function Sailable:PlayTrawlOverAnims()
    if TheWorld.ismastersim then
        self._currentboatanim:set(BOAT_ANIM_IDS.trawlover)
        self._animevent:push()
    end
    self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.trawlover)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayTrawlOverAnims()
    end
    self:PlayIdleAnims(true)
end

function Sailable:PlayIdleAnims(push)
    if push then
        if TheWorld.ismastersim then
            self._currentboatanim:set(BOAT_ANIM_IDS.idleanim_push)
            self._animevent:push()
        end
        self.inst.AnimState:PushAnimation(BOAT_ANIM_NAMES.idleanim, true)
        for k, v in pairs(self.inst.boatvisuals) do
            k.components.boatvisualanims:PlayIdleAnims(true)
        end
        return
    end
    if not self.inst.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.idleanim) then
        if TheWorld.ismastersim then
            self._currentboatanim:set(BOAT_ANIM_IDS.idleanim)
            self._animevent:push()
        end
        self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.idleanim, true)
    end
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayIdleAnims(false)
    end
end

function Sailable:PlayOnHitAnims()
    if TheWorld.ismastersim then
        self._currentboatanim:set(BOAT_ANIM_IDS.hitanim)
        self._animevent:push()
    end
    self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.hitanim)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayOnHitAnims()
    end
    self:PlayRunAnims(true)
end

function Sailable:PlayRunAnims(push)
    if push then
        if TheWorld.ismastersim then
            self._currentboatanim:set(BOAT_ANIM_IDS.runanim_push)
            self._animevent:push()
        end
        self.inst.AnimState:PushAnimation(BOAT_ANIM_NAMES.runanim, true)
        for k, v in pairs(self.inst.boatvisuals) do
            k.components.boatvisualanims:PlayRunAnims(true)
        end
        return
    end
    if not self.inst.AnimState:IsCurrentAnimation(BOAT_ANIM_NAMES.runanim) then
        if TheWorld.ismastersim then
            self._currentboatanim:set(BOAT_ANIM_IDS.runanim)
            self._animevent:push()
        end
        self.inst.AnimState:PlayAnimation(BOAT_ANIM_NAMES.runanim, true)
    end
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayRunAnims(false)
    end
end

function Sailable:UpdateHaunt(enable)
    local _enable = self._haunt:value()
    if enable ~= nil then
        _enable = enable
    end
    if TheWorld.ismastersim then
        self._haunt:set(_enable)
    end
    self.inst.AnimState:SetHaunted(_enable)
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:SetHauntFx(_enable)
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

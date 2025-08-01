local Sailable = Class(function(self, inst)
    self.inst = inst

    self._sailor = net_entity(inst.GUID, "sailable._sailor", "sailordirty")

    self._currentboatanim = net_smallbyte(inst.GUID, "sailable._currentboatanim", "animdirty")
    self._currentboatanim:set(BOAT_ANIM_IDS["run_loop"])

    self._haunt = net_bool(inst.GUID, "sailable._haunt", "hauntdirty")
    self._haunt:set(false)

    if not TheWorld.ismastersim then
        inst:ListenForEvent("animdirty", function()
            if self:CheckIsPredict() then
                return
            end

            self.is_predict = false

            local boatanim = BOAT_ID_TO_ANIM[self._currentboatanim:value()]
            self:PlayAnim(boatanim)
        end)
        inst:ListenForEvent("hauntdirty", function()
            self:UpdateHaunt()
        end)

        self.is_predict = false

        self.inst:StartUpdatingComponent(self)
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

function Sailable:PlayAnim(animname)
    if BOAT_ANIM_IDS[animname] == nil then
        return
    end

    if TheWorld.ismastersim then
        if LOOP_BOAT_ANIMS[animname] then
            self.inst.AnimState:PlayAnimation(animname, true) -- 虽然船实体本身的动画会因为没有build而不显示，但是可以用作同步数据
        else
            self.inst.AnimState:PlayAnimation(animname)
        end
        self._currentboatanim:set_local(0) -- 这样可以强制网络同步事件触发
        self._currentboatanim:set(BOAT_ANIM_IDS[animname])
    end

    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:PlayAnim(animname)
    end
end

function Sailable:ClientPlayAnim(animname)
    if not self:CheckIsPredict() then
        return
    end
    self.is_predict = true
    self:PlayAnim(animname)
end

function Sailable:SetAnimFrame(frame) -- 仅本地，无网络同步效果
    for k, v in pairs(self.inst.boatvisuals) do
        k.components.boatvisualanims:SetAnimFrame(frame)
    end
end

function Sailable:CheckIsPredict()
    if self:GetSailor() and self:GetSailor().sg then -- 是否开启本地延迟补偿
        if not self:GetSailor():HasAnyTag({"nopredict", "pausepredict"}) then -- 本地延迟补偿是否被特定state覆盖
            return true
        end
    end
end

function Sailable:RefreshClientAnim()
    self.is_predict = false

    local startanim = "run_loop"
    for animname, _ in pairs(BOAT_ANIM_IDS) do
        if self.inst.AnimState:IsCurrentAnimation(animname) then
            startanim = animname
            break
        end
    end
    self:PlayAnim(startanim)
    
    local startanimframe = self.inst.AnimState:GetCurrentAnimationFrame() or 0
    self:SetAnimFrame(startanimframe)
end

function Sailable:OnUpdate()
    if self.is_predict == false and self:CheckIsPredict() then -- 客户端启用了延迟补偿，且客户端还没有播放过预测动画，则默认使用idle_loop作为预测动画
        self:ClientPlayAnim("idle_loop")
    elseif self.is_predict == true and not self:CheckIsPredict() then -- 客户端停用了延迟补偿，且客户端仍在播放预测动画，则默认同步船本体的动画
        self:RefreshClientAnim()
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

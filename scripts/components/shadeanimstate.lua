local ShadeAnimState = Class(function(self, inst)
    self.inst = inst

    self.currentframe = 0

    self.currentshadeanimdata = nil

    self.currentanim = nil

    self.scale = 10

    self._currentanim = net_string(inst.GUID, "shadeanimstate._currentanim", "currentanimdirty")
    self._isloop = net_bool(inst.GUID, "shadeanimstate._isloop", "isloopdirty")
    self._scale = net_float(inst.GUID, "shadeanimstate._scale", "scaledirty")
    self._scale:set(10)

    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("currentanimdirty", function()
            self.currentanim = self._currentanim:value()
            self.currentframe = 0
            self:SpawnNewFrame()
        end)
        self.inst:ListenForEvent("scaledirty", function()
            self.scale = self._scale:value()
        end)
    end

    inst:StartUpdatingComponent(self)
end)

function ShadeAnimState:PlayAnimation(anim, loop)
    self.currentanim = anim
    self.currentframe = 0

    self._isloop:set(loop or false)
    self._currentanim:set(anim)

    self:SpawnNewFrame()
end

function ShadeAnimState:ClearCurrentFrame()
    if self.currentshadeanimdata then
        RemoveAnimShadeRenderer(self.currentshadeanimdata.type, self.currentshadeanimdata.frame, self.currentshadeanimdata.id)
        self.currentshadeanimdata = nil
    end
end

function ShadeAnimState:OnRemoveFromEntity()
    self:ClearCurrentFrame()
end

function ShadeAnimState:OnRemoveEntity()
    self:ClearCurrentFrame()
end

function ShadeAnimState:SpawnNewFrame()
    self:ClearCurrentFrame()
    if self.currentanim then
        local animation = AnimShadeRenderers[self.currentanim]
        if self.currentframe > animation.length then
            self.currentframe = 0
        end
        local id = SpawnAnimShadeRenderer(self.currentanim,
            self.currentframe,
            self.inst:GetPosition(),
            self.inst:GetRotation(),
            self.scale)
        self.currentshadeanimdata =
        {
            type = self.currentanim,
            frame = self.currentframe,
            id = id,
        }
    end
end

function ShadeAnimState:OnUpdate()
    if self.currentanim then
        self:SpawnNewFrame()
        local animation = AnimShadeRenderers[self.currentanim]
        if self._isloop:value() then
            self.currentframe = self.currentframe + 1
        elseif self.currentframe < animation.length then
            self.currentframe = self.currentframe + 1
        end
    end
end

return ShadeAnimState

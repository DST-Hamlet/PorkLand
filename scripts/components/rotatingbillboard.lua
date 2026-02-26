-- animation render implement for `SetOrientation(ANIM_ORIENTATION.RotatingBillboard)` in DS Porkland
--
-- NOTE:
-- use this feature as less as possible!
-- 1. don't use with Follower:FollowSymbol() (tracker will not work)
-- 2. don't use when camera is locked (use Transform:SetTwoFaced() instead)
-- 3. don't use when accurate interaction behavior is needed
-- 4. never use with AnimState:SetBloomEffectHandle()
-- 5. never use with object that pos.y ~= 0

local function UpdateAnim(inst)
    inst.components.rotatingbillboard:UpdateAnim()
end

local function CheckHaunt(inst)
    if inst.components.rotatingbillboard._haunt_active:value() then
        inst.components.rotatingbillboard:StartHaunt()
    else
        inst.components.rotatingbillboard:StopHaunt()
    end
end

local RotatingBillboard = Class(function(self, inst)
    self.inst = inst
    self._rotation_net = net_float(inst.GUID, "rotatingbillboard.rotation_net", "rotationdirty")
    self.rotation = 0

    self._haunt_active = net_bool(inst.GUID, "_haunt_active", "hauntdirty")
    self.current_haunt = 0
    self.haunt_speed = -1

    self.animdata = {}

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/animrotatingbillboard.ksh"))
    inst.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/animrotatingbillboard_bloom_haunt.ksh"))

    if not TheWorld.ismastersim then
        inst:ListenForEvent("rotationdirty", UpdateAnim)

        inst:ListenForEvent("hauntdirty", CheckHaunt)
    end
end, nil)

function RotatingBillboard:GetRotation()
    if TheWorld.ismastersim then
        return self.rotation
    else
        return self._rotation_net:value()
    end
end

function RotatingBillboard:UpdateAnim()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    self.pos = Vector3(x, y, z)
    self.inst.AnimState:SetFloatParams(x, z, self:GetRotation() * DEGREES + PI)
end

function RotatingBillboard:SetRotation(rotation)
    self.rotation = rotation
    self._rotation_net:set(rotation)
    UpdateAnim(self.inst)
end

function RotatingBillboard:SetHaunt(active)
    self._haunt_active:set(active)
    CheckHaunt(self.inst)
end

function RotatingBillboard:StartHaunt()
    self.haunt_speed = 1
    self.inst:StartUpdatingComponent(self)
end

function RotatingBillboard:StopHaunt()
    self.haunt_speed = -1
    self.inst:StartUpdatingComponent(self)
end

function RotatingBillboard:OnUpdate(dt)
    self.current_haunt = self.current_haunt + self.haunt_speed * dt
    self.current_haunt = math.max(math.min(self.current_haunt, 1), 0)
    self.inst.AnimState:SetOceanBlendParams(self.current_haunt)
    if self.current_haunt == 1 or self.current_haunt == 0 then
        self.inst:StopUpdatingComponent(self)
    end
end

function RotatingBillboard:OnSave()
    return {
        add_component_if_missing = true,
        rotation = self.rotation
    }
end

function RotatingBillboard:OnLoad(data)
    if data and data.rotation and data.rotation ~= 0 then
        self.inst.Transform:SetRotation(data.rotation)
    end
end

function RotatingBillboard:OnRemoveFromEntity()
    self.inst.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard)
    self.inst.AnimState:SetDefaultEffectHandle("")
end

RotatingBillboard.OnRemoveEntity = RotatingBillboard.OnRemoveFromEntity

return RotatingBillboard

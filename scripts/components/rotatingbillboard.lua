-- animation render implement for `SetOrientation(ANIM_ORIENTATION.RotatingBillboard)` in DS Porkland
--
-- NOTE:
-- use this feature as less as possible!
-- 1. don't use with Follower:FollowSymbol() (tracker will not work)
-- 2. don't use when camera is locked (use Transform:SetTwoFaced() instead)
-- 3. don't use when accurate interaction behavior is needed
-- 4. never use with AnimState:SetBloomEffectHandle()
-- 5. never use with object that pos.y ~= 0

local function Mask(parent)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst:AddTag("noblock")
    inst:AddTag("rotatingbillboard_mask")
    inst.AnimState:SetMultColour(0, 0, 0, 0)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MIN)
    inst.Transform:SetTwoFaced()

    inst.persists = false
    inst.parent = parent
    inst.entity:SetParent(parent.entity)

    return inst
end

local function CanMouseThrough(inst)
    if inst:IsValid() then
    	local mask = inst.components.rotatingbillboard ~= nil
		    	 and inst.components.rotatingbillboard:GetMask()
		if mask and mask:IsValid() then
	        for i,v in ipairs(TheInput.entitiesundermouse) do
	            if v == mask then
	                return false
	            end
	        end
	    end
    end
    return true, true
end

local RotatingBillboard = Class(function(self, inst)
	self.inst = inst
	self.rotation_net = net_float(inst.GUID, "rotatingbillboard.rotation_net", "rotatingbillboard.rotation_net")
	self.rotation = 0
	self.always_on_updating = false
    self.setted = false -- 用于判断是否在实体生成后至少传入一次立体参数

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/animrotatingbillboard.ksh"))
	inst:StartUpdatingComponent(self)

	if not TheNet:IsDedicated() then
	    self.mask = Mask(inst)
	    inst.CanMouseThrough = CanMouseThrough
	    inst:DoTaskInTime(0, function() self:SyncMaskAnimation() end)
	end

	if not TheNet:GetIsServer() then
		inst:ListenForEvent("rotatingbillboard.rotation_net", function()
			inst:DoTaskInTime(0, function()
				self:SetRotation(self.rotation_net:value())
			end)
		end)
	end
end, nil, {
	rotation = function(self, value)
		if TheWorld.ismastersim then
			self.rotation_net:set(value)
		end
	end,
})

function RotatingBillboard:GetMask()
	return self.mask
end

function RotatingBillboard:SyncMaskAnimation()
	if self.mask  then
		if self.inst:HasTag("NOCLICK") then
			self.mask:AddTag("NOCLICK")
		else
			self.mask:RemoveTag("NOCLICK")
		end
		local data = self.animdata or {}
		local anim = self.mask.AnimState
		anim:SetBank(data.bank or self.inst.AnimState:GetCurrentBankName())
		anim:SetBuild(data.build or self.inst.AnimState:GetBuild())
		local animation = data.animation or select(2, self.inst.AnimState:GetHistoryData())
		if not anim:IsCurrentAnimation(animation) then
			anim:PlayAnimation(animation)
		end
	end
end

function RotatingBillboard:GetRotation()
	return self.rotation
end

function RotatingBillboard:SetRotation(rot)
	self.rotation = rot
    self.setted = true
	local x, _, z = self.inst.Transform:GetWorldPosition()
	self.inst.AnimState:SetFloatParams(x, z, rot* DEGREES + PI)

	self:UpdateLightPosition()
end

function RotatingBillboard:UpdateLightPosition()
	if self.inst.swinglight ~= nil and self.inst.swinglight:IsValid() then -- see pl_deco_util
		local offset = self.inst.swinglight
		print("Setup light", offset)
		self.inst.swinglight.Transform:SetPosition(offset.x, offset.y,
			(self.rotation > 0 and 1 or -1)* offset.z)
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
		self.inst:StartUpdatingComponent(self)
	end
end

function RotatingBillboard:OnUpdate()
	local rot = self.inst.Transform:GetRotation()
	if rot ~= 0 or not self.setted then
		self:SetRotation(rot)
		self.inst.Transform:SetRotation(0) -- set transform rot to 0 to make anim align to xz
	end

	if not self.always_on_updating then
		self.inst:StopUpdatingComponent(self)
	end
end

function RotatingBillboard:OnRemoveFromEntity()
	if self.mask and self.mask:IsValid() then
		self.mask:Remove()
	end

	self.inst.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard)
	self.inst.AnimState:SetDefaultEffectHandle("")
end

RotatingBillboard.OnRemoveEntity = RotatingBillboard.OnRemoveFromEntity

return RotatingBillboard

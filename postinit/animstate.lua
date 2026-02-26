GLOBAL.setfenv(1, GLOBAL)

local PLAYER_REPLACE_ANIMS =
{
    ["wilson"] =
    {
        ["atk_pre"] = "atk_pre_old",
        ["atk_lag"] = "atk_lag_old",
        ["atk"] = "atk_old",
        ["hit"] = "hit_old",
        ["hit_goo"] = "hit_goo_old",
        ["idle_inaction_sanity"] = "idle_inaction_sanity_fixed",
    }
}

AnimState_Player = Class(function(self, inst)
    self.inst = inst
    self._AnimState = inst.AnimState
    inst.AnimState = self
end)

for k, v in pairs(AnimState) do
    AnimState_Player[k] = function(self, ...)
        return v(self._AnimState, ...)
    end
end

local _SetBank = AnimState.SetBank
function AnimState_Player:SetBank(bank, ...)
    self.bank = bank
    return _SetBank(self._AnimState, bank, ...)
end

local _PlayAnimation = AnimState.PlayAnimation
AnimState_Player.PlayAnimation = function(self, animname, ...)
    if PLAYER_REPLACE_ANIMS[self.bank] and PLAYER_REPLACE_ANIMS[self.bank][animname] then
        return _PlayAnimation(self._AnimState, PLAYER_REPLACE_ANIMS[self.bank][animname], ...)
    else
        return _PlayAnimation(self._AnimState, animname, ...)
    end
end

local _PushAnimation = AnimState.PushAnimation
AnimState_Player.PushAnimation = function(self, animname, ...)
    if PLAYER_REPLACE_ANIMS[self.bank] and PLAYER_REPLACE_ANIMS[self.bank][animname] then
        return _PushAnimation(self._AnimState, PLAYER_REPLACE_ANIMS[self.bank][animname], ...)
    else
        return _PushAnimation(self._AnimState, animname, ...)
    end
end

local _IsCurrentAnimation = AnimState.IsCurrentAnimation
AnimState_Player.IsCurrentAnimation = function(self, animname, ...)
    if PLAYER_REPLACE_ANIMS[self.bank] and PLAYER_REPLACE_ANIMS[self.bank][animname] then
        return _IsCurrentAnimation(self._AnimState, PLAYER_REPLACE_ANIMS[self.bank][animname], ...)
    else
        return _IsCurrentAnimation(self._AnimState, animname, ...)
    end
end

AnimState_Player._Hide = AnimState_Player.Hide
AnimState_Player.Hide = function(self, layername, ...)
    if self.Anim_Hide_Hook then
        return self.Anim_Hide_Hook(self, layername, ...)
    end
    return AnimState_Player._Hide(self._AnimState, layername, ...)
end

AnimState_Player._Show = AnimState_Player.Show
AnimState_Player.Show = function(self, layername, ...)
    if self.Anim_Show_Hook then
        return self.Anim_Show_Hook(self, layername, ...)
    end
    return AnimState_Player._Show(self._AnimState, layername, ...)
end

----------------------------------------------------------------------------------

Transform_RotatingBillBoard = Class(function(self, inst)
    self.inst = inst
    self._Transform = inst.Transform
    inst.Transform = self
end)

for k, v in pairs(Transform) do
    Transform_RotatingBillBoard[k] = function(self, ...)
        return v(self._Transform, ...)
    end
end

Transform_RotatingBillBoard._SetRotation = Transform_RotatingBillBoard.SetRotation
Transform_RotatingBillBoard.SetRotation = function(self, rot, ...)
    self.inst.components.rotatingbillboard:SetRotation(rot)
    self:_SetRotation(0, ...)
end

Transform_RotatingBillBoard._GetRotation = Transform_RotatingBillBoard.GetRotation
Transform_RotatingBillBoard.GetRotation = function(self, ...)
    return self.inst.components.rotatingbillboard:GetRotation()
end

local _SetPosition = Transform.SetPosition
Transform_RotatingBillBoard.SetPosition = function(self, ...)
    _SetPosition(self._Transform, ...)
    self.inst.components.rotatingbillboard:UpdateAnim()
end

local function UpdateAnim_RotatingBillboard(inst)
    inst.components.rotatingbillboard:UpdateAnim()
end

local function OnReplica_RotatingBillboard(inst)
    inst:RunOnPostUpdate(UpdateAnim_RotatingBillboard)
end

AnimState_RotatingBillBoard = Class(function(self, inst)

    Transform_RotatingBillBoard(inst)

    self.inst = inst
    self._AnimState = inst.AnimState
    inst.AnimState = self

    inst:AddComponent("rotatingbillboard")
    inst.Transform:SetRotation(inst.Transform:_GetRotation())

    inst:AddOnReplicatedPost(OnReplica_RotatingBillboard)
end)

for k, v in pairs(AnimState) do
    AnimState_RotatingBillBoard[k] = function(self, ...)
        return v(self._AnimState, ...)
    end
end

AnimState_RotatingBillBoard.SetHaunted = function(self, haunted, ...)
    self.inst.components.rotatingbillboard:SetHaunt(haunted, ...)
end
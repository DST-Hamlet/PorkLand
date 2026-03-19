GLOBAL.setfenv(1, GLOBAL)

local AnimState_Hooked = {
    __index = function(t, key)
        local function forwarded(self, ...)
            local original = self.inst.Old_AnimState[key]
            return original(self.inst.Old_AnimState, ...)
        end
        t[key] = forwarded
        return forwarded
    end
}

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

local AnimState_Player = {}
AnimState_Player.__index = AnimState_Player
setmetatable(AnimState_Player, AnimState_Hooked)

function MakeAnimStatePlayer(inst)
    local new_AnimState = {inst = inst}
    setmetatable(new_AnimState, AnimState_Player)
    inst.Old_AnimState = inst.AnimState
    inst.AnimState = new_AnimState
end

function AnimState_Player:SetBank(bank, ...)
    self.bank = bank
    return self.inst.Old_AnimState:SetBank(bank, ...)
end

AnimState_Player.PlayAnimation = function(self, animname, ...)
    if PLAYER_REPLACE_ANIMS[self.bank] and PLAYER_REPLACE_ANIMS[self.bank][animname] then
        return self.inst.Old_AnimState:PlayAnimation(PLAYER_REPLACE_ANIMS[self.bank][animname], ...)
    else
        return self.inst.Old_AnimState:PlayAnimation(animname, ...)
    end
end

AnimState_Player.PushAnimation = function(self, animname, ...)
    if PLAYER_REPLACE_ANIMS[self.bank] and PLAYER_REPLACE_ANIMS[self.bank][animname] then
        return self.inst.Old_AnimState:PushAnimation(PLAYER_REPLACE_ANIMS[self.bank][animname], ...)
    else
        return self.inst.Old_AnimState:PushAnimation(animname, ...)
    end
end

local _IsCurrentAnimation = AnimState.IsCurrentAnimation
AnimState_Player.IsCurrentAnimation = function(self, animname, ...)
    if PLAYER_REPLACE_ANIMS[self.bank] and PLAYER_REPLACE_ANIMS[self.bank][animname] then
        return self.inst.Old_AnimState:IsCurrentAnimation(PLAYER_REPLACE_ANIMS[self.bank][animname], ...)
    else
        return self.inst.Old_AnimState:IsCurrentAnimation(animname, ...)
    end
end

AnimState_Player.Hide = function(self, layername, ...)
    if layername == "HAIR" then
        self.inst.Old_AnimState:Hide("HAIRFRONT")
    end
    return self.inst.Old_AnimState:Hide(layername, ...)
end

AnimState_Player.Show = function(self, layername, ...)
    if layername == "HAIR" then
        self.inst.Old_AnimState:Show("HAIRFRONT")
    end
    return self.inst.Old_AnimState:Show(layername, ...)
end

----------------------------------------------------------------------------------


local Transform_Hooked = {
    __index = function(t, key)
        local function forwarded(self, ...)
            local original = self.inst.Old_Transform[key]
            return original(self.inst.Old_Transform, ...)
        end
        t[key] = forwarded
        return forwarded
    end
}

local Transform_RotatingBillBoard = {}
Transform_RotatingBillBoard.__index = Transform_RotatingBillBoard
setmetatable(Transform_RotatingBillBoard, Transform_Hooked)

Transform_RotatingBillBoard.SetRotation = function(self, rot, ...)
    self.inst.components.rotatingbillboard:SetRotation(rot)
    return self.inst.Old_Transform:SetRotation(0, ...)
end

Transform_RotatingBillBoard.GetRotation = function(self, ...)
    return self.inst.components.rotatingbillboard:GetRotation()
end

Transform_RotatingBillBoard.SetPosition = function(self, ...)
    self.inst.Old_Transform:SetPosition(...)
    self.inst.components.rotatingbillboard:UpdateAnim()
end

function MakeTransformRotatingBillBoard(inst)
    local new_Transform = {inst = inst}
    setmetatable(new_Transform, Transform_RotatingBillBoard)
    inst.Old_Transform = inst.Transform
    inst.Transform = new_Transform
end


local AnimState_RotatingBillBoard = {}
AnimState_RotatingBillBoard.__index = AnimState_RotatingBillBoard
setmetatable(AnimState_RotatingBillBoard, AnimState_Hooked)

AnimState_RotatingBillBoard.SetHaunted = function(self, ...)
    self.inst.components.rotatingbillboard:SetHaunt(haunted, ...)
end

local function UpdateAnim_RotatingBillboard(inst)
    inst.components.rotatingbillboard:UpdateAnim()
end

local function OnReplica_RotatingBillboard(inst)
    inst:RunOnPostUpdate(UpdateAnim_RotatingBillboard)
end

function MakeAnimStateRotatingBillBoard(inst)
    MakeTransformRotatingBillBoard(inst)

    local new_AnimState = {inst = inst}
    setmetatable(new_AnimState, AnimState_RotatingBillBoard)
    inst.Old_AnimState = inst.AnimState
    inst.AnimState = new_AnimState

    inst:AddComponent("rotatingbillboard")
    inst.Transform:SetRotation(inst.Old_Transform:GetRotation())

    inst:AddOnReplicatedPost(OnReplica_RotatingBillboard)
end
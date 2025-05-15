GLOBAL.setfenv(1, GLOBAL)

local REPLACE_ANIMS =
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

local anim_to_entity = {}

local animstate_banks = {}

local function clean_up_mapping(inst)
    if inst.AnimState then
        anim_to_entity[inst.AnimState] = nil
        animstate_banks[inst.AnimState] = nil
    end
end

local _AddAnimState = Entity.AddAnimState
function Entity:AddAnimState(...)
    local animstate = _AddAnimState(self, ...)

    local guid = self:GetGUID()
    local inst = Ents[guid]
    anim_to_entity[animstate] = inst
    inst:ListenForEvent("onremove", clean_up_mapping)

    return animstate
end

local _SetBank = AnimState.SetBank
function AnimState:SetBank(bank, ...)
    animstate_banks[self] = bank
    return _SetBank(self, bank, ...)
end

local _PlayAnimation = AnimState.PlayAnimation
AnimState.PlayAnimation = function(self, animname, ...)
    local bank = animstate_banks[self]
    if REPLACE_ANIMS[bank] and REPLACE_ANIMS[bank][animname] then
        return _PlayAnimation(self, REPLACE_ANIMS[bank][animname], ...)
    else
        return _PlayAnimation(self, animname, ...)
    end
end

local _PushAnimation = AnimState.PushAnimation
AnimState.PushAnimation = function(self, animname, ...)
    local bank = animstate_banks[self]
    if REPLACE_ANIMS[bank] and REPLACE_ANIMS[bank][animname] then
        return _PushAnimation(self, REPLACE_ANIMS[bank][animname], ...)
    else
        return _PushAnimation(self, animname, ...)
    end
end

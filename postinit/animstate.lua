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

local hash_to_bank = {}

local anim_to_entity = {}

local function clean_up_mapping(inst)
    if inst.AnimState then
        anim_to_entity[inst.AnimState] = nil
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
    local ret = _SetBank(self, bank, ...)
    hash_to_bank[self:GetBankHash()] = bank
    return ret
end

local _PlayAnimation = AnimState.PlayAnimation
AnimState.PlayAnimation = function(self, animname, ...)
    local bank = hash_to_bank[self:GetBankHash()]
    if REPLACE_ANIMS[bank] and REPLACE_ANIMS[bank][animname] then
        return _PlayAnimation(self, REPLACE_ANIMS[bank][animname], ...)
    else
        return _PlayAnimation(self, animname, ...)
    end
end

local _PushAnimation = AnimState.PushAnimation
AnimState.PushAnimation = function(self, animname, ...)
    local bank = hash_to_bank[self:GetBankHash()]
    if REPLACE_ANIMS[bank] and REPLACE_ANIMS[bank][animname] then
        return _PushAnimation(self, REPLACE_ANIMS[bank][animname], ...)
    else
        return _PushAnimation(self, animname, ...)
    end
end

AnimState._Hide = AnimState.Hide
AnimState.Hide = function(self, layername, ...)
    local inst = anim_to_entity[self]
    if inst and inst.Anim_Hide_Hook then
        return inst.Anim_Hide_Hook(self, layername, ...)
    end
    return AnimState._Hide(self, layername, ...)
end

AnimState._Show = AnimState.Show
AnimState.Show = function(self, layername, ...)
    local inst = anim_to_entity[self]
    if inst and inst.Anim_Show_Hook then
        return inst.Anim_Show_Hook(self, layername, ...)
    end
    return AnimState._Show(self, layername, ...)
end
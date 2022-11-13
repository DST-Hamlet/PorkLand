GLOBAL.setfenv(1, GLOBAL)

local animstate_overrides = {}

local _OverrideSymbol = AnimState.OverrideSymbol
function AnimState:OverrideSymbol(symbol, build, swap_symbol, ...)
    animstate_overrides[self] = animstate_overrides[self] or {}
    animstate_overrides[self][symbol] = {build, swap_symbol}
    return _OverrideSymbol(self, symbol, build, swap_symbol, ...)
end

local _OverrideItemSkinSymbol = AnimState.OverrideItemSkinSymbol
function AnimState:OverrideItemSkinSymbol(symbol, skin_build, build, param, swap_symbol, ...)
    animstate_overrides[self] = animstate_overrides[self] or {}
    animstate_overrides[self][symbol] = {build, swap_symbol, skin_build, param}
    return _OverrideItemSkinSymbol(self, symbol, skin_build, build, param, swap_symbol, ...)
end

local _ClearOverrideSymbol = AnimState.ClearOverrideSymbol
function AnimState:ClearOverrideSymbol(symbol, ...)
    if animstate_overrides[self] and animstate_overrides[self][symbol] then
        animstate_overrides[self][symbol] = nil
    end
    _ClearOverrideSymbol(self, symbol, ...)
end

local _ClearAllOverrideSymbols = AnimState.ClearAllOverrideSymbols
function AnimState:ClearAllOverrideSymbols(...)
    animstate_overrides[self] = {}
    return _ClearAllOverrideSymbols(self, ...)
end

function AnimState:GetSymbolOverrideTable(symbol)
    return animstate_overrides[self] ~= nil and animstate_overrides[self][symbol] or nil
end

local _Remove = EntityScript.Remove
function EntityScript:Remove(...)
    if self.AnimState then
        animstate_overrides[self.AnimState] = nil
    end
    return _Remove(self, ...)
end

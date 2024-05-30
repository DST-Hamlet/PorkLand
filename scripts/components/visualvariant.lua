local VARIANTS = require("prefabs/visualvariant_defs").VARIANTS

local function TryReCalculate(inst)
    if inst and inst:IsValid() and inst.components.visualvariant and not inst.components.visualvariant.variant then
        inst.components.visualvariant:ReCalculate()
    end
end

local VisualVariant = Class(function(self, inst)
    self.inst = inst

    -- self.variant = "default"
    self.variants = nil

    self.inst:DoTaskInTime(0, TryReCalculate)
end)

function VisualVariant:SetVariantData(prefab)
    self.variants = VARIANTS[prefab]
end

function VisualVariant:GetVariantData(variant)
    return self.variants[variant] or {}
end

function VisualVariant:GetVariant()
    return self.variant
end

function VisualVariant:SetVariant(variant)
    variant = variant or "default"

    local old_variant = self.variant
    if old_variant == variant then
        return
    end

    self.variant = variant

    local old_variant_data = self:GetVariantData(old_variant)
    local variant_data = self:GetVariantData(variant)
    if variant_data.name then
        -- TODO: This is causing odd desync issues and im not sure why -Half
        -- if variant_data.name == "default" then
        --     if self.inst.components.named then
        --         if self.inst.components.named.possiblenames and #self.inst.components.named.possiblenames > 0 then
        --             self.inst.components.named:PickNewName()
        --         else
        --             self.inst.components.named:SetName()
        --         end
        --     end
        -- else
        --     if not self.inst.components.named then
        --         self.inst:AddComponent("named")
        --     end
        --     self.inst.components.named:SetName(STRINGS.NAMES[string.upper(variant_data.name)])
        -- end
    end
    if self.inst.AnimState then
        if old_variant_data.override ~= nil then
            for _,data in pairs(old_variant_data.override) do
                self.inst.AnimState:ClearOverrideSymbol(data.symbol)
            end
        end
        if variant_data.build then
            self.inst.AnimState:SetBuild(variant_data.build)
        end
        if variant_data.bank then
            self.inst.AnimState:SetBank(variant_data.bank)
        end
        if variant_data.override ~= nil then
            for _, data in pairs(variant_data.override) do
                self.inst.AnimState:OverrideSymbol(data.symbol, data.build, data.new_symbol)
            end
        end
    end

    if variant_data.minimap then
        self.inst.MiniMapEntity:SetIcon(variant_data.minimap)
    end

    -- if items try to stack as soon as they spawn, they might not have a classified (apparently) -M
    if variant_data.inv_image and self.inst.replica.inventoryitem and self.inst.replica.inventoryitem.classified then
        if variant_data.inv_image == "default" then
            self.inst.components.inventoryitem:ChangeImageName()
        else
            self.inst.components.inventoryitem:ChangeImageName(variant_data.inv_image)
        end
    end
end

function VisualVariant:ReCalculate()
    if TheWorld:HasTag("porkland") then
        self:SetVariant("porkland")
    else
        self:SetVariant()
    end
end

function VisualVariant:OnSave()
    return {
        variant = self.variant,
    }
end

function VisualVariant:OnLoad(data)
    if not data then
        return
    end

    local variant = data.variant or self.variant
    if variant then
        self:SetVariant(variant)
    else
        self:Recalc()
    end
end

return VisualVariant

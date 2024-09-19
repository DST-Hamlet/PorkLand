local Renovator = Class(function(self, inst)
    self.inst = inst
end)

function Renovator:Renovate(target)
    if self.build then
        target.AnimState:SetBuild(self.build)
        target.build = self.build
    end
    if self.bank then
        target.AnimState:SetBank(self.bank)
        target.bank = self.bank
    end

    if self.prefabname then
        target.prefabname = self.prefabname
        target.name = STRINGS.NAMES[string.upper(self.prefabname)]
    end

    if self.minimap then
        target.minimapicon = self.minimap .. ".tex"
        target.MiniMapEntity:SetIcon(target.minimapicon)
    end

    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(target.Transform:GetWorldPosition())
    fx:SetMaterial("none")
end

return Renovator

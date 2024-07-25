local function OnDeconstructStructure(inst)
    inst.components.fixable.overridden = true
end

local Fixable = Class(function(self, inst)
    self.inst = inst
    self.overridden = false
    self.reconstruction_stages = {}
    self.reconstruction_anims = {}

    self.inst:AddTag("fixable")

    self.inst:ListenForEvent("ondeconstructstructure", OnDeconstructStructure)
end)

function Fixable:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("ondeconstructstructure", OnDeconstructStructure)
end

function Fixable:OnRemoveEntity()
    if not self.overridden then
        local fixer = SpawnPrefab("reconstruction_project")

        fixer.reconstruction_prefab = self.reconstruction_prefab or self.inst.prefab
        fixer.reconstruction_stages = self.reconstruction_stages
        fixer.reconstruction_anims = self.reconstruction_anims
        fixer.reconstruction_overridebuild = self.overridebuild
        fixer.interiorID = self.inst.interiorID
        fixer.cityID = self.inst.components.citypossession and self.inst.components.citypossession.cityID or nil

        if self.inst.components.spawner then
            fixer.spawner_data = {
                childname = self.inst.components.spawner.childname,
                child = self.inst.components.spawner.child or nil,
                delay = self.inst.components.spawner.delay,
            }
        end

        fixer:SetReconstructionStage(1)
        fixer:SetConstructionPrefabName(self.nameoverride or self.inst.prefab)
        fixer.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    end
end

function Fixable:AddRecinstructionStageData(anim, bank, build, scale, stage)
    if not stage then
        stage = #self.reconstruction_stages + 1
    end

    if type(scale) == "number" then
        scale = {scale, scale, scale}
    end

    self.reconstruction_stages[stage] = {
        bank = bank,
        build = build,
        anim = anim,
        scale = scale,
    }
end

return Fixable

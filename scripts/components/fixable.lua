local function OnDeconstructStructure(inst)
    inst:RemoveComponent("fixable")
end

local function OnWorked(inst, data)
    if data.workleft <= 0 then
        local worker = data.worker
        local tool = worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool:HasTag("fixable_crusher") then
            inst:RemoveComponent("fixable")
        end
    end
end

local Fixable = Class(function(self, inst)
    self.inst = inst
    self.reconstruction_stages = {}
    self.reconstruction_anims = {}

    self.inst:AddTag("fixable")

    self.inst:ListenForEvent("worked", OnWorked)
    self.inst:ListenForEvent("ondeconstructstructure", OnDeconstructStructure)
end)

function Fixable:OnRemoveFromEntity()
    self.inst:RemoveTag("fixable")
    self.inst:RemoveEventCallback("worked", OnWorked)
    self.inst:RemoveEventCallback("ondeconstructstructure", OnDeconstructStructure)
end

function Fixable:OnRemoveEntity()
    local fixer = SpawnPrefab("reconstruction_project")

    fixer.reconstruction_prefab = self.reconstruction_prefab or self.inst.prefab
    fixer.reconstruction_stages = self.reconstruction_stages
    fixer.reconstruction_anims = self.reconstruction_anims
    fixer.reconstruction_overridebuild = self.overridebuild
    fixer.interiorID = self.inst.interiorID
    fixer.cityID = self.inst.components.citypossession and self.inst.components.citypossession.cityID

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

    if fixer.interiorID then
        TheWorld.components.interiorspawner:TransferExterior(self.inst, fixer)
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

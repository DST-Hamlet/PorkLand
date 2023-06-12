
local Fixable = Class(function(self, inst)
    self.inst = inst
    self.reconstruction_stages = {}
    self.inst:AddTag("fixable")
end)

function Fixable:OnRemoveEntity()
    if not self.overridden then

        local fixer = SpawnPrefab("reconstruction_project")
        fixer.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        fixer.construction_prefab = self.reconstructionprefab or self.inst.prefab

        if self.inst.components.spawner then
            fixer.spawnerdata = {
                    childname = self.inst.components.spawner.childname,
                    child = self.inst.components.spawner.child or nil,     
                    delay = self.inst.components.spawner.delay        
                } 
        end

        if self.reconstruction_stages[1] then
            fixer.AnimState:SetBank(self.reconstruction_stages[1].bank)
            fixer.AnimState:SetBuild(self.reconstruction_stages[1].build)
            fixer.AnimState:PlayAnimation(self.reconstruction_stages[1].anim,true)
            fixer.saveartdata = {
                bank = self.reconstruction_stages[1].bank,
                build = self.reconstruction_stages[1].build,
                anim = self.reconstruction_stages[1].anim,
            }        
            if self.reconstruction_stages[1].scale then
                fixer.AnimState:SetScale(self.reconstruction_stages[1].scale[1],self.reconstruction_stages[1].scale[2],self.reconstruction_stages[1].scale[3])
                fixer.saveartdata.scale = {self.reconstruction_stages[1].scale[1],self.reconstruction_stages[1].scale[2],self.reconstruction_stages[1].scale[3]}
            else
                fixer.AnimState:SetScale(1,1,1)
            end                            
            fixer:Show()        

            if self.inst.components.citypossession then
                fixer.cityID = self.inst.components.citypossession.cityID
            end        
            if self.inst.interiorID then
                fixer.interiorID = self.inst.interiorID 
            end
        end

        if self.reconstructedanims then
            fixer.reconstructedanims = self.reconstructedanims
        end

        if self.prefabname then
            fixer:SetPrefabNameOverride(self.prefabname)
        else
            fixer:SetPrefabNameOverride(self.inst.prefab)
        end
        fixer.reconstruction_stages = self.reconstruction_stages
    end
end

function Fixable:SetPrefabName(name)
    self.prefabname = name
end

function Fixable:AddRecinstructionStageData(anim,bank,build,stage,scale)
    if not stage then
        stage = #self.reconstruction_stages + 1
    end

    self.reconstruction_stages[stage] = {}

    if bank then
        self.reconstruction_stages[stage].bank = bank
    end
    if build then
        self.reconstruction_stages[stage].build = build
    end
    if anim then
        self.reconstruction_stages[stage].anim = anim
    end    
    if scale then
        self.reconstruction_stages[stage].scale = scale
    end
end

function Fixable:OnSave()

end

return Fixable

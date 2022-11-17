local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("death",function(self, data)
        if self.components.poisonable then
            self.components.poisonable:SetBlockAll(true)
        end
    end)

    inst:ListenForEvent("respawnfromghost",function(self, data)
        if self.components.poisonable and not inst:HasTag("beaver") then
            self.components.poisonable:SetBlockAll(false)
        end
    end)

end)

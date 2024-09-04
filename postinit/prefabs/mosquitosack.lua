local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("mosquitosack", function(inst)
    inst:AddTag("fillable_showoceanaction")

    if not TheWorld.ismastersim then
        return
    end

    inst.components.fillable.acceptsoceanwater = true
end)

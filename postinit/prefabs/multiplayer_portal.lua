local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("multiplayer_portal", function(inst)
    inst.AnimState:SetBank("portal_dst_classic")
    inst.AnimState:SetBuild("portal_dst_classic")
end)

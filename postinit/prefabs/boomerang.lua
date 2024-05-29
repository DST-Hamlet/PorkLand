local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function OnFinished(inst)
    inst.AnimState:PlayAnimation("used")
    inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(),inst.Remove)
end

local function OnDropped(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.components.inventoryitem.pushlandedevents = true
end

AddPrefabPostInit("boomerang", function(inst)
    inst.components.finiteuses:SetOnFinished(OnFinished_Pl)

    inst.components.inventoryitem:SetOnDroppedFn(OnDropped_Pl)
end)

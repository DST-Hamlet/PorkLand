local function RemoveHudIndicator(inst)
    if ThePlayer and ThePlayer.HUD then
        ThePlayer.HUD:RemoveTargetIndicator(inst)
    end
end

local function SetupHudIndicator(inst)
    if ThePlayer then
        ThePlayer.HUD:AddTargetIndicator(inst)
        inst:ListenForEvent("onremove", RemoveHudIndicator)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst.entity:SetCanSleep(false)

    inst:AddTag("CLASSIFIED")

    -- We set this data from `InteriorHudIndicatableManager`
    inst.marker_data = nil

    inst:DoTaskInTime(0, SetupHudIndicator)

    inst.persists = false

    return inst
end

return Prefab("target_indicator_marker", fn)

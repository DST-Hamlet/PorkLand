local function waterfall_sfx()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst:AddTag("CLASSIFIED")
    --[[Non-networked entity]]

    inst:AddTag("FX")

    --inst.entity:SetCanSleep ??

    inst:AddComponent("fader")

    inst:DoPeriodicTask(FRAMES, function()
        if ThePlayer and ThePlayer:IsValid() then
            local dist = math.sqrt(inst:GetDistanceSqToInst(ThePlayer))
            if dist > 40 then
                inst.SoundEmitter:KillSound("waterfall")
            elseif not inst.SoundEmitter:PlayingSound("waterfall") then
                inst.SoundEmitter:PlaySound("porkland_soundpackage/common/waterfall/waterfall", "waterfall")
                inst.SoundEmitter:SetVolume("waterfall", 0.3)
            end
        end
        if inst.target_waterfall and inst.target_waterfall:IsValid() then
            inst.Transform:SetPosition(inst.target_waterfall.Transform:GetWorldPosition())
        end
    end)

    inst.persists = false

    return inst
end

return Prefab("waterfall_sfx", waterfall_sfx)

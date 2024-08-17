local assets =
{
    Asset("ANIM", "anim/deed.zip"),
}

-- local function revealHouse(inst)
--     local house = TheWorld.playerhouse
--     if house and house:IsValid() then
--         house:RevealFog(house)
--     end
-- end

-- local function showOnMinimap(house, reader)
--     if house and house:IsValid() then
--         house:FocusMinimap(house)
--     end
-- end

-- local function readfn(inst, reader)
--     -- if not SaveGameIndex:IsModePorkland() or TheCamera.interior then

--     --     reader.components.talker:Say(GetString(reader.prefab, "ANNOUCE_OTHERWORLD_DEED"))
--     --     return true
--     -- end

--     if TheWorld.playerhouse then
--         revealHouse(inst)
--         TheWorld.playerhouse:DoTaskInTime(0, function() showOnMinimap(TheWorld.playerhouse, reader) end)
--     end

--     return true
-- end

local function OnBought(inst)
    print("DEED BOUGHT")
    TheWorld:PushEvent("deedbought")
end

local function fn(inst)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("deed")
    inst.AnimState:SetBuild("deed")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst:AddComponent("book")
    -- inst.components.book:SetOnReadFn(readfn)
    -- inst.components.book:SetAction(ACTIONS.READMAP)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"

    inst.OnBought = OnBought

    return inst
end

return Prefab("deed", fn, assets)

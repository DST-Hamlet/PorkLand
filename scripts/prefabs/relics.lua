-- local function getstatus(inst)
--     if inst.components.sinkable and inst.components.sinkable.sunken then
--         return "SUNKEN"
--     end
-- end

-- local function Bubble(inst)
    -- inst.task = nil

    -- hacky, need to force a floatable anim change
    -- inst.components.floater:UpdateAnimations(inst.relicnum.."_water", inst.relicnum)

    -- if inst.components.sinkable.sunken then
    --     inst.components.floater:UpdateAnimations(inst.relicnum.."_bubble", inst.relicnum)
    -- end

--     if inst.components.floater.showing_effect then
--         inst.AnimState:PushAnimation(inst.relicnum.."_water")
--     else
--         inst.AnimState:PushAnimation(inst.relicnum)
--     end

--     if inst.entity:IsAwake() then
--         inst:DoTaskInTime(4 + math.random() * 10, Bubble)
--     end
-- end

-- local function OnEntityWake(inst)
--     inst.task = inst:DoTaskInTime(4 + math.random() * 10, Bubble)
-- end

local function MakeRelic(num)

    local name = "relic_"..tostring(num)

    local assets = {
        Asset("ANIM", "anim/relics.zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("molebait")
        inst:AddTag("cattoy")
        inst:AddTag("relic")

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)
        -- inst.components.floater:UpdateAnimations(num .. "_water", tostring(num))

        inst.AnimState:SetBank("relic")
        inst.AnimState:SetBuild("relics")
        inst.AnimState:PlayAnimation(tostring(num))

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("tradable")
        inst:AddComponent("bait")
        inst:AddComponent("inventoryitem")

        inst:AddComponent("inspectable")
        -- inst.components.inspectable.getstatus = getstatus

        -- inst:AddComponent("sinkable")
        -- inst.components.sinkable.swapbuild = "relics"
        -- inst.components.sinkable.swapsymbol = "fish0"..num

        inst.relicnum = num
        -- inst.OnEntityWake = OnEntityWake

        return inst
    end
    return Prefab(name, fn, assets)
end

local ret = {}
for i = 1, 5 do
    table.insert(ret, MakeRelic(i))
end

return unpack(ret)



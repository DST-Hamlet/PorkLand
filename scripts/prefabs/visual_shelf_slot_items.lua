local function MakeVisualShelfSlot(name, animdata, follow_data, common_postinit, master_postinit)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddFollower()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild(animdata[1])
        inst.AnimState:SetBank(animdata[2])
        inst.AnimState:PlayAnimation(animdata[3], animdata[4])

        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("NOFORAGE")

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        inst.follow_data = follow_data
        inst.persists = false

        return inst
    end

    return Prefab(name .. "_visual_shelf_slot", fn)
end

local slot_items = {}

local function Sparkle(inst, colour)
    if not inst.AnimState:IsCurrentAnimation(colour .. "gem_sparkle") then
        inst.AnimState:PlayAnimation(colour .. "gem_sparkle")
        inst.AnimState:PushAnimation(colour .. "gem_idle", true)
    end
    inst:DoTaskInTime(4 + math.random(), Sparkle, colour)
end

for k, colour in ipairs({"purple", "blue", "red", "orange", "yellow", "green", "opal"}) do
    local name = colour .. (colour == "opal" and "preciousgem" or "gem")
    table.insert(slot_items, MakeVisualShelfSlot(name, {"gems", "gems", colour.."gem_idle", true}, nil, nil, function(inst) Sparkle(inst, colour) end))
end

return unpack(slot_items)

local master_postinitfns = {}

local client_postinitfns = {}

local shelfslot_scales = {
    shelf_displayshelf_wood = {0.6, 0.7, 0.8}
}

local function ScaleShelfSlot(inst, shelf, slot, base_scale)
    local scale = shelfslot_scales[shelf.prefab] and shelfslot_scales[shelf.prefab][slot] or nil
    if scale then
        if base_scale then
            scale = base_scale * scale
        end
        inst.AnimState:SetScale(scale, scale, scale)
    end
end

local function SparkleGem(inst, colour, loop)
    if not inst.AnimState:IsCurrentAnimation("sparkle") then
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:PushAnimation("idle")
    end
    inst:DoTaskInTime(4 + math.random(), SparkleGem, colour, loop)
end

for k, colour in ipairs({"purple", "blue", "red", "orange", "yellow", "green", "opal"}) do
    local name = colour .. "gem"
    master_postinitfns[name] = function(inst, shelf, slot, item)
        local sparkle_fx = CreateEntity()
        inst.sparkle_fx = sparkle_fx

        sparkle_fx:AddTag("NOCLICK")

        sparkle_fx.entity:AddTransform()
        sparkle_fx.entity:AddAnimState()
        sparkle_fx.entity:SetParent(inst.entity)

        sparkle_fx.AnimState:SetBank("inventory_fx_sparkle")
        sparkle_fx.AnimState:SetBuild("inventory_fx_sparkle")
        sparkle_fx.AnimState:PlayAnimation("idle", true)
        sparkle_fx.AnimState:SetScale(0.9, 0.9, 0.9)
        sparkle_fx:DoTaskInTime(1, SparkleGem, colour, true)
    end
end

for k, colour in ipairs({"purple", "blue", "red", "orange", "yellow", "green"}) do
    local name = colour .. "mooneye"
    master_postinitfns[name] = function(inst, shelf, slot, item)
        local sparkle_fx = CreateEntity()
        inst.sparkle_fx = sparkle_fx

        sparkle_fx:AddTag("NOCLICK")

        sparkle_fx.entity:AddTransform()
        sparkle_fx.entity:AddAnimState()
        sparkle_fx.entity:SetParent(inst.entity)

        sparkle_fx.AnimState:SetBank("inventory_fx_sparkle")
        sparkle_fx.AnimState:SetBuild("inventory_fx_sparkle")
        sparkle_fx.AnimState:PlayAnimation("idle", true)
        sparkle_fx.AnimState:SetScale(0.8, 0.8, 0.8)
        sparkle_fx:DoTaskInTime(1, SparkleGem, colour, true)
    end
end

master_postinitfns.goldnugget = function(inst, shelf, slot, item)
    inst.AnimState:SetBank("goldnugget")
    inst.AnimState:SetBuild("gold_nugget")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 60, 0)

    inst:DoTaskInTime(1, SparkleGem, nil, true)

    ScaleShelfSlot(inst, shelf, slot, 0.9)
end

master_postinitfns.lightbulb = function(inst, shelf, slot, item)
    inst.entity:AddLight()
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)
end

master_postinitfns.moonglass_charged = function(inst, shelf, slot, item)
    inst.entity:AddLight()

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(true)
end

master_postinitfns.poop = function(inst, shelf, slot, item)
    inst:SpawnChild("flies")
end

client_postinitfns.tophat = function(inst, shelf, slot, item)
    if not inst.shelf_shadow_fx and item:HasTag("shadow_item") then
        local shelf_shadow_fx = CreateEntity()
        inst.shelf_shadow_fx = shelf_shadow_fx

        shelf_shadow_fx:AddTag("NOCLICK")

        shelf_shadow_fx.entity:AddTransform()
        shelf_shadow_fx.entity:AddAnimState()
        shelf_shadow_fx.entity:SetParent(inst.entity)

        shelf_shadow_fx.AnimState:SetBank("inventory_fx_shadow")
        shelf_shadow_fx.AnimState:SetBuild("inventory_fx_shadow")
        shelf_shadow_fx.AnimState:PlayAnimation("idle", true)
        shelf_shadow_fx.AnimState:SetTime(math.random() * shelf_shadow_fx.AnimState:GetCurrentAnimationTime())
        shelf_shadow_fx.AnimState:AnimateWhilePaused(false)

        ScaleShelfSlot(tophat_shadow_fx, shelf, slot, 0.8)
    end
end

return {
    master_postinitfns = master_postinitfns,
    client_postinitfns = client_postinitfns
}

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

local function CreateCopyEntity(inst, item)
    local copy = CreateEntity()
    copy:AddTag("NOCLICK")
    copy.entity:AddTransform()
    copy.entity:AddAnimState()
    copy.entity:AddFollower()

    inst.highlightchildren = inst.highlightchildren or {}
    table.insert(inst.highlightchildren, copy)

    copy:ListenForEvent("onremove", function()
        copy:Remove()
    end, inst)

    local build = item:GetSkinBuild() or item.AnimState:GetBuild()
    local bank = item.AnimState:GetCurrentBankName()
    local animation = item:GetCurrentAnimation()

    copy.AnimState:SetBank(bank)
    copy.AnimState:SetBuild(build)
    copy.AnimState:PlayAnimation(animation)

    local skin_name = item.AnimState:GetSkinBuild()
    if skin_name then
        copy.AnimState:SetSkin(skin_name, animation)
    end

    return copy
end

local function SparkleGem(inst, colour, loop)
    if not inst.AnimState:IsCurrentAnimation(colour .. "gem_sparkle") then
        inst.AnimState:PlayAnimation(colour .. "gem_sparkle")
        inst.AnimState:PushAnimation(colour .. "gem_idle", loop)
    end
    inst:DoTaskInTime(4 + math.random(), SparkleGem, colour, loop)
end

local function ReviverBeat(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve/ghost/bloodpump")
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, ReviverBeat)
end

local gem_offests = {
    green = {x = -35}
}

for k, colour in ipairs({"purple", "blue", "red", "orange", "yellow", "green", "opal"}) do
    local name = colour .. (colour == "opal" and "preciousgem" or "gem")
    master_postinitfns[name] = function(inst, shelf, slot, item)
        inst.AnimState:SetBuild("gems")
        inst.AnimState:SetBank("gems")
        inst.AnimState:PlayAnimation(colour.."gem_idle", true)

        local offest = gem_offests[colour] or {}
        inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), offest.x or 0, offest.y or 20, offest.z or 0)

        inst:DoTaskInTime(1, SparkleGem, colour, true)

        ScaleShelfSlot(inst, shelf, slot)
    end
end

for k, colour in ipairs({"purple", "blue", "red", "orange", "yellow", "green"}) do
    local name = colour .. "mooneye"
    master_postinitfns[name] = function(inst, shelf, slot, item)
        inst.AnimState:SetBank("mooneyes")
        inst.AnimState:SetBuild("mooneyes")
        inst.AnimState:PlayAnimation(colour .. "gem_idle")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 50, 0)

        inst:DoTaskInTime(0, SparkleGem, colour, false)

        ScaleShelfSlot(inst, shelf, slot)
    end
end

local FISH_DATA = require("prefabs/oceanfishdef")
local Flop = ToolUtil.GetUpvalue(Prefabs["oceanfish_small_1"].fn, "water_common.OnMakeProjectile.OnProjectileLand.Flop")
for _, fish_def in pairs(FISH_DATA.fish) do
	master_postinitfns[fish_def.prefab .. "_inv"] = function(inst, shelf, slot, item)
        if fish_def.light ~= nil then
            inst.entity:AddLight()
            inst.Light:SetRadius(fish_def.light.r)
            inst.Light:SetFalloff(fish_def.light.f)
            inst.Light:SetIntensity(fish_def.light.i)
            inst.Light:SetColour(unpack(fish_def.light.c))
            inst.Light:Enable(false)
        end

        if fish_def.dynamic_shadow then
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(fish_def.dynamic_shadow[1], fish_def.dynamic_shadow[2])
        end

        inst.Transform:SetTwoFaced()

        inst.AnimState:SetBank(fish_def.bank)
        inst.AnimState:SetBuild(fish_def.build)
        inst.AnimState:PlayAnimation("flop_pst")

        inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 50, 0)

        Flop(inst)

        ScaleShelfSlot(inst, shelf, slot)
    end
end

master_postinitfns.lightbulb = function(inst, shelf, slot, item)
    inst.AnimState:SetBank("bulb")
    inst.AnimState:SetBuild("bulb")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.entity:AddLight()
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 50, 0)

    ScaleShelfSlot(inst, shelf, slot)
end

master_postinitfns.purebrilliance = function(inst, shelf, slot, item)
    inst.AnimState:SetBank("purebrilliance")
    inst.AnimState:SetBuild("purebrilliance")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop", .5)
    inst.AnimState:SetSymbolLightOverride("pb_ray", .5)
    inst.AnimState:SetSymbolLightOverride("SparkleBit", .5)
    inst.AnimState:SetLightOverride(.1)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 50, 0)

    ScaleShelfSlot(inst, shelf, slot)
end

master_postinitfns.moonglass_charged = function(inst, shelf, slot, item)
    inst.entity:AddLight()

    inst.AnimState:SetBank("moonglass_charged")
    inst.AnimState:SetBuild("moonglass_charged")
    inst.AnimState:PlayAnimation("f1")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(true)

    ScaleShelfSlot(inst, shelf, slot)
end

master_postinitfns.nightmarefuel = function(inst, shelf, slot, item)
    inst.AnimState:SetBank("nightmarefuel")
    inst.AnimState:SetBuild("nightmarefuel")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)
    inst.AnimState:UsePointFiltering(true)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 50, 0)

    ScaleShelfSlot(inst, shelf, slot)
end

master_postinitfns.horrorfuel = function(inst, shelf, slot, item)
    inst.AnimState:SetBank("horrorfuel")
    inst.AnimState:SetBuild("horrorfuel")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)
    inst.AnimState:UsePointFiltering(true)

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 50, 0)

    ScaleShelfSlot(inst, shelf, slot)
end

master_postinitfns.poop = function(inst, shelf, slot, item)
    inst.AnimState:SetBank("poop")
    inst.AnimState:SetBuild("poop")
    inst.AnimState:PlayAnimation("idle", false)
    inst.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 50, 0)
    inst:SpawnChild("flies")

    ScaleShelfSlot(inst, shelf, slot, 0.8)
end

client_postinitfns.tophat = function(inst, shelf, slot, item)
    if not inst.tophat_shadow_fx then
        local tophat_shadow_fx = CreateEntity()
        inst.tophat_shadow_fx = tophat_shadow_fx

        tophat_shadow_fx:AddTag("NOCLICK")

        tophat_shadow_fx.entity:AddTransform()
        tophat_shadow_fx.entity:AddAnimState()
        tophat_shadow_fx.entity:SetParent(inst.entity)

        tophat_shadow_fx.AnimState:SetBank("inventory_fx_shadow")
        tophat_shadow_fx.AnimState:SetBuild("inventory_fx_shadow")
        tophat_shadow_fx.AnimState:PlayAnimation("idle", true)
        tophat_shadow_fx.AnimState:SetTime(math.random() * tophat_shadow_fx.AnimState:GetCurrentAnimationTime())
        tophat_shadow_fx.AnimState:AnimateWhilePaused(false)

        ScaleShelfSlot(tophat_shadow_fx, shelf, slot, 0.8)
    end
end

master_postinitfns.reviver = function(inst, shelf, slot, item)
    inst.components.visualslot:SetDefault()
end

client_postinitfns.reviver = function(inst, shelf, slot, item)
    if not inst.visual_reviver then
        inst.visual_reviver = CreateCopyEntity(inst, item)
        inst.visual_reviver.entity:AddSoundEmitter()
        inst.visual_reviver.Follower:FollowSymbol(shelf.GUID, shelf:GetSlotSymbol(slot), 0, 20, 0)
        ScaleShelfSlot(inst.visual_reviver, shelf, slot)
    end
    inst.visual_reviver.beattask = inst.visual_reviver:DoTaskInTime(.75 + math.random() * .75, ReviverBeat)
end

return {
    master_postinitfns = master_postinitfns,
    client_postinitfns = client_postinitfns
}

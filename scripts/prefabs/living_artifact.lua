local assets =
{
    Asset("ANIM", "anim/living_artifact.zip"),
    Asset("ANIM", "anim/living_suit_build.zip"),
}

local function SavePlayerData(player)
    local data = {}

    data.build = player.AnimState:GetBuild()
    data.skins = player.components.skinner:GetClothing()

    data.health_redirect = player.components.health.redirect

    -- Wagstaff stuff
    -- data.wasnearsighted = player.components.vision.nearsighted

    return data
end

local function LoadPlayerData(player, data)
    player.AnimState:ClearOverrideBuild("living_suit_build_morph")
    player.AnimState:SetBuild(data.build)
    player.components.skinner:SetSkinName(data.skins.base, true)
    for _, skin in pairs(data.skins) do
        player.components.skinner:SetClothing(skin)
    end

    player.components.health.redirect = data.health_redirect

    -- Wagstaff stuff
    -- player.components.vision.nearsighted = data.wasnearsighted
    -- player.components.vision:CheckForGlasses()
end

local function drop_inventory_items(player)
    local self = player.components.inventory
    if self.activeitem then
        self:DropItem(self.activeitem, true, true)
        self:SetActiveItem(nil)
    end

    for k = 1, self.maxslots do
        local v = self.itemslots[k]
        if v and not (ondeath and v.components.inventoryitem.keepondeath) then
            self:DropItem(v, true, true)
        end
    end

        -- if self.inst.EmptyBeard ~= nil then
        --     self.inst:EmptyBeard()
        -- end

    for k, v in pairs(self.equipslots) do
        self:DropItem(v, true, true)
    end
end

local function BecomeIronLord_post(inst)
    inst.player.components.skinner:SetSkinName("", nil, true)
    inst.player.components.skinner:ClearAllClothing()
    inst.player.AnimState:SetBuild("living_suit_build")
    inst.player.AnimState:AddOverrideBuild("living_suit_build") -- override Wanda & Wolfgang's symbols

    local controller_mode = TheInput:ControllerAttached()
    if controller_mode and inst.components.reticule and not inst.components.reticule.reticule then
        inst.components.reticule:CreateReticule()
        inst.components.reticule.reticule:Show()
    end
end

local function BecomeIronLord(inst, instant)
    local player = inst.player

    inst.player_data = SavePlayerData(player)

    inst.AnimState:Hide("beard")
    player.AnimState:AddOverrideBuild("player_living_suit_morph")

    player:AddTag("fireimmune")
    player:AddTag("has_gasmask")
    player:AddTag("ironlord")
    player:AddTag("laser_immune")
    player:AddTag("mech")

    player:DoTaskInTime(0, function() -- wait for player_classified to be constructed
        player.player_classified.instantironlord:set(true)
        player.player_classified.isironlord:set(true)
    end)

    player.components.combat:SetDefaultDamage(TUNING.IRON_LORD_DAMAGE)

    player.components.inventory:DropEverything(true, false)

    player.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * 1.3

    player.components.grogginess:SetEnableSpeedMod(false)

    if player.components.poisonable then
        player.components.poisonable:SetBlockAll(true)
    end

    player.components.temperature:SetTemp(TUNING.STARTING_TEMP)

    player.components.health:SetPercent(1)
    player.components.health.redirect = function() return true end

    if player.components.oldager then
        player:StopUpdatingComponent(player.components.oldager)
    end

    player.components.hunger:Pause()
    player.components.hunger:SetPercent(1)

    player.components.sanity:SetPercent(1)
    player.components.sanity.ignore = true

    player:AddComponent("worker")
    player.components.worker:SetAction(ACTIONS.DIG, 1)
    player.components.worker:SetAction(ACTIONS.CHOP, 4)
    player.components.worker:SetAction(ACTIONS.MINE, 3)
    player.components.worker:SetAction(ACTIONS.HAMMER, 3)
    player.components.worker:SetAction(ACTIONS.HACK, 2)

    -- Wagstaff stuff
    -- player.components.vision.nearsighted = false
    -- player.components.vision:CheckForGlasses()

    inst.nightlight = SpawnPrefab("living_artifact_light")
    player:AddChild(inst.nightlight)

    if player:HasTag("lightsource") then
        player:RemoveTag("lightsource")
    end

    inst:AddTag("notslippery")
    inst:AddTag("cantdrop")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = function()
        local offset = player.components.playercontroller:GetWorldControllerVector()
        if offset then
            local newpt = Vector3(player.Transform:GetWorldPosition())
            newpt.x = newpt.x + offset.x * 8
            newpt.z = newpt.z + offset.z * 8
            return newpt
        end
    end

    inst:StartUpdatingComponent(inst.components.livingartifact)

    if not instant then
        player.sg:GoToState("ironlord_morph")
        player:DoTaskInTime(2, function()
            player.components.talker:Say(GetString(player.prefab, "ANNOUNCE_SUITUP"))
        end)
    else
        BecomeIronLord_post(inst)
        inst:StartUpdatingComponent(inst.components.livingartifact)
        inst.player.components.inventory.ignoresound = true -- hacky
        inst.player.components.inventory:GiveItem(inst)
        inst.player.components.inventory.ignoresound = false
    end
end

local function Revert(inst)
    inst.nightlight:Remove()
    inst.components.reticule:DestroyReticule()

    local player = inst.player

    LoadPlayerData(player, inst.player_data)

    player.AnimState:ClearOverrideBuild("living_suit_build")
    player.AnimState:SetBank("wilson")
    player.AnimState:Show("beard")

    player.SoundEmitter:KillSound("chargedup")

    player:RemoveTag("ironlord")
    player:RemoveTag("laser_immune")
    player:RemoveTag("mech")
    player:RemoveTag("has_gasmask")
    player:RemoveTag("fireimmune")

    player.player_classified.isironlord:set(false)

    player:RemoveComponent("worker")

    player.components.locomotor:Stop()
    player.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED

    player.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)

    player.components.grogginess:SetEnableSpeedMod(true)

    player.components.moisture:ForceDry(false)

    player.components.temperature:SetTemperature(TUNING.STARTING_TEMP)
    player.components.temperature:SetTemp(nil)

    if player.components.poisonable then
        player.components.poisonable:SetBlockAll(nil)
    end

    player.components.hunger:Resume()
    player.components.sanity.ignore = false

    if player.components.oldager then
        player:StartUpdatingComponent(player.components.oldager)
    end

    player:ClearBufferedAction()
    player:DoTaskInTime(0, function() player.sg:GoToState("bucked_post") end)

    inst:Remove()
end

local function OnActivate(inst, player, instant)
    if instant then -- OnLoad
        inst.player = inst.components.inventoryitem:GetGrandOwner()
        if not inst.player then
            return
        end

        inst:AddTag("enabled")
        inst:ListenForEvent("revert", function() Revert(inst) end, inst.player)
        BecomeIronLord(inst, true)
        inst.player.components.inventory:GiveItem(inst)
        return
    end

    if player.components.inventory:FindItem(function(item) if inst == item then return true end end) then
        player.components.inventory:RemoveItem(inst)
        local x, y, z = player.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x, y, z)
    end

    inst:AddTag("enabled")
    inst.player = player

    inst.AnimState:PlayAnimation("activate")
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("activate") then
            inst:Hide()
            inst.player.components.inventory.ignoresound = true -- hacky
            inst.player.components.inventory:GiveItem(inst)
            inst.player.components.inventory.ignoresound = false
        end
    end)

    inst:ListenForEvent("ironlord_morph_complete", function() BecomeIronLord_post(inst) end, player)
    inst:ListenForEvent("revert", function() Revert(inst) end, player)

    BecomeIronLord(inst, false)
end

local function OnFinished(inst)
    inst.player.sg:GoToState("ironlord_explode")
end

local function OnDelta(inst)
    inst.player.player_classified.ironlordtimeleft:set(inst.components.livingartifact.time_left)
end

local function OnSave(inst, data)
    if inst:HasTag("enabled") then
        data.enabled = true
        data.player_data = inst.player_data
    end
end

local function OnLoad(inst, data)
    if data and data.enabled then
        inst:Hide()
        inst.player_data = data.player_data
        inst:DoTaskInTime(0, function()
            inst.components.livingartifact:Activate(nil, true)
        end)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.AnimState:SetBank("living_artifact")
    inst.AnimState:SetBuild("living_artifact")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ANCIENT_HULK_MINE_DAMAGE)

    inst:AddComponent("livingartifact")
    inst.components.livingartifact:SetOnActivateFn(OnActivate)
    inst.components.livingartifact:SetOnDeltaFn(OnDelta)
    inst.components.livingartifact:SetOnFinishedFn(OnFinished)

    MakeHauntableLaunch(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function lightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:Enable(true)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.6)
    inst.Light:SetColour(245/255, 150/255, 0/255)

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function()
        if inst:HasTag("lightsource") then
            inst:RemoveTag("lightsource")
        end
    end)

    return inst
end

return Prefab("living_artifact", fn, assets),
       Prefab("living_artifact_light", lightfn, assets)


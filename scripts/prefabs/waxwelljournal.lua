local assets =
{
    Asset("ANIM", "anim/book_maxwell.zip"),

    Asset("SOUND", "sound/together.fsb"),
}


local SUMMON_MINION_DIST = PLAYER_CAMERA_SEE_DISTANCE * 0.5

local function ReticuleMouseTargetFn(inst, pos)
    local doer_pos = inst:GetPosition()
    if inst:GetDistanceSqToPoint(pos) > SUMMON_MINION_DIST * SUMMON_MINION_DIST then
        return doer_pos + (pos - doer_pos):Normalize() * SUMMON_MINION_DIST
    end
end

local function ReticuleTargetFn(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(7, 0.001, 0))
end

local function StartAOETargeting(inst)
    if ThePlayer.components.playercontroller then
        print(inst.components.aoetargeting:IsEnabled())
        ThePlayer.components.playercontroller:StartAOETargetingUsing(inst)
    end
end

local function CheckMaxSanity(doer)
	return doer.components.sanity ~= nil
        and (doer.components.sanity:GetPenaltyPercent() + TUNING.WAXWELL_MINION_SANITY_PENALTY) <= TUNING.MAXIMUM_SANITY_PENALTY
end

local function SummonMinionSpell(inst, doer, position)
    if not CheckMaxSanity(doer) then
        doer:PushEvent("summon_fail")
        return false
    end

    if not doer.components.petleash then
        return false
    end

    doer.sg:GoToState("book")

    local pt = position or doer:GetPosition() -- FindSpawnPoints(doer, pos, NUM_MINIONS_PER_SPAWN, 1)

    local pet = doer.components.petleash:SpawnPetAt(pt.x, 0, pt.z, "waxwell_minion")
    if pet ~= nil then
        if pet.SaveSpawnPoint ~= nil then
            pet:SaveSpawnPoint() -- TODO: manage minion activity range
        end
    end
    return true
end

local function ShadowShieldSpell(inst, doer, position)

end

local function ShadowChainSpell(inst, doer, position)
    doer.sg:GoToState("")

    local chain = SpawnPrefab("shadow_chain")
    chain.Transform:SetPosition(position.x, 0, position.y)
end

local ATLAS = "images/hud/abigail_flower_commands.xml"
local SCALE = 0.9

-- maybe we should write templates for these commands?
local COMMANDS = {
    {
        id = "summon_minion",
        label = STRINGS.SPELLCOMMAND.WAXWELL.SUMMON_MINION,
        on_execute_on_server = function(inst, doer, position)
            SummonMinionSpell(inst, doer, position)
        end,
        on_execute_on_client = function(inst)
            inst.components.spellcommand:SetSelectedCommand("summon_minion")

            local aoetargeting = inst.components.aoetargeting
            aoetargeting:SetAllowWater(true)
            aoetargeting:SetDeployRadius(0)
            aoetargeting:SetRange(40)
            aoetargeting:SetShouldRepeatCastFn(function ()
                return true
            end)

            aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
            aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
            aoetargeting.reticule.reticuleprefab = "reticuleaoeghosttarget"
            aoetargeting.reticule.pingprefab = "reticuleaoeghosttarget_ping"
            aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
            aoetargeting.reticule.targetfn = ReticuleTargetFn
            aoetargeting.reticule.updatepositionfn = nil
            aoetargeting.reticule.twinstickrange = 15

            StartAOETargeting(inst)
        end,
        widget_scale = SCALE,
        atlas = ATLAS,
        normal = "haunt.tex"--"summon_minion.tex",
    },
    -- {
    --     id = "shadow_chain",
    --     label = STRINGS.SPELLCOMMAND.WAXWELL.SHADOW_CHAIN,
    --     on_execute_on_server = function(inst, doer, position)
    --         -- TODO: See if we still want this
    --         inst.components.aoetargeting:SetTargetFX("reticuleaoeghosttarget")
    --         local fx = inst.components.aoetargeting:SpawnTargetFXAt(position)
    --         if fx then
    --             -- This is normally done in SG to align with the animations,
    --             -- but since we don't want it to have animations right now,
    --             -- we remove it after a fixed time
    --             fx:DoTaskInTime(15* FRAMES, function(inst)
    --                 if inst.KillFX then
    --                     inst:KillFX()
    --                 else
    --                     inst:Remove()
    --                 end
    --             end)
    --         end

    --         ShadowChainSpell(inst, doer, position)
    --     end,
    --     on_execute_on_client = function(inst)
    --         inst.components.spellcommand:SetSelectedCommand("shadow_chain")

    -- 		local aoetargeting = inst.components.aoetargeting
    --         aoetargeting:SetDeployRadius(0)
    -- 		aoetargeting:SetRange(20)
    -- 		aoetargeting:SetShouldRepeatCastFn(function()
    --             return true
    --         end)
    --         aoetargeting.reticule.pingprefab = "reticuleaoeghosttarget_ping"

    --         aoetargeting.reticule.mousetargetfn = nil
    --         aoetargeting.reticule.targetfn = ReticuleTargetFn
    --         aoetargeting.reticule.updatepositionfn = nil
    -- 		aoetargeting.reticule.twinstickrange = 15

    --         StartAOETargeting(inst)
    --     end,
    --     widget_scale = SCALE,
    --     atlas = ATLAS,
    --     normal = "shadow_chain.tex",
    -- },
    -- {
    --     id = "shadow_shield",
    --     label = STRINGS.SPELLCOMMAND.WAXWELL.SHADOW_SHIELD,
    --     on_execute_on_server = function(inst, doer)
    --         ShadowShieldSpell(inst, doer)
    --     end,
    --     on_execute_on_client = function(inst)
    --         inst.components.spellcommand:SetSelectedCommand("shadow_shield")

    -- 		local aoetargeting = inst.components.aoetargeting
    --         aoetargeting:SetDeployRadius(0)
    -- 		aoetargeting:SetShouldRepeatCastFn(function()
    --             return true
    --         end)
    --         inst.components.aoetargeting.reticule.reticuleprefab = "reticulemultitarget"
    --         inst.components.aoetargeting.reticule.pingprefab = "reticulemultitargetping"

    --         aoetargeting.reticule.mousetargetfn = function(inst, mousepos)
    --             if mousepos == nil then
    --                 return nil
    --             end
    --             local inventoryitem = inst.replica.inventoryitem
    --             local owner = inventoryitem and inventoryitem:IsGrandOwner(ThePlayer) and ThePlayer
    --             if owner then
    --                 local pos = Vector3(owner.Transform:GetWorldPosition())
    --                 return pos
    --             end
    --         end
    --         aoetargeting.reticule.targetfn = function(inst)
    --             if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.components.playercontroller.isclientcontrollerattached then
    --                 local inventoryitem = inst.replica.inventoryitem
    --                 local owner =  inventoryitem and inventoryitem:IsGrandOwner(ThePlayer) and ThePlayer
    --                 if owner then
    --                     local pos = Vector3(owner.Transform:GetWorldPosition())
    --                     return pos
    --                 end
    --             end
    --         end
    --         aoetargeting.reticule.updatepositionfn = function(inst, pos, reticule, ease, smoothing, dt)
    --             local inventoryitem = inst.replica.inventoryitem
    --             local owner = inventoryitem and inventoryitem:IsGrandOwner(ThePlayer) and ThePlayer

    --             if owner then
    --                 reticule.Transform:SetPosition(Vector3(owner.Transform:GetWorldPosition()):Get())
    --                 reticule.Transform:SetRotation(0)
    --             end
    --         end
    -- 		-- aoetargeting.reticule.twinstickrange = 15

    --         StartAOETargeting(inst)
    --     end,
    --     widget_scale = SCALE,
    --     atlas = ATLAS,
    --     normal = "shadow_shield.tex",
    -- },
}

--[==[
local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)


AddPrefabRegisterPostInit("abigail_flower", function(abigail_flower)
    ToolUtil.SetUpvalue(abigail_flower.fn, "updatespells", function(inst, owner)
        if not owner then
            return
        end
        if owner:HasTag("ghostfriend_summoned") then
            if owner.HUD and owner.HUD.controls.spellcontrols:IsOpen() then
                owner.HUD.controls.spellcontrols:RefreshItemStates()
            end
        else
            if owner.HUD and owner.HUD.controls.spellcontrols:IsOpen() then
                owner.HUD.controls.spellcontrols:Close()
            end
        end
    end)
end)
]==]

local function tryplaysound(inst, id, sound)
    inst._soundtasks[id] = nil
    if inst.AnimState:IsCurrentAnimation("proximity_pst") then
        inst.SoundEmitter:PlaySound(sound)
    end
end

local function trykillsound(inst, id, sound)
    inst._soundtasks[id] = nil
    if inst.AnimState:IsCurrentAnimation("proximity_pst") then
        inst.SoundEmitter:KillSound(sound)
    end
end

local function queueplaysound(inst, delay, id, sound)
    if inst._soundtasks[id] ~= nil then
        inst._soundtasks[id]:Cancel()
    end
    inst._soundtasks[id] = inst:DoTaskInTime(delay, tryplaysound, id, sound)
end

local function queuekillsound(inst, delay, id, sound)
    if inst._soundtasks[id] ~= nil then
        inst._soundtasks[id]:Cancel()
    end
    inst._soundtasks[id] = inst:DoTaskInTime(delay, trykillsound, id, sound)
end

local function tryqueueclosingsounds(inst, onanimover)
    inst._soundtasks.animover = nil
    if inst.AnimState:IsCurrentAnimation("proximity_pst") then
        inst:RemoveEventCallback("animover", onanimover)
        --Delay one less frame, since this task is delayed one frame already
        queueplaysound(inst, 4 * FRAMES, "close", "dontstarve/common/together/book_maxwell/close")
        queuekillsound(inst, 5 * FRAMES, "killidle", "idlesound")
        queueplaysound(inst, 14 * FRAMES, "drop", "dontstarve/common/together/book_maxwell/drop")
    end
end

local function onanimover(inst)
    if inst._soundtasks.animover ~= nil then
        inst._soundtasks.animover:Cancel()
    end
    inst._soundtasks.animover = inst:DoTaskInTime(FRAMES, tryqueueclosingsounds, onanimover)
end

local function stopclosingsounds(inst)
    inst:RemoveEventCallback("animover", onanimover)
    if next(inst._soundtasks) ~= nil then
        for k, v in pairs(inst._soundtasks) do
            v:Cancel()
        end
        inst._soundtasks = {}
    end
end

local function startclosingsounds(inst)
    stopclosingsounds(inst)
    inst:ListenForEvent("animover", onanimover)
    onanimover(inst)
end

local function onturnon(inst)
    if inst._activetask == nil then
        stopclosingsounds(inst)
        if inst.AnimState:IsCurrentAnimation("proximity_loop") then
            --In case other animations were still in queue
            inst.AnimState:PlayAnimation("proximity_loop", true)
        else
            inst.AnimState:PlayAnimation("proximity_pre")
            inst.AnimState:PushAnimation("proximity_loop", true)
        end
        if not inst.SoundEmitter:PlayingSound("idlesound") then
            inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/active_LP", "idlesound")
        end
    end
end

local function onturnoff(inst)
    if inst._activetask == nil and not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PushAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
        startclosingsounds(inst)
    end
end

local function doneact(inst)
    inst._activetask = nil
    if inst.components.prototyper.on then
        inst.AnimState:PlayAnimation("proximity_loop", true)
        if not inst.SoundEmitter:PlayingSound("idlesound") then
            inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/active_LP", "idlesound")
        end
    else
        inst.AnimState:PushAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
        startclosingsounds(inst)
    end
end

local function showfx(inst, show)
    if inst.AnimState:IsCurrentAnimation("use") then
        if show then
            inst.AnimState:Show("FX")
        else
            inst.AnimState:Hide("FX")
        end
    end
end

local function onuse(inst, hasfx)
    stopclosingsounds(inst)
    inst.AnimState:PlayAnimation("use")
    inst:DoTaskInTime(0, showfx, hasfx)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/use")
    if inst._activetask ~= nil then
        inst._activetask:Cancel()
    end
    inst._activetask = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), doneact)
end

local function onactivate(inst)
    onuse(inst, true)
end

local function onputininventory(inst)
    if inst._activetask ~= nil then
        inst._activetask:Cancel()
        inst._activetask = nil
    end
    stopclosingsounds(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:KillSound("idlesound")
end

local function ondropped(inst)
    if inst.components.prototyper.on then
        onturnon(inst)
    end
end

local function OnHaunt(inst, haunter)
    if inst.components.prototyper.on then
        onuse(inst, false)
    else
        Launch(inst, haunter, TUNING.LAUNCH_SPEED_SMALL)
    end
    inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("book_maxwell")
    inst.AnimState:SetBuild("book_maxwell")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("shadowmagic")

    -- prototyper (from prototyper component) added to pristine state for optimization
    inst:AddTag("prototyper")

    local aoetargeting = inst:AddComponent("aoetargeting")
    aoetargeting:SetAllowWater(true)
    aoetargeting.reticule.mouseenabled = true
    aoetargeting.reticule.twinstickmode = 1
    aoetargeting.reticule.twinstickrange = 15


    local spellbook = inst:AddComponent("spellbook")
    spellbook:SetRequiredTag("shadowmagic")
    spellbook:SetItems(COMMANDS)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._activetask = nil
    inst._soundtasks = {}

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    inst.components.prototyper.onactivate = onactivate
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.WAXWELLJOURNAL

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    inst:AddComponent("aoespell") -- need both aoespell and aoetargeting to work, obviously...

    inst:AddComponent("spellcommand")
    inst.components.spellcommand:SetSpellCommands(COMMANDS)
    inst.components.spellcommand.ui_background = {
        bank = "ui_abigail_command_5x1",
        build = "ui_abigail_command_5x1",
    }

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst:ListenForEvent("onputininventory", onputininventory)
    inst:ListenForEvent("ondropped", ondropped)

    return inst
end

return Prefab("waxwelljournal", fn, assets)

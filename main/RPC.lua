local AddModRPCHandler = AddModRPCHandler
local AddShardModRPCHandler = AddShardModRPCHandler
GLOBAL.setfenv(1, GLOBAL)

local function printinvalid(rpcname, player)
    print(string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))

    --This event is for MODs that want to handle players sending invalid rpcs
    TheWorld:PushEvent("invalidrpc", { player = player, rpcname = rpcname })

    if BRANCH == "dev" then
        --Internal testing
        assert(false, string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))
    end
end

local function IsPointInRange(player, position)
    local px, _, pz = player.Transform:GetWorldPosition()
    return distsq(position.x, position.z, px, pz) <= 4096
end

local function ConvertPlatformRelativePositionToAbsolutePosition(platform, relative_x, relative_z)
    if not (relative_x and relative_z) then
        return
    end
    if not platform then
        return Vector3(relative_x, 0, relative_z)
    end
    local x, _, z = platform.entity:LocalToWorldSpace(relative_x, 0, relative_z)
    return Vector3(x, 0, z)
end

AddModRPCHandler("Porkland", "BoatEquipActiveItem", function(player, container)
    if container ~= nil then
        container.components.container:BoatEquipActiveItem()
    end
end)

AddModRPCHandler("Porkland", "SwapBoatEquipWithActiveItem", function(player, container)
    if container ~= nil then
        container.components.container:SwapBoatEquipWithActiveItem()
    end
end)

AddModRPCHandler("Porkland", "TakeActiveItemFromBoatEquipSlot", function(player, eslot, container)
    if not checknumber(eslot) then
        printinvalid("TakeActiveItemFromBoatEquipSlot", player)
        return
    end
    if container ~= nil then
        container.components.container:TakeActiveItemFromBoatEquipSlotID(eslot)
    end
end)

AddShardModRPCHandler("Porkland", "SetAporkalypseClockRewindMult", function(shardid, rewind_mult)
    if not TheWorld.ismastershard then
        return
    end

    TheWorld:PushEvent("ms_setrewindmult", rewind_mult)
end)

AddShardModRPCHandler("Porkland", "SwitchAporkalypse", function(shardid, active)
    if not TheWorld.ismastershard then
        return
    end

    if active then
        TheWorld:PushEvent("ms_startaporkalypse")
    else
        TheWorld:PushEvent("ms_stopaporkalypse")
    end
end)

AddModRPCHandler("Porkland", "teleport_to_home", function(inst)
    -- TODO: 以后可以做一个倒计时...
    local pos = inst:GetPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(pos.x, pos.z) then
        TheWorld.components.playerspawner:SpawnAtNextLocation(inst)
    end
end)

AddModRPCHandler("Porkland", "ReleaseControlSecondary", function(player, x, z)
    if not (checknumber(x) and checknumber(z)) then
        return
    end
    local playercontroller = player.components.playercontroller
    if playercontroller ~= nil then
        playercontroller:OnRemoteReleaseControlSecondary(x, z)
    end
end)

AddModRPCHandler("Porkland", "StrafeFacing_pl", function(player, dir)
    if not checknumber(dir) then
        printinvalid("StrafeFacing", player)
        return
    end
    local locomotor = player.components.locomotor
    if locomotor then
        locomotor:OnStrafeFacingChanged(dir)
    end
end)

AddModRPCHandler("Porkland", "CastSpellCommand", function(player, item, command_id, target, x, z, platform)
    if not (
        checkentity(item)
        and checkstring(command_id)
        and optentity(target)
        and optnumber(x)
        and optnumber(z)
        and optentity(platform)
    ) then
        printinvalid("CastSpellCommand", player)
        return
    end

    local playercontroller = player.components.playercontroller
    if playercontroller then
        local position = ConvertPlatformRelativePositionToAbsolutePosition(platform, x, z)
        if not position or IsPointInRange(player, position) then
            playercontroller:OnRemoteCastSpellCommand(item, command_id, position, target)
        else
            print("Remote left click out of range")
        end
    end
end)

AddClientModRPCHandler("Porkland", "interior_map", function(data)
    local interiorvisitor = ThePlayer and ThePlayer.replica.interiorvisitor
    if interiorvisitor then
        interiorvisitor:OnNewInteriorMapData(DecodeAndUnzipString(data))
    end
end)

AddClientModRPCHandler("Porkland", "remove_interior_map", function(data)
    local interiorvisitor = ThePlayer and ThePlayer.replica.interiorvisitor
    if interiorvisitor then
        interiorvisitor:RemoveInteriorMapData(DecodeAndUnzipString(data))
    end
end)

AddClientModRPCHandler("Porkland", "always_shown_interior_map", function(data)
    local interiorvisitor = ThePlayer and ThePlayer.replica.interiorvisitor
    if interiorvisitor then
        interiorvisitor:OnAlwaysShownInteriorMapData(DecodeAndUnzipString(data))
    end
end)

AddClientModRPCHandler("Porkland", "update_hud_indicatable_entities", function(data)
    local interiorhudindicatablemanager = TheWorld and TheWorld.components.interiorhudindicatablemanager
    if interiorhudindicatablemanager then
        interiorhudindicatablemanager:OnInteriorHudIndicatableData(DecodeAndUnzipString(data))
    end
end)

AddClientModRPCHandler("Porkland", "update_undertile", function(data)
    local clientundertile = TheWorld and TheWorld.components.clientundertile
    if clientundertile then
        clientundertile:OnUnderTilesChange(DecodeAndUnzipString(data))
    end
end)

AddClientModRPCHandler("Porkland", "tile_changed", function(data)
    local tilechangewatcher = ThePlayer and ThePlayer.components.tilechangewatcher
    if tilechangewatcher then
        if TheWorld.ismastersim then
            -- TODO: Use the data if we have more granular updates in the future
            tilechangewatcher:NotifyUpdate()
        else
            -- Delay this for a frame on client to wait for the tile to update
            ThePlayer:DoStaticTaskInTime(0, function()
                -- TODO: Use the data if we have more granular updates in the future
                tilechangewatcher:NotifyUpdate()
            end)
        end
    end
end)

AddUserCommand("saveme", {
    aliases = nil,
    prettyname = nil,
    desc = nil,
    permission = COMMAND_PERMISSION.USER,
    confirm = false,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    localfn = function(params, caller)
        ThePlayer:DoTaskInTime(0, function()
            SendModRPCToServer(MOD_RPC["Porkland"]["teleport_to_home"])
        end)
    end,
})

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

AddShardModRPCHandler("Porkland", "SetAporkalypseClockRewindMult", function(shardid, rewind_mult)
    if not TheWorld.ismastershard then
        return
    end

    TheWorld:PushEvent("ms_setrewindmult", {mult = rewind_mult}) -- 传入的变量是单个数值，包装成键值对后推送事件
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

local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("inventoryitem", function(self, inst)
    inst:AddTag("isinventoryitem")
end)

local InventoryItem = require("components/inventoryitem")

local _OnDropped = InventoryItem.OnDropped
function InventoryItem:OnDropped(randomdir, speedmult, skipfall)
    _OnDropped(self, randomdir, speedmult)
    if not skipfall then
        self.inst:AddTag("falling")
    end
end

local _SetLanded = InventoryItem.SetLanded
function InventoryItem:SetLanded(is_landed, should_poll_for_landing)
    _SetLanded(self, is_landed, should_poll_for_landing)
    if is_landed then
        self.inst:RemoveTag("falling")
    end
end

function InventoryItem:OnHitCloud()
    self.inst:RemoveTag("falling")
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if self.inst:HasTag("irreplaceable") then
        local sx, sy, sz = FindRandomPointOnShoreFromOcean(x, y, z)
        if sx then
            self.inst.Transform:SetPosition(sx, sy, sz)
        else
            -- Our reasonable cases are out... so let's loop to find the portal and respawn there.
            for k, v in pairs(Ents) do
                if v:IsValid() and v:HasTag("multiplayer_portal") then
                    self.inst.Transform:SetPosition(v.Transform:GetWorldPosition())
                end
            end
        end
    else
        local fx = SpawnPrefab("splash_clouds_drop")
        fx.Transform:SetPosition(x, y, z)
        self.inst:Remove()
    end
end

local _SinkEntity = SinkEntity
function SinkEntity(entity, ...)
    if not entity:IsValid() or not TheWorld.has_pl_ocean then
        return _SinkEntity(entity, ...)
    end

    local px, py, pz = 0, 0, 0
    if entity.Transform then
        px, py, pz = entity.Transform:GetWorldPosition()
    end

    if entity.components.inventory then
        entity.components.inventory:DropEverything()
    end

    if entity.components.container then
        entity.components.container:DropEverything()
    end

    local fx = SpawnPrefab((TheWorld.Map:IsValidTileAtPoint(px, py, pz) and "splash_sink") or "splash_clouds_drop")
    fx.Transform:SetPosition(px, py, pz)

    -- If the entity is irreplaceable, respawn it at the player
    if entity:HasTag("irreplaceable") then
        local sx, sy, sz = FindRandomPointOnShoreFromOcean(px, py, pz)
        if sx ~= nil then
            entity.Transform:SetPosition(sx, sy, sz)
        else
            -- Our reasonable cases are out... so let's loop to find the portal and respawn there.
            for k, v in pairs(Ents) do
                if v:IsValid() and v:HasTag("multiplayer_portal") then
                    entity.Transform:SetPosition(v.Transform:GetWorldPosition())
                end
            end
        end
    else
        entity:Remove()
    end
end

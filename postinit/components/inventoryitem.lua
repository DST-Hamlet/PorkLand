local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("inventoryitem", function(self, inst)
    inst:AddTag("isinventoryitem")
    self.onimpassable = false
end)

local InventoryItem = require("components/inventoryitem")

function InventoryItem:KeepOnInterior()
    local x, y, z = self.inst.Transform:GetWorldPosition()

    if TheWorld.components.interiorspawner == nil then
        return
    end

    local isininteriorregion = TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)

    local isininteriorroom = TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)

    if isininteriorregion and not isininteriorroom then
        local pt = Vector3(x, y, z)
        local dest = FindNearbyLand(pt, 1)
        if not dest then
            dest = FindNearbyLand(pt, 2)
        end
        if not dest then
            dest = FindNearbyLand(pt, 4)
        end
        if dest ~= nil then
            if self.inst.Physics ~= nil then
                self.inst.Physics:Teleport(dest:Get())
            elseif self.inst.Transform ~= nil then
                self.inst.Transform:SetPosition(dest:Get())
            end
        end
    end
end

local _OnDropped = InventoryItem.OnDropped
function InventoryItem:OnDropped(randomdir, speedmult, skipfall)
    _OnDropped(self, randomdir, speedmult)
    self:SetLanded(false, true)
end

local _SetLanded = InventoryItem.SetLanded
function InventoryItem:SetLanded(is_landed, should_poll_for_landing)
    if is_landed or not should_poll_for_landing then
        self.inst:RemoveTag("falling")
    else
        self.inst:AddTag("falling")
        self:KeepOnInterior()
    end
    _SetLanded(self, is_landed, should_poll_for_landing)
end

function InventoryItem:OnHitCloud()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if self.inst:HasTag("irreplaceable") then
        local sx, _, sz = FindRandomPointOnShoreFromOcean(x, y, z)
        if sx then
            if self.inst.Physics then
                self.inst.Physics:Stop()
            end
            self.inst.Transform:SetPosition(sx, 5, sz)
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

local _OnUpdate = InventoryItem.OnUpdate
function InventoryItem:OnUpdate(dt, ...)
    local x, y, z = self.inst.Transform:GetWorldPosition()

    if x and y and z and self.inst.Physics and self.inst.Physics:GetCollisionGroup() == COLLISION.ITEMS then
        if self.inst.Physics then
            if not self.onimpassable and TheWorld.Map:IsImpassableAtPoint(x, 0, z) then
                self:SetLanded(false, true)
                self.onimpassable = true
                self.inst.Physics:ClearCollidesWith(COLLISION.GROUND - COLLISION.VOID_LIMITS)
            elseif self.onimpassable and not TheWorld.Map:IsImpassableAtPoint(x, 0, z) then
                self.onimpassable = false
                self.inst.Physics:CollidesWith(COLLISION.GROUND - COLLISION.VOID_LIMITS)
                self.inst.AnimState:SetLayer(LAYER_WORLD)
            end
        end
    end
    if self.onimpassable and self.inst.Physics and self.inst.Physics:GetCollisionGroup() == COLLISION.ITEMS then
        if y then
            if y < -0.01 then
                self.inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
                self.inst.Physics:CollidesWith(COLLISION.VOID_LIMITS)
            else
                self.inst.AnimState:SetLayer(LAYER_WORLD)  -- 虽然inventoryitem基本上都属于这个显示层级，但是保险起见，最好在改变显示层级的时候保存旧的显示层级
                self.inst.Physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
            end
            if y < -2 then
                self:TryToSink()
                if not self.inst:HasTag("irreplaceable") then
                    self.inst:StopUpdatingComponent(self)
                end
            end
        else
            self:TryToSink()
            if not self.inst:HasTag("irreplaceable") then
                self.inst:StopUpdatingComponent(self)
            end
        end
    else
        return _OnUpdate(self, dt, ...)
    end
end

function InventoryItem:Launch(veldirect)  --应当使用Launch函数替换所有会将inventoryitem一次性弹飞的效果
    if self.inst.Physics == nil then
        return
    end

    self:SetLanded(false, true)

    self.inst.Physics:SetVel(veldirect:Get())
end

local _SinkEntity = SinkEntity
function SinkEntity(entity, ...)
    if not entity:IsValid() or not TheWorld.has_pl_ocean then
        return _SinkEntity(entity, ...)
    end

    local px, py, pz = 0, 0, 0
    if entity.Transform then
        px, py, pz = entity.Transform:GetWorldPosition()

        if entity.persists
            and entity.components.inventoryitem
            and entity.components.inventoryitem.cangoincontainer
            -- and TheWorld.Map:GetTileAtPoint(px, py, pz) ~= WORLD_TILES.OCEAN_DEEP then
            and TheWorld.Map:GetTileAtPoint(px, py, pz) == WORLD_TILES.LILYPOND then

            local sunkenprefab = SpawnPrefab("sunkenprefab")
            sunkenprefab:Initialize(entity)
            local fx = SpawnPrefab("splash_sink")
            fx.Transform:SetPosition(px, py, pz)
            return
        end
    end

    if entity.components.inventory then
        entity.components.inventory:DropEverything()
    end

    if entity.components.container then
        entity.components.container:DropEverything()
    end

    local fx = SpawnPrefab((TheWorld.Map:IsImpassableAtPoint(px, py, pz) and "splash_clouds_drop") or "splash_sink")
    fx.Transform:SetPosition(px, py, pz)

    -- If the entity is irreplaceable, respawn it at the player
    if entity:HasTag("irreplaceable") then
        local sx, _, sz = FindRandomPointOnShoreFromOcean(px, py, pz)
        if sx ~= nil then
            if entity.Physics then
                entity.Physics:Stop()
            end
            entity.Transform:SetPosition(sx, 5, sz)
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

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

-- is_landed               用于确定物品是否完全停止
-- should_poll_for_landing 用于在物品没有完全停止的情况下决定是否要通过update来追踪完全停止
local _SetLanded = InventoryItem.SetLanded
function InventoryItem:SetLanded(is_landed, should_poll_for_landing)
    if not is_landed and should_poll_for_landing then
        self:KeepOnInterior()
    end
    _SetLanded(self, is_landed, should_poll_for_landing)
end

function InventoryItem:OnUpdate(dt) -- 覆盖法
    local x,y,z = self.inst.Transform:GetWorldPosition()

    if x and y and z then
        local vely = 0
        if self.inst.Physics then
            if self.inst.Physics:GetCollisionGroup() == COLLISION.ITEMS then
                local isimpassable = TheWorld.Map:IsImpassableAtPoint(x, 0, z)
                if not self.onimpassable and isimpassable then -- 进入虚空区域时执行
                    self.onimpassable = true
                    self.inst.Physics:ClearCollidesWith(COLLISION.GROUND - COLLISION.VOID_LIMITS)
                elseif self.onimpassable and not isimpassable then -- 离开虚空区域时执行
                    self.onimpassable = false
                    self.inst.Physics:CollidesWith(COLLISION.GROUND - COLLISION.VOID_LIMITS)
                    self.inst.AnimState:SetLayer(LAYER_WORLD)
                end

                if self.onimpassable then -- 坠入虚空判定
                    self:SetLanded(false, true) -- 试图推送离地事件
                    if y < -0.01 then
                        self.inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
                        self.inst.Physics:CollidesWith(COLLISION.VOID_LIMITS)
                    else
                        self.inst.AnimState:SetLayer(LAYER_WORLD)  -- 虽然inventoryitem基本上都属于这个显示层级，但是保险起见，最好在改变显示层级的时候保存旧的显示层级
                        self.inst.Physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
                    end
                    if y < -3 then
                        self:TryToSink()
                    end
                end
            end

            if not self.onimpassable then -- 在陆地区域时的判定
                local vx, vy, vz = self.inst.Physics:GetVelocity()
                vely = vy or 0

                if (not vx) or (not vy) or (not vz) then
                    self:SetLanded(true, false)
                    return
                elseif (vx == 0) and (vy == 0) and (vz == 0) then
                    self:SetLanded(true, false)
                    return
                else
                    if y + vely * dt * 1.5 < 0.01 and vely <= 0 then -- 接触地面时检测
                        if vx * vx + vz * vz > 0.25 then -- 接触地面且大于一定移动速度时强制推送落地事件
                            self.is_landed = false
                        end
                        self:SetLanded(true, false) -- 试图推送落地事件
                        StopUpdatingComponents[self] = nil -- SetLanded(true)会导致本组件的update停止更新
                    elseif y + vely * dt * 1.5 > 0.2 and vely >= 0 then
                        self:SetLanded(false, true) -- 试图推送离地事件
                    end
                end
            end
        end
    else -- 这不应该发生
        self:SetLanded(true, false)
    end
end

function InventoryItem:Launch(veldirect)  --应当使用Launch函数替换所有会将inventoryitem一次性弹飞的效果
    if self.inst.Physics == nil then
        return
    end

    self:SetLanded(false, true)

    self.inst.Physics:Old_SetVel(veldirect:Get())
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
            and TheWorld.Map:ReverseIsVisualWaterAtPoint(px, py, pz) then

            local sunkenprefab = SpawnPrefab("sunkenprefab")
            sunkenprefab:Initialize(entity)
            local fx = SpawnPrefab("splash_water_sink")
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
            local portal = TheSim:FindFirstEntityWithTag("multiplayer_portal")
            if portal and portal:IsValid() then
                entity.Transform:SetPosition(portal.Transform:GetWorldPosition())
            end
        end
    else
        entity:Remove()
    end
end


local CC_DEF = require("main/interior_texture_defs").CC_DEF

local InteriorVisitor = Class(function(self, inst)
    self.inst = inst

    self.center_ent = net_entity(inst.GUID, "interiorvisitor.center_ent")
    self.last_center_ent = nil
    self.exterior_pos_x = net_shortint(inst.GUID, "interiorvisitor.exterior_pos_x", "interiorvisitor.exterior_pos")
    self.exterior_pos_x:set_local(0)
    self.exterior_pos_z = net_shortint(inst.GUID, "interiorvisitor.exterior_pos_z", "interiorvisitor.exterior_pos")
    self.exterior_pos_z:set_local(0)
    self.interior_cc = net_smallbyte(inst.GUID, "interiorvisitor.interior_cc", "interiorvisitor.interior_cc")

    self.resetinteriorcamera = net_event(inst.GUID, "interiorvisitor.resetinteriorcamera")
    self.restore_outside_interior_camera = net_event(inst.GUID, "interiorvisitor.restoreoutsideinteriorcamera")

    -- inst:ListenForEvent("interiorvisitor.center_ent", OnCenterEntChanged)
    self.inst:ListenForEvent("interiorvisitor.restoreoutsideinteriorcamera", function()
        self:OnUpdate()
        if self.inst == ThePlayer then
            TheCamera:RestoreOutsideInteriorCamera()
        end
    end)

    self.interior_map = {}

    self.player_icon = SpawnPrefab("pl_local_icon")

    inst:StartUpdatingComponent(self)
end)

function InteriorVisitor:GetExteriorPos()
    return Point(
        self.exterior_pos_x:value(),
        0,
        self.exterior_pos_z:value()
    )
end

-- TODO: Make this actually work
function InteriorVisitor:IsInInterior(x, z)
    -- local pos = self.inst:GetPosition()
    -- local index = TheWorld.components.interiorspawner:PositionToIndex(pos)
end

function InteriorVisitor:GetInteriorCenterGeneric()
    local pos = self.inst:GetPosition()
    for _, v in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, 30, {"pl_interiorcenter"})) do
        return v
    end
end

-- function InteriorVisitor:GetInteriorCenterDedicated()
--     return TheWorld.components.interiorspawner:PositionToInteriorCenter()
-- end

local function IsInInteriorRectangle(player_pos, ent)
    if ent == nil or not ent:IsValid() then
        return false
    end
    local w, d = ent:GetSize()
    local offset = ent:GetPosition() - player_pos
    return math.abs(offset.x) < d/2 + 2 and math.abs(offset.z) < w/2 + 2
end

-- function InteriorVisitor:Activate()
--     print("InteriorVisitor:Activate()")
-- end

-- function InteriorVisitor:Deactivate()
--     print("InteriorVisitor:Deactivate()")
-- end

function InteriorVisitor:ApplyInteriorCamera(interior_center)
    local cameraoffset = -2.5         --10x15
    local zoom = 23
    local depth = interior_center:GetDepth()

    if interior_center.cameraoffset and interior_center.zoom then
        cameraoffset = interior_center.cameraoffset
        zoom = interior_center.zoom
    elseif depth == 12 then    --12x18
        cameraoffset = -2
        zoom = 25
    elseif depth == 16 then --16x24
        cameraoffset = -1.5
        zoom = 30
    elseif depth == 18 then --18x26
        cameraoffset = -2 -- -1
        zoom = 35
    end

    -- custom value
    if interior_center.pl_interior_distance ~= nil then
        zoom = interior_center.pl_interior_distance
    end
    if interior_center.pl_interior_cameraoffset ~= nil then
        cameraoffset = interior_center.pl_interior_cameraoffset
    else
        cameraoffset = Vector3(cameraoffset, 0, 0)
    end

    local pos = interior_center:GetPosition()
    TheCamera.inside_interior = true
    TheCamera.pl_interior_currentpos = pos + cameraoffset
    TheCamera.pl_interior_distance = zoom
end

function InteriorVisitor:RestoreOutsideInteriorCamera()
    self.restore_outside_interior_camera:push()
end

function InteriorVisitor:OnUpdate()
    if self.inst.components.interiorvisitor then
        self.inst.components.interiorvisitor:UpdateExteriorPos()
    end

    if self.inst ~= ThePlayer then
        return
    end

    local ambientlighting = TheWorld.components.ambientlighting
    local last_center_ent = self.last_center_ent
    local room_center_ent = self.center_ent:value()
    if IsInInteriorRectangle(self.inst:GetPosition(), room_center_ent) then
        self.inst:AddTag("inside_interior")
        self:ApplyInteriorCamera(room_center_ent)
        if room_center_ent:HasInteriorMinimap() then
            self.player_icon.MiniMapEntity:SetEnabled(false)
        else
            self.player_icon.MiniMapEntity:CopyIcon(self.inst.MiniMapEntity)
            self.player_icon.MiniMapEntity:SetEnabled(true)
            self.player_icon.Transform:SetPosition(self:GetExteriorPos():Get())
        end
        if last_center_ent ~= room_center_ent then
            self.last_center_ent = room_center_ent
            self.inst:PushEvent("enterinterior", {from = last_center_ent, to = room_center_ent})

            if self.inst.MiniMapEntity then
                self.inst.MiniMapEntity:SetEnabled(false)
            end
            if ambientlighting then
                ambientlighting:Pl_Refresh()
            end

            TheWorld.WaveComponent:SetWaveTexture(resolvefilepath("images/could/fog_cloud_interior.tex")) -- disable clouds
        end
    else
        self.inst:RemoveTag("inside_interior")
        self.player_icon.MiniMapEntity:SetEnabled(false)
        TheCamera.inside_interior = false
        self.last_center_ent = nil
        if last_center_ent ~= room_center_ent then
            self.inst:PushEvent("leaveinterior", {from = last_center_ent, to = nil})

            if self.inst.MiniMapEntity then
                self.inst.MiniMapEntity:SetEnabled(true)
            end
            if ambientlighting then
                ambientlighting:Pl_Refresh()
            end

            TheWorld.WaveComponent:SetWaveTexture(resolvefilepath("images/could/fog_cloud.tex")) -- enable clouds again
        end
    end
end

function InteriorVisitor:GetCenterEnt()
    local ent = self.center_ent:value()
    if ent and ent:IsValid() then
        return ent
    end
end

function InteriorVisitor:GetCCTable()
    local index = self.interior_cc:value()
    local cc = CC_DEF[index] and CC_DEF[index].path or "images/colour_cubes/day05_cc.tex"
    cc = resolvefilepath(cc) -- add prefix mod root
    return {
        day = cc, dusk = cc, night = cc, full_moon = cc
    }
end

function InteriorVisitor:OnNewInteriorMapData(data)
    for id, data in pairs(data) do
        self.interior_map[id] = data
    end
end

-- function InteriorVisitor:OnRemoveFromEntity()
--     self:Deactivate()
-- end

-- InteriorVisitor.OnRemoveEntity = InteriorVisitor.OnRemoveFromEntity

return InteriorVisitor

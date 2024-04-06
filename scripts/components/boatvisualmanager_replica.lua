local BoatVisualManager = Class(function(self, inst)
    self.inst = inst
    self.visuals = {}
    self.items = {}
    self._equipvisuals = {}

    for i = 1, 6 do--如果船的额外视觉子实体超过6个，那么会崩溃
        table.insert(self._equipvisuals, net_string(self.inst.GUID, "boatvisualmanager._equipvisuals["..tostring(i).."]", "equipvisuals["..tostring(i).."]dirty"))
    end

    for i, v in ipairs(self._equipvisuals) do
        inst:ListenForEvent("equipvisuals[" .. tostring(i) .. "]dirty", function()
            if self._equipvisuals[i]:value() == "" then
                self:RemoveBoatEquipVisuals_Client(i)
            else
                self:SpawnBoatEquipVisuals_Client(i, self._equipvisuals[i]:value())
            end
        end)
    end
end)

local function OnRemove(inst)
    inst.boat.boatvisuals[inst] = nil
end

function BoatVisualManager:SpawnBoatEquipVisuals(item, visualprefab)
    assert(visualprefab and type(visualprefab) == "string", "item.visualprefab must be a valid string!")

    local visual = SpawnPrefab("visual_" .. visualprefab .. "_boat")
    visual.entity:SetParent(self.inst.entity)
    self.visuals[item] = visual

    item.visual = visual
    visual.boat = self.inst

    visual.boat.boatvisuals[visual] = true
    visual:ListenForEvent("onremove", OnRemove)

    if visual.components.highlightchild then
        visual.components.highlightchild:SetOwner(visual.boat)
    end
    -- if self.inst.components.bloomer then
    --     self.inst.components.bloomer:AttachChild(visual)
    -- end
    if self.inst.components.colouradder then
        self.inst.components.colouradder:AttachChild(visual)
    end
    if self.inst.components.eroder then
        self.inst.components.eroder:AttachChild(visual)
    end

    visual:StartUpdatingComponent(visual.components.boatvisualanims)

    for i, v in pairs(self._equipvisuals) do
        if v:value() and v:value() == "" then
            v:set(visualprefab)
            self.items[item] = i
            return
        end
    end
end

function BoatVisualManager:SpawnBoatEquipVisuals_Client(itemnumber, visualprefab)
    assert(visualprefab and type(visualprefab) == "string", "item.visualprefab must be a valid string!")

    local visual = SpawnPrefab("visual_" .. visualprefab .. "_boat")
    visual.entity:SetParent(self.inst.entity)
    self.visuals[itemnumber] = visual

    visual.boat = self.inst

    visual.boat.boatvisuals[visual] = true
    visual:ListenForEvent("onremove", OnRemove)

    if visual.components.highlightchild then
        visual.components.highlightchild:SetOwner(visual.boat)
    end
    -- if self.inst.components.bloomer then
    --     self.inst.components.bloomer:AttachChild(visual)
    -- end
    if self.inst.components.colouradder then
        self.inst.components.colouradder:AttachChild(visual)
    end
    if self.inst.components.eroder then
        self.inst.components.eroder:AttachChild(visual)
    end

    visual:StartUpdatingComponent(visual.components.boatvisualanims)

end

function BoatVisualManager:RemoveBoatEquipVisuals(item)
    self._equipvisuals[self.items[item]]:set("")
    self.items[item] = nil
    item.visual = nil
    if self.visuals[item] then
        self.visuals[item]:Remove()
        self.visuals[item] = nil
    end
end

function BoatVisualManager:RemoveBoatEquipVisuals_Client(itemnumber)
    if self.visuals[itemnumber] then
        self.visuals[itemnumber]:Remove()
        self.visuals[itemnumber] = nil
    end
end

return BoatVisualManager

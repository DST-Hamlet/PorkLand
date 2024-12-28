local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("grass", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _onregenfn = inst.components.pickable.onregenfn
    local function onregenfn(inst, ...)
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        if NUTRIENT_TILES[tile] then
            local cycles_left = inst.components.pickable.cycles_left
            local tallgrass = ReplacePrefab(inst, "grass_tall")
            -- tallgrass.components.hackable.onregenfn(tallgrass)
            return
        end
        _onregenfn(inst, ...)
    end
    inst.components.pickable.onregenfn = onregenfn

    local _ontransplantfn = inst.components.pickable.ontransplantfn
    local function ontransplantfn(inst, ...)
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        if NUTRIENT_TILES[tile] then
            local tallgrass = ReplacePrefab(inst, "grass_tall")
            -- tallgrass.components.hackable:MakeEmpty()
            return
        end
        _ontransplantfn(inst, ...)
    end
    inst.components.pickable.ontransplantfn = ontransplantfn
end)

AddPrefabPostInit("dug_grass_placer", function(inst)
    local _OnUpdate = inst.components.placer.OnUpdate
    function inst.components.placer:OnUpdate(dt, ...)
        _OnUpdate(self, dt, ...)
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        if NUTRIENT_TILES[tile] then
            if not self.istall then
                self.istall = true
                self.inst.AnimState:SetBank("grass_tall")
                self.inst.AnimState:SetBuild("grass_tall")
                self.inst.AnimState:PlayAnimation("idle", true)
            end
        else
            if self.istall then
                self.istall = false
                self.inst.AnimState:SetBank("grass")
                self.inst.AnimState:SetBuild("grass1")
                self.inst.AnimState:PlayAnimation("idle", true)
            end
        end
    end
end)

local POSSIBLE_VARIANTS = require("prefabs/visualvariant_defs").POSSIBLE_VARIANTS

local function TryRecalc(inst)
	if inst and inst:IsValid()
	and inst.components.visualvariant
	and not inst.components.visualvariant.variant then
		inst.components.visualvariant:Recalc()
	end
end

local VisualVariant = Class(function(self, inst)
	self.inst = inst

	self.possible_variants = POSSIBLE_VARIANTS[self.inst.prefab]
	-- self.variant = "default"
	
	self.inst:DoTaskInTime(0,TryRecalc)
end)

function VisualVariant:GetVariantData(variant)
	return self.possible_variants ~= nil and self.possible_variants[variant or self.variant] or {}
end

function VisualVariant:GetVariant()
	return self.variant
end

function VisualVariant:CopyOf(source)
	if not source then return end

	if source.components.visualvariant then
		return self:Set(source.components.visualvariant.variant)
	end

	for k, v in pairs(self.possible_variants) do
		if (v.sourceprefabs and table.contains(v.sourceprefabs, source.prefab)) or
		   (v.sourcetags and source:HasOneOfTags(v.sourcetags)) then
			return self:Set(k)
		end
	end
end

function VisualVariant:Set(variant)
	local old_variant = self.variant
	if variant and self.possible_variants and self.possible_variants[variant] and self.inst.skinname == nil then
		self.variant = variant
	else
		self.variant = "default"
	end
    local old_variant_data = self:GetVariantData(old_variant)
	local variant_data = self:GetVariantData()
	if variant_data and self.variant ~= old_variant then
		if variant_data.name then
			if variant_data.name == "default" then
				if self.inst.components.named then
					if self.inst.components.named.possiblenames and #self.inst.components.named.possiblenames > 0 then
						self.inst.components.named:PickNewName()
					else
						self.inst.components.named:SetName()
					end
				end
			else
				if not self.inst.components.named then
					self.inst:AddComponent("named")
				end
				self.inst.components.named:SetName(STRINGS.NAMES[string.upper(variant_data.name)])
			end
		end
		if self.inst.AnimState then
			if old_variant_data.override ~= nil then
                for _,data in pairs(old_variant_data.override) do
                    self.inst.AnimState:ClearOverrideSymbol(data[1])
                end
			end
			if variant_data.build then
				self.inst.AnimState:SetBuild(variant_data.build)
			end
			if variant_data.bank then
				self.inst.AnimState:SetBank(variant_data.bank)
			end
			if variant_data.override ~= nil then
                for _,data in pairs(variant_data.override) do
				    self.inst.AnimState:OverrideSymbol(data[1], data[2], data[3])
                end
			end
		end
		if self.inst.MiniMapEntity and variant_data.minimap then
			self.inst.MiniMapEntity:SetIcon(variant_data.minimap)
		end
		if self.inst.components.inventoryitem and variant_data.invatlas
		--if items try to stack as soon as they spawn, they might not have a classified (apparently) -M
		and self.inst.replica.inventoryitem and self.inst.replica.inventoryitem.classified then
			if variant_data.invatlas == "default" then
				self.inst.components.inventoryitem.atlasname = resolvefilepath("images/inventoryimages.xml")
			else
				self.inst.components.inventoryitem.atlasname = resolvefilepath(variant_data.invatlas)
			end
			self.inst:PushEvent("imagechange")
		end
	end
end

function VisualVariant:Recalc()
	local valid_variants = {}
	local desired_variants = {}
	for k, v in pairs(self.possible_variants) do
		if v.testfn then
			if v.testfn(self.inst) then
				table.insert(desired_variants, k)
			end
		else
			table.insert(valid_variants, k)
		end
	end
	--if the current variant is still valid or desired, keep it
	if self.variant and (table.contains(valid_variants, self.variant) or table.contains(desired_variants, self.variant)) then
		--Change nothing
	elseif #desired_variants > 0 then
		--if default is desired, pick that
		if table.contains(desired_variants, "default") then
			self:Set()
		else
			self:Set(desired_variants[1])
		end
	else
		--if default is valid, pick that
		if table.contains(valid_variants, "default") then
			self:Set()
		else
			self:Set(valid_variants[1])
		end
	end
end

function VisualVariant:OnSave()
	return {
		variant = self.variant,
	}
end

function VisualVariant:OnLoad(data)
	local variant
	if data then
		variant = data.variant or self.variant
	end
	if variant then
		self:Set(variant)
	else
		self:Recalc()
	end
end

return VisualVariant

local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphState = AddStategraphState
GLOBAL.setfenv(1, GLOBAL)

local function FixupMinionCarry(inst, swap)
    if inst.sg.mem.swaptool == swap then
        return false
    end
    inst.sg.mem.swaptool = swap
    if swap == nil then
        inst.AnimState:ClearOverrideSymbol("swap_object")
        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Show("ARM_normal")
    else
        inst.AnimState:Show("ARM_carry")
        inst.AnimState:Hide("ARM_normal")
        inst.AnimState:OverrideSymbol("swap_object", swap, swap)
    end
    return true
end

local states = {
    State{
        name = "item_out_sword",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("item_out")
            inst.sg:RemoveStateTag("busy")
            inst.sg:AddStateTag("idle")
        end,

        events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
    }
}

for _, state in pairs(states) do
    AddStategraphState("shadowwaxwell", state)
end

AddStategraphPostInit("shadowwaxwell", function(sg)
    local _doattack_fn = sg.events["doattack"].fn
    sg.events["doattack"].fn = function(inst, data)
        if FixupMinionCarry(inst, "swap_nightmaresword_shadow") then
            inst.sg:GoToState("item_out_sword")
        else
            _doattack_fn(inst, data)
        end
    end
end)

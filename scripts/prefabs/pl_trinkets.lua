
function PickRandomTrinket()
    local chessunlocks = TheWorld.components.chessunlocks

	local has_locked_chess = chessunlocks ~= nil and (chessunlocks:GetNumLockedTrinkets() > 0)
	local is_hallowednights = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS)

	local unlocked_trinkets = {}
	for i = 1,NUM_TRINKETS do
		if (not has_locked_chess or not chessunlocks:IsLocked("trinket_"..i))
			and (is_hallowednights or not(i >= HALLOWEDNIGHTS_TINKET_START and i <= HALLOWEDNIGHTS_TINKET_END)) then

			table.insert(unlocked_trinkets, i)
		end
    end

    return "trinket_"..unlocked_trinkets[math.random(#unlocked_trinkets)]
end

local assets =
{
    Asset("ANIM", "anim/trinkets_giftshop.zip"),
}

local SMALLFLOATS =
{
    [0]     = {0.9, 0.0},
    [1]     = {0.7, 0.1},
    [2]     = {0.6, 0.1},
}

local function MakeTrinket(num)
    local prefabs = {}

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

		--local amin = num > 6 and "trinkets_ia" or "sea_trinkets"
        inst.AnimState:SetBank("trinkets_giftshop")
        inst.AnimState:SetBuild("trinkets_giftshop")
        inst.AnimState:PlayAnimation(tostring(num))

        inst:AddTag("molebait")
        inst:AddTag("cattoy")

        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inventoryitem")

        if SMALLFLOATS[num] ~= nil then
            inst.components.floater:SetScale(SMALLFLOATS[num][1])
            inst.components.floater:SetVerticalOffset(SMALLFLOATS[num][2])
        end

        inst:AddComponent("tradable")
        inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.TRINKETS[num] or 3

		if num >= HALLOWEDNIGHTS_TINKET_START and num <= HALLOWEDNIGHTS_TINKET_END then
	        if IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) then
				inst.components.tradable.halloweencandyvalue = 5
			end
		end
		inst.components.tradable.rocktribute = math.ceil(inst.components.tradable.goldvalue / 3)

        MakeHauntableLaunchAndSmash(inst)

        inst:AddComponent("bait")

        return inst
    end

    return Prefab("trinket_giftshop_"..tostring(num), fn, assets, prefabs)
end

local ret = {}
--for k = 1, 4 do
--    table.insert(ret, MakeTrinket(k))
--end
table.insert(ret, MakeTrinket(1))
table.insert(ret, MakeTrinket(3))
--table.insert(ret, MakeTrinket(4)) -- look deflated_balloon

return unpack(ret)
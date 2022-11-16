AddPrefabPostInitAny = AddPrefabPostInitAny
GLOBAL.setfenv(1, GLOBAL)

local poisonimmune_prefabs = table.invert({
    "wx78"
})

local poisonimmune_tags = {
    "fx",
    "shadow",
    "chess",
    "wall",
    "poisonimmune",
    "mech",
    "brightmare",
    "hive",
    "ghost",
    "veggie",
    "balloon",
}

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if not poisonimmune_prefabs[inst.prefab] and not inst:HasOneOfTags(poisonimmune_tags) then
        if inst.components.combat and inst.components.health and not inst.components.poisonable then
            if inst:HasTag("player") then
                MakePoisonableCharacter(inst, nil, nil, "player", 0, 0, 1)
                inst.components.poisonable.duration = TUNING.TOTAL_DAY_TIME * 3
                inst.components.poisonable.transfer_poison_on_attack = false
            else
                MakePoisonableCharacter(inst)
            end
        end
    end
end)

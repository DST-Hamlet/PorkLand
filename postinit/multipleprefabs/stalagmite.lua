local AddSimPostInit = AddSimPostInit
GLOBAL.setfenv(1, GLOBAL)

-- Remove fossil_pieces because there's no use for it

local function sim_postinit()
    SetSharedLootTable( 'full_rock',
    {
        {'rocks',       1.00},
        {'rocks',       1.00},
        {'rocks',       1.00},
        {'goldnugget',  1.00},
        {'flint',       1.00},
        --{'fossil_piece',0.10},
        {'goldnugget',  0.25},
        {'flint',       0.60},
        {'bluegem',     0.05},
        {'redgem',      0.05},
    })

    SetSharedLootTable( 'med_rock',
    {
        {'rocks',       1.00},
        {'rocks',       1.00},
        {'flint',       1.00},
        {'goldnugget',  0.50},
        --{'fossil_piece',0.10},
        {'flint',       0.60},
    })

    SetSharedLootTable( 'low_rock',
    {
        {'rocks',       1.00},
        {'flint',       1.00},
        {'goldnugget',  0.50},
        --{'fossil_piece',0.10},
        {'flint',       0.30},
    })

    SetSharedLootTable('stalagmite_tall_full_rock',
    {
        {'rocks',       1.00},
        {'rocks',       1.00},
        {'goldnugget',  1.00},
        {'flint',       1.00},
        --{'fossil_piece',0.10},
        {'goldnugget',  0.25},
        {'flint',       0.60},
        {'redgem',      0.05},
        {'log',         0.05},
    })

    SetSharedLootTable('stalagmite_tall_med_rock',
    {
        {'rocks',       1.00},
        {'rocks',       1.00},
        {'flint',       1.00},
        --{'fossil_piece',0.10},
        {'goldnugget',  0.15},
        {'flint',       0.60},
    })

    SetSharedLootTable('stalagmite_tall_low_rock',
    {
        {'rocks',       1.00},
        {'flint',       1.00},
        --{'fossil_piece',0.10},
        {'goldnugget',  0.15},
        {'flint',       0.30},
    })
end

-- needs AddSimPostInit because prefab files are not loaded yet
AddSimPostInit(sim_postinit)

IA_AllBoons = {}

local function AddBoons(area, name)
    if not IA_AllBoons[area] then
        IA_AllBoons[area] = {}
    end

    table.insert(IA_AllBoons[area], name)
    AddLayoutToSanbox("map/boons", area, name)
end

AddBoons("Shipwrecked_Any", "SeaFarerBoon")
AddBoons("Shipwrecked_Any", "JungleHackerBoon")
AddBoons("Shipwrecked_Any", "DrunkenPirateBoon")

AddBoons("Water", "AbandonedRaftBoon")
AddBoons("Water", "AbandonedSailBoon")

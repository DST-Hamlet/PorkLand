local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

local Eater = require("components/eater")

function Eater:SetCarnivore(human)
    if human then
        self.inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.MEAT, FOODTYPE.GOODIES })
    else
        self.inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
    end
end

function Eater:SetVegetarian(human)
    if human then
        self.inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.VEGGIE })
    else
        self.inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
    end
end

function Eater:SetInsectivore()
    self.inst.components.eater:SetDiet({ FOODTYPE.INSECT }, { FOODTYPE.INSECT })
end

function Eater:SetBird()
    self.inst.components.eater:SetDiet({ FOODTYPE.SEEDS }, { FOODTYPE.SEEDS })
end

function Eater:SetBeaver()
    self.inst.components.eater:SetDiet({ FOODTYPE.WOOD }, { FOODTYPE.WOOD })
end

function Eater:SetElemental(human)
    if human then
        self.inst.components.eater:SetDiet({ FOODTYPE.MEAT, FOODTYPE.VEGGIE, FOODTYPE.INSECT, FOODTYPE.SEEDS, FOODTYPE.GENERIC, FOODTYPE.ELEMENTAL }, { FOODTYPE.ELEMENTAL })
    else
        self.inst.components.eater:SetDiet({ FOODTYPE.ELEMENTAL }, { FOODTYPE.ELEMENTAL })
    end
end

function Eater:SetOmnivore()
    self.inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
end

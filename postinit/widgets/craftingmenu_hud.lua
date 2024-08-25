local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self)
    self.inst:ListenForEvent("enterinterior", function() self:UpdateRecipes() end, self.owner)
    self.inst:ListenForEvent("leaveinterior", function() self:UpdateRecipes() end, self.owner)
end)

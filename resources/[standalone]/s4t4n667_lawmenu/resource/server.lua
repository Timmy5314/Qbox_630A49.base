--[[
    Bewust leeg.

    Hier stond `lib.versionCheck('s4t4n667/s4t4n667_lawmenu')`, dat bij elke
    serverstart een HTTP-call naar GitHub doet. Op een productieserver voegt dat
    niets toe en het maakt het opstarten afhankelijk van een externe dienst.

    Deze resource heeft verder geen serverkant nodig: het menu toont alleen
    tekst en zet dingen op het klembord. Er valt niets te valideren en er is
    geen speleractie die de server moet goedkeuren.
]]

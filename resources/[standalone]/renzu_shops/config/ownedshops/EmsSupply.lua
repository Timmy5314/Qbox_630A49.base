-- EMS-uitgifte in Pillbox Hospital.
--
-- ND_Ambulance levert zelf geen enkele winkel of locker met items, waardoor EMS
-- nergens een medbag, defib of brancard vandaan kon halen. Dit vult dat gat.
--
-- De coordinaten komen uit ND_Ambulance/data (respawn- en behandelpunten in
-- Pillbox), dus ze zijn op deze server aantoonbaar geldig. Bijstellen naar de
-- exacte plek in de EMS-ruimte kan alsnog nodig zijn - dat is niet vanaf hier
-- te controleren.
--
-- Niet te koop: dit is job-gated op ambulance, geen speler-eigendom.
return {
	[1] = {
		groups = {'ambulance'},
		moneytype = 'money',
		label = 'EMS Supply', -- identifier, niet hernoemen zodra in gebruik
		coord = vec3(306.6618, -597.3710, 43.2611),
		price = 0, -- niet koopbaar
		supplieritem = shared.Storeitems.EmsSupply,
	}
}

return {
    -- Server-authoritative locatie van het inlever-/uitpakpunt (spiegelt config.client.dropLocation).
    -- Wordt gebruikt om te verifiëren dat de speler echt in de recyclehal staat.
    dropLocation		= vec3(1048.224, -3097.071, -38.999),
    maxDropDistance		= 12.0,
    payoutCooldown		= 4000, -- ms; één uitbetaling per pakket-cyclus (pickup ~5s + deliver 5s)
    maxItemsReceived 	= 5,
    minItemReceivedQty 	= 2,
    maxItemReceivedQty 	= 6,
    chanceItem 			= 'cryptostick',
    luckyItem 			= 'rubber',
    itemTable = {
        [1] = 'metalscrap',
        [2] = 'plastic',
        [3] = 'copper',
        [4] = 'iron',
        [5] = 'aluminum',
        [6] = 'steel',
        [7] = 'glass',
    }
}
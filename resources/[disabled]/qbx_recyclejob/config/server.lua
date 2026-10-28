return {
    maxItemsReceived 	= 3, -- [OUR CHANGE] was 5. Fewer, real-priced materials (~$510/hr at rp_buyers)
    minItemReceivedQty 	= 2,
    maxItemReceivedQty 	= 4, -- [OUR CHANGE] was 6
    chanceItem 			= 'copper', -- [OUR CHANGE] was 'cryptostick' (no use). Now a 6% bonus piece of copper
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
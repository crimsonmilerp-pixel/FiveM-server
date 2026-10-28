return {
    discordWebhook = nil, -- Replace nil with your webhook if you chose to use discord logging over ox_lib logging
    coralTypes = {
        {item = 'dendrogyra_coral', maxAmount = math.random(1, 5), price = math.random(16, 22)}, -- [OUR CHANGE] was random(70, 100). Aims for ~$720/hr
        {item = 'antipatharia_coral', maxAmount = math.random(2, 7), price = math.random(11, 15)}, -- [OUR CHANGE] was random(50, 70)
    },
    priceModifiers = {
        {minAmount = 5,  maxAmount = 10, minPercentage = 80, maxPercentage = 85},
        {minAmount = 11, maxAmount = 15, minPercentage = 70,  maxPercentage = 75},
        {minAmount = 16, minPercentage = 50, maxPercentage = 55},
    },
}
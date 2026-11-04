-- ============================================================
--  rp_economy - settings
--  The numbers come from docs/economy.xlsx (Settings and Taxes & Loans tabs).
--  If you change one here, change it in the sheet too so they match.
--  All text players see: locales/en.json
-- ============================================================
return {
    -- Income tax, taken off every paycheck and job payout ("Taken from each paycheck", decided Nov 4).
    -- Each line: weekly job income above `over` dollars is taxed at `rate` percent.
    -- US federal brackets divided by 12 (one real week = one "month"). Crime money is never taxed.
    incomeTax = {
        { over = 0,     rate = 10 },
        { over = 1000,  rate = 12 },
        { over = 4200,  rate = 22 },
        { over = 8800,  rate = 24 },
        { over = 16800, rate = 32 },
    },

    -- The tax week starts every Monday at this hour (UTC).
    -- 5 = midnight US Eastern in winter (1 am in summer).
    weekStartUtcHour = 5,

    -- Weekly bills: due every this many real days, and only charged while the player is in the city.
    -- Someone away for three weeks comes back to one bill, not three (decided Oct 27).
    billEveryDays = 7,
    checkEveryMinutes = 5, -- how often the server looks for bills that are due

    -- Luxury upkeep on vehicles: 6% a year on the value above $100,000, one twelfth each real week.
    -- A $3M hypercar costs about $14,500 a week. Cars under the line cost nothing to keep.
    luxuryVehicles = {
        line = 100000,
        yearlyRate = 0.06,
        weeksPerYear = 12,
    },

    -- Jobs paid by the government. Their paychecks count as treasury spending (it never stops pay).
    governmentJobs = {
        police = true,
        ambulance = true,
    },

    -- Loans and credit (car loans now; mortgages come with housing).
    -- Rates match docs/economy.xlsx (Settings: new car 7%, used car 11% for average credit).
    loans = {
        startScore = 650,                 -- every new character starts here ("thin credit")
        minScore = 300,
        maxScore = 850,
        scoreChange = {
            onTime = 5,                   -- each payment made on time
            paidOff = 25,                 -- extra when a loan is paid off
            missed = -40,                 -- each missed payment
            repossessed = -150,           -- when the bank takes the car back
        },
        -- Interest by credit score, highest first. Below the last line the bank says no.
        -- `id` picks the name players see (locales: credit.excellent, credit.good...).
        rates = {
            { minScore = 750, apr = 5.5, id = 'excellent' },
            { minScore = 670, apr = 7,   id = 'good' },
            { minScore = 580, apr = 11,  id = 'fair' },
            { minScore = 500, apr = 16,  id = 'poor' },
        },
        car = {
            minDownPercent = 10,          -- at least 10% down
            minLoan = 1000,               -- smaller than this: just buy it
            minWeeks = 12,                -- weekly payments (one real week = one "month")
            maxWeeks = 72,
            -- How much the bank lends: all your loan payments together can be up to $400 a week
            -- (so anyone can finance a first car of about $20k), or up to 35% of your average
            -- weekly job income over the last 4 tax weeks if that's more.
            starterPayment = 400,
            incomeShare = 0.35,
            incomeWeeks = 4,
            maxActive = 3,                -- car loans at once
            firstPaymentAfterDays = 3,    -- a loan this new skips the next weekly bill
            lateFeePercent = 5,           -- late fee on a missed payment (added to what you owe)
            minLateFee = 25,
            missesBeforeRepo = 3,         -- missed payments in a row before the bank takes the car
        },
    },

    -- Who can open /treasury and use /billsnow (an ace from permissions.cfg).
    staffAce = 'admin',
    staffGroup = 'group.admin',
}

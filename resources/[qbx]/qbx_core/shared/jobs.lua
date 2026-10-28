---Job names must be lower case (top level table key)
---@type table<string, Job>

-- [OUR CHANGE] Job pay (economy v2, Oct 27 2026). See docs/core-changes.md and docs/economy.xlsx (Jobs & Pay).
-- `payment` is paid every 10 minutes, and only while ON DUTY (offDutyPay = false).
-- Pay per hour = payment x 6. Target pay per hour = real hourly wage x 30.
--   * Task jobs (taxi, trucker, tow, garbage, vineyard) pay 0 here. They pay per fare / stop / delivery
--     in their own resource, so you only earn by working (Pillar B).
--   * Shift jobs (police, EMS, mechanic) start OFF duty (defaultDuty = false). Clock in at the station or shop to get paid.
--   * Commission / client-fee jobs (car dealer, real estate, lawyer) pay 0 here. They earn from sales and clients.
return {
    ['unemployed'] = {
        label = 'Civilian',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Freelancer',
                payment = 0 -- [OUR CHANGE] was 10. No free paycheck for idling (design pillar B). See docs/core-changes.md
            },
        },
    },
    ['police'] = {
        label = 'LSPD',
        type = 'leo',
        defaultDuty = false, -- [OUR CHANGE] was true. Clock in at the station to get paid.
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Officer = $1,080/hr (real $36/hr x 30)
            [0] = {
                name = 'Recruit',
                payment = 150 -- $900/hr
            },
            [1] = {
                name = 'Officer',
                payment = 180 -- $1,080/hr
            },
            [2] = {
                name = 'Sergeant',
                payment = 210 -- $1,260/hr
            },
            [3] = {
                name = 'Lieutenant',
                payment = 240 -- $1,440/hr
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 270 -- $1,620/hr
            },
        },
    },
    ['bcso'] = {
        label = 'BCSO',
        type = 'leo',
        defaultDuty = false, -- [OUR CHANGE] was true. Clock in at the station to get paid.
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Same as LSPD.
            [0] = {
                name = 'Recruit',
                payment = 150
            },
            [1] = {
                name = 'Officer',
                payment = 180
            },
            [2] = {
                name = 'Sergeant',
                payment = 210
            },
            [3] = {
                name = 'Lieutenant',
                payment = 240
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 270
            },
        },
    },
    ['sasp'] = {
        label = 'SASP',
        type = 'leo',
        defaultDuty = false, -- [OUR CHANGE] was true. Clock in at the station to get paid.
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Same as LSPD.
            [0] = {
                name = 'Recruit',
                payment = 150
            },
            [1] = {
                name = 'Officer',
                payment = 180
            },
            [2] = {
                name = 'Sergeant',
                payment = 210
            },
            [3] = {
                name = 'Lieutenant',
                payment = 240
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 270
            },
        },
    },
    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = false, -- [OUR CHANGE] was true. Clock in at the hospital to get paid.
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Paramedic = $720/hr (real $24/hr x 30)
            [0] = {
                name = 'Recruit',
                payment = 100 -- $600/hr
            },
            [1] = {
                name = 'Paramedic',
                payment = 120 -- $720/hr
            },
            [2] = {
                name = 'Doctor',
                payment = 180 -- $1,080/hr
            },
            [3] = {
                name = 'Surgeon',
                payment = 220 -- $1,320/hr
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 250 -- $1,500/hr
            },
        },
    },
    ['realestate'] = {
        label = 'Real Estate',
        type = 'realestate',
        defaultDuty = true,
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Agents will earn commission on sales (Phase 10: properties).
            [0] = {
                name = 'Recruit',
                payment = 0
            },
            [1] = {
                name = 'House Sales',
                payment = 0
            },
            [2] = {
                name = 'Business Sales',
                payment = 0
            },
            [3] = {
                name = 'Broker',
                payment = 0
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 0
            },
        },
    },
    ['taxi'] = {
        label = 'Taxi',
        defaultDuty = true,
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Paid per fare (qbx_taxijob meter).
            [0] = {
                name = 'Recruit',
                payment = 0
            },
            [1] = {
                name = 'Driver',
                payment = 0
            },
            [2] = {
                name = 'Event Driver',
                payment = 0
            },
            [3] = {
                name = 'Sales',
                payment = 0
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 0
            },
        },
    },
    -- [OUR CHANGE] 'bus' removed Oct 27: job cut (qbx_busjob disabled). See docs/core-changes.md
    ['cardealer'] = {
        label = 'Vehicle Dealer',
        defaultDuty = true,
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Paid by commission per car sold (qbx_vehicleshop commissionRate).
            [0] = {
                name = 'Recruit',
                payment = 0
            },
            [1] = {
                name = 'Showroom Sales',
                payment = 0
            },
            [2] = {
                name = 'Business Sales',
                payment = 0
            },
            [3] = {
                name = 'Finance',
                payment = 0
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 0
            },
        },
    },
    ['mechanic'] = {
        label = 'Mechanic',
        type = 'mechanic',
        defaultDuty = false, -- [OUR CHANGE] was true. Clock in at the shop to get paid.
        offDutyPay = false,
        grades = { -- [OUR CHANGE] was 50/75/100/125/150. Small base pay while clocked in; the rest comes from charging customers.
            [0] = {
                name = 'Recruit',
                payment = 50 -- $300/hr base
            },
            [1] = {
                name = 'Novice',
                payment = 55 -- $330/hr base
            },
            [2] = {
                name = 'Experienced',
                payment = 60 -- $360/hr base
            },
            [3] = {
                name = 'Advanced',
                payment = 70 -- $420/hr base
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 80 -- $480/hr base
            },
        },
    },
    ['judge'] = {
        label = 'Honorary',
        defaultDuty = false, -- [OUR CHANGE] was true. No courthouse clock-in exists yet, so judges aren't paid until Phase 3 adds one.
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Judge',
                payment = 375 -- [OUR CHANGE] was 100. $2,250/hr (real $75/hr x 30), paid only while on duty.
            },
        },
    },
    ['lawyer'] = {
        label = 'Law Firm',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Associate',
                payment = 0 -- [OUR CHANGE] was 50. Lawyers earn client fees (Phase 3).
            },
        },
    },
    ['reporter'] = {
        label = 'Reporter',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Journalist',
                payment = 0 -- [OUR CHANGE] was 50. Anyone can take this job at City Hall and it has no clock-in, so a wage would pay idlers. Pay per story is to build.
            },
        },
    },
    ['trucker'] = {
        label = 'Trucker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 0 -- [OUR CHANGE] was 50. Paid per delivery (qbx_truckerjob).
            },
        },
    },
    ['tow'] = {
        label = 'Towing',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 0 -- [OUR CHANGE] was 50. Paid per tow (qbx_towjob).
            },
        },
    },
    ['garbage'] = {
        label = 'Garbage',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Collector',
                payment = 0 -- [OUR CHANGE] was 50. Paid per bag (qbx_garbagejob).
            },
        },
    },
    ['vineyard'] = {
        label = 'Vineyard',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Picker',
                payment = 0 -- [OUR CHANGE] was 50. Will be paid by selling what you make (buyer to build).
            },
        },
    },
    -- [OUR CHANGE] 'hotdog' removed Oct 27: no hot dog script is installed.
}

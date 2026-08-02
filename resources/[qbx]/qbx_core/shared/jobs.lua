---Job names must be lower case (top level table key)
---@type table<string, Job>
--
-- LOON-MODEL (besluit Tim, aug 2026 — zie ECONOMY.md).
-- payment = per loonstrook; qbx_core betaalt 6x per uur (paycheckTimeout 10 min).
--   Instapjob   $100/strook = $600/uur
--   Ervaren job $200/strook = $1.200/uur (top grade)
--   Hulpdienst  $250/strook = $1.500/uur (top grade), recruit $150 = $900/uur
--   Werkloos    $25/strook  = $150/uur (overlevingsvloer, geen wage)
-- Netto ligt ~20% lager door belasting + verzekering (los_insurance).
--
-- GANGS KRIJGEN BEWUST GEEN LOON. Ballas, Vagos, Families, Marabunta, Mafia enz.
-- staan in shared/gangs.lua (de gang-slot, PlayerData.gang) en hebben daar GEEN
-- `payment`. De loonstrook-lus (server/loops.lua) betaalt alleen PlayerData.job.
-- Voeg dus NOOIT een gang als job met een `payment` toe: gangs verdienen via
-- drugs/turfs/overvallen, niet via een uurloon.
return {
    ['unemployed'] = {
        label = 'Civilian',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Freelancer',
                payment = 75
            },
        },
    },
    ['police'] = {
        label = 'LSPD',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 450
            },
            [1] = {
                name = 'Officer',
                payment = 525
            },
            [2] = {
                name = 'Sergeant',
                payment = 600
            },
            [3] = {
                name = 'Lieutenant',
                payment = 675
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 750
            },
        },
    },
    ['bcso'] = {
        label = 'BCSO',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 450
            },
            [1] = {
                name = 'Officer',
                payment = 525
            },
            [2] = {
                name = 'Sergeant',
                payment = 600
            },
            [3] = {
                name = 'Lieutenant',
                payment = 675
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 750
            },
        },
    },
    ['sasp'] = {
        label = 'SASP',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 450
            },
            [1] = {
                name = 'Officer',
                payment = 525
            },
            [2] = {
                name = 'Sergeant',
                payment = 600
            },
            [3] = {
                name = 'Lieutenant',
                payment = 675
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 750
            },
        },
    },
    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 450
            },
            [1] = {
                name = 'Paramedic',
                payment = 525
            },
            [2] = {
                name = 'Doctor',
                payment = 600
            },
            [3] = {
                name = 'Surgeon',
                payment = 675
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 750
            },
        },
    },
    ['realestate'] = {
        label = 'Real Estate',
        type = 'realestate',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 300
            },
            [1] = {
                name = 'House Sales',
                payment = 375
            },
            [2] = {
                name = 'Business Sales',
                payment = 450
            },
            [3] = {
                name = 'Broker',
                payment = 525
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 600
            },
        },
    },
    ['taxi'] = {
        label = 'Taxi',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 300
            },
            [1] = {
                name = 'Driver',
                payment = 375
            },
            [2] = {
                name = 'Event Driver',
                payment = 450
            },
            [3] = {
                name = 'Sales',
                payment = 525
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 600
            },
        },
    },
    ['bus'] = {
        label = 'Bus',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 300
            },
        },
    },
    ['cardealer'] = {
        label = 'Vehicle Dealer',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 300
            },
            [1] = {
                name = 'Showroom Sales',
                payment = 375
            },
            [2] = {
                name = 'Business Sales',
                payment = 450
            },
            [3] = {
                name = 'Finance',
                payment = 525
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 600
            },
        },
    },
    ['mechanic'] = {
        label = 'Mechanic',
        type = 'mechanic',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 300
            },
            [1] = {
                name = 'Novice',
                payment = 375
            },
            [2] = {
                name = 'Experienced',
                payment = 450
            },
            [3] = {
                name = 'Advanced',
                payment = 525
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 600
            },
        },
    },
judge = {
    label = 'Department of Justice',
    type = 'doj',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Clerk', payment = 375 },
        ['1'] = { name = 'Magistrate', payment = 525 },
        ['2'] = { name = 'Judge', isboss = true, payment = 600 },
    },
},
lawyer = {
    label = 'Law Firm',
    type = 'doj',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Paralegal', payment = 300 },
        ['1'] = { name = 'Associate', payment = 450 },
        ['2'] = { name = 'Partner', isboss = true, payment = 600 },
    },
},
    ['reporter'] = {
        label = 'Reporter',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Journalist',
                payment = 300
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
                payment = 300
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
                payment = 300
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
                payment = 300
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
                payment = 300
            },
        },
    },
    ['hotdog'] = {
        label = 'Hotdog',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Sales',
                payment = 300
            },
        },
    },
}

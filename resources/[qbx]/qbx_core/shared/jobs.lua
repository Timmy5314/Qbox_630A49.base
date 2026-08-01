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
                payment = 25
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
                payment = 150
            },
            [1] = {
                name = 'Officer',
                payment = 175
            },
            [2] = {
                name = 'Sergeant',
                payment = 200
            },
            [3] = {
                name = 'Lieutenant',
                payment = 225
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 250
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
                payment = 150
            },
            [1] = {
                name = 'Officer',
                payment = 175
            },
            [2] = {
                name = 'Sergeant',
                payment = 200
            },
            [3] = {
                name = 'Lieutenant',
                payment = 225
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 250
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
                payment = 150
            },
            [1] = {
                name = 'Officer',
                payment = 175
            },
            [2] = {
                name = 'Sergeant',
                payment = 200
            },
            [3] = {
                name = 'Lieutenant',
                payment = 225
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 250
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
                payment = 150
            },
            [1] = {
                name = 'Paramedic',
                payment = 175
            },
            [2] = {
                name = 'Doctor',
                payment = 200
            },
            [3] = {
                name = 'Surgeon',
                payment = 225
            },
            [4] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 250
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
                payment = 100
            },
            [1] = {
                name = 'House Sales',
                payment = 125
            },
            [2] = {
                name = 'Business Sales',
                payment = 150
            },
            [3] = {
                name = 'Broker',
                payment = 175
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 200
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
                payment = 100
            },
            [1] = {
                name = 'Driver',
                payment = 125
            },
            [2] = {
                name = 'Event Driver',
                payment = 150
            },
            [3] = {
                name = 'Sales',
                payment = 175
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 200
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
                payment = 100
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
                payment = 100
            },
            [1] = {
                name = 'Showroom Sales',
                payment = 125
            },
            [2] = {
                name = 'Business Sales',
                payment = 150
            },
            [3] = {
                name = 'Finance',
                payment = 175
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 200
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
                payment = 100
            },
            [1] = {
                name = 'Novice',
                payment = 125
            },
            [2] = {
                name = 'Experienced',
                payment = 150
            },
            [3] = {
                name = 'Advanced',
                payment = 175
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 200
            },
        },
    },
judge = {
    label = 'Department of Justice',
    type = 'doj',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Clerk', payment = 125 },
        ['1'] = { name = 'Magistrate', payment = 175 },
        ['2'] = { name = 'Judge', isboss = true, payment = 200 },
    },
},
lawyer = {
    label = 'Law Firm',
    type = 'doj',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Paralegal', payment = 100 },
        ['1'] = { name = 'Associate', payment = 150 },
        ['2'] = { name = 'Partner', isboss = true, payment = 200 },
    },
},
    ['reporter'] = {
        label = 'Reporter',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Journalist',
                payment = 100
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
                payment = 100
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
                payment = 100
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
                payment = 100
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
                payment = 100
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
                payment = 100
            },
        },
    },
}

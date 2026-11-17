-- Defaults. Admins change these in game (/whip -> Settings -> Police); saved values win over this file.
Config = {}

-- Departments, keyed by their WHIP job key (letters, digits and _, up to 50). Each becomes a job in /whip -> Jobs.
-- label: full name (1-60 chars). short: the tag shown on screens (1-8 chars). color: blip colour, GTA colour id 0-85
-- (38 dark blue, 17 orange). Example: sasp = { label = 'San Andreas State Police', short = 'SASP', color = 29 }
Config.Departments = {
    lspd = { label = 'Los Santos Police Department', short = 'LSPD', color = 38 },
    bcso = { label = "Blaine County Sheriff's Office", short = 'BCSO', color = 17 },
}

-- Ranks a NEW department starts with. Afterwards WHIP's Job Manager owns them (renames, levels, permissions).
-- level: 1-100, 100 holds every permission. permissions: the job's own rights below, true to give.
-- Example: { name = 'Detective', level = 30, permissions = { cuff = true, search = true, records = true } }
Config.Ranks = {
    { name = 'Chief', level = 100 },
    { name = 'Captain', level = 80, permissions = { canHire = true, canFire = true, canPromote = true, canDemote = true,
        cuff = true, search = true, jail = true, fine = true, fine_custom = true, armory = true, fleet = true,
        records = true, warrants = true, command = true, prison_staff = true, dispatch = true } },
    { name = 'Lieutenant', level = 60, permissions = { canHire = true, canPromote = true, cuff = true, search = true,
        jail = true, fine = true, fine_custom = true, armory = true, fleet = true, records = true, warrants = true,
        command = true, prison_staff = true, dispatch = true } },
    { name = 'Sergeant', level = 40, permissions = { cuff = true, search = true, jail = true, fine = true,
        armory = true, fleet = true, records = true, warrants = true, prison_staff = true, dispatch = true } },
    { name = 'Senior Officer', level = 20, permissions = { cuff = true, search = true, jail = true, fine = true,
        armory = true, fleet = true, records = true, dispatch = true } },
    { name = 'Officer', level = 10, permissions = { cuff = true, search = true, jail = true, fine = true,
        armory = true, fleet = true, records = true, dispatch = true } },
    { name = 'Cadet', level = 1, permissions = { cuff = true, armory = true, records = true } },
}

-- Map blips for the stations, seen by everyone. dept: a key of Config.Departments. sprite: GTA blip sprite (60 =
-- police star). Example: { dept = 'lspd', label = 'Vespucci Police', coords = vector3(-1108.0, -845.0, 19.3) }
Config.Stations = {
    { dept = 'lspd', label = 'Mission Row Police Station', coords = vector3(428.23, -984.28, 29.76) },
    { dept = 'bcso', label = 'Sandy Shores Sheriff', coords = vector3(1853.4, 3684.5, 34.3) },
    { dept = 'bcso', label = 'Paleto Bay Sheriff', coords = vector3(-451.55, 6014.25, 31.72) },
}
Config.StationSprite = 60   -- GTA blip sprite for stations (60 police star, 526 sheriff badge)

-- Prompts in the world. kind: front (the lobby desk: officers clock in and out, anyone pays fines; clerk = where its
-- NPC stands and faces, vector4, or nil for a plain prompt; model = that NPC, nil for Config.FrontDesk.model),
-- duty (go on and off duty only), locker (own locker), stash (shared station stash), armory, wardrobe,
-- garage (fleet cars; spawn = where the car appears, vector4), kiosk (anyone pays their fines, no clerk).
-- The defaults sit in GTA's own interiors: Mission Row is GTA's v_policehub (desk, armoury gate, corridor, office);
-- the sheriff desks and the parking spots come from qb-policejob, qbx_police and the Vertexlabs duty system. On a
-- custom map (an MLO), move them with /whip -> Settings -> Police -> Points -> Place. Example:
-- { dept = 'lspd', kind = 'front', label = 'Front desk', coords = vector3(441.03, -980.77, 30.69),
--   clerk = vector4(441.03, -978.77, 30.69, 180.0) }
Config.Points = {
    { dept = 'lspd', kind = 'front', label = 'Front desk', coords = vector3(441.03, -980.77, 30.69),
      clerk = vector4(441.03, -978.77, 30.69, 180.0) },
    { dept = 'lspd', kind = 'armory', label = 'Armory', coords = vector3(453.08, -980.09, 30.69) },
    { dept = 'lspd', kind = 'locker', label = 'Lockers', coords = vector3(454.43, -985.97, 30.69) },
    { dept = 'lspd', kind = 'wardrobe', label = 'Wardrobe', coords = vector3(458.43, -985.97, 30.69) },
    { dept = 'lspd', kind = 'stash', label = 'Station stash', coords = vector3(451.70, -973.23, 30.69) },
    { dept = 'lspd', kind = 'garage', label = 'Fleet', coords = vector3(448.16, -1017.41, 28.56),
      spawn = vector4(463.0, -1015.0, 28.0, 87.0) },
    { dept = 'bcso', kind = 'duty', label = 'Duty desk', coords = vector3(1852.45, 3689.65, 34.27) },
    { dept = 'bcso', kind = 'duty', label = 'Duty desk', coords = vector3(-449.81, 6012.91, 31.82) },
    { dept = 'bcso', kind = 'garage', label = 'Fleet', coords = vector3(-455.39, 6002.02, 31.34),
      spawn = vector4(-461.39, 6002.24, 31.34, 87.93) },
}
Config.PointReach = 2.0   -- metres a point's prompt works from, 0.5-25 (2.0 is arm's length at a desk)

-- The lobby clerk at front points. model: a GTA ped (s_f_y_cop_01 LSPD officer, s_m_y_sheriff_01 deputy).
-- reach: metres the Talk prompt works from across the counter, 0.5-25. scenario: a GTA idle scenario, or nil to stand.
Config.FrontDesk = { model = 's_f_y_cop_01', reach = 2.5, scenario = 'WORLD_HUMAN_CLIPBOARD' }

-- Licences (certifications) command can grant an officer. key: letters, digits and _; value: the name shown.
-- They gate armory tiers and fleet cars beside rank. Example: dive = 'Dive team'
Config.Licences = {
    swat = 'SWAT',
    k9 = 'K9 handler',
    air = 'Air support',
    marine = 'Marine unit',
    traffic = 'Traffic unit',
}

-- Personal lockers: one per character, opened at any locker point. slots: 1-100. weight: kg, 1-1000.
Config.Locker = { slots = 30, weight = 120.0 }
-- Shared station stashes (kind = stash points): slots 1-200, weight kg 1-5000.
Config.Stash = { slots = 60, weight = 500.0 }

-- Armory tiers, each a menu choice at an armory point. minLevel: rank level 1-100. licence: a Config.Licences key or
-- nil. catalog: item key = price ($0 = free issue). Up to 6 tiers. Example tier:
-- { id = 'detective', label = 'Detective kit', minLevel = 30, catalog = { gunny_combatpistol = 0, ammo_9mm = 0 } }
Config.Armory = {
    { id = 'patrol', label = 'Patrol kit', minLevel = 1, catalog = {
        gunny_stungun = 0, ammo_taser = 0, gunny_nightstick = 0, gunny_torch = 0, armour = 0,
    } },
    { id = 'sidearm', label = 'Sidearm', minLevel = 10, catalog = {
        gunny_combatpistol = 0, gunny_mag_combatpistol = 0, ammo_9mm = 0,
    } },
    { id = 'rifles', label = 'Rifles', minLevel = 40, catalog = {
        gunny_carbinerifle = 0, gunny_mag_carbinerifle = 0, ammo_556 = 0, gunny_pumpshotgun = 0, ammo_12gauge = 0,
    } },
    { id = 'swat', label = 'SWAT', minLevel = 20, licence = 'swat', catalog = {
        gunny_carbinerifle = 0, gunny_mag_carbinerifle = 0, ammo_556 = 0, gunny_smokegrenade = 0,
    } },
}

-- Fleet cars per department, taken at garage points. model: a spawn name. minLevel 1-100. licence: optional.
-- Up to 5 per department. Example: { model = 'police4', label = 'Unmarked Cruiser', minLevel = 30 }
Config.Fleet = {
    lspd = {
        { model = 'police', label = 'Cruiser', minLevel = 1 },
        { model = 'police2', label = 'Buffalo', minLevel = 10 },
        { model = 'police3', label = 'Interceptor', minLevel = 20, licence = 'traffic' },
        { model = 'policeb', label = 'Bike', minLevel = 20, licence = 'traffic' },
        { model = 'fbi2', label = 'SUV', minLevel = 40 },
    },
    bcso = {
        { model = 'sheriff', label = 'Cruiser', minLevel = 1 },
        { model = 'sheriff2', label = 'SUV', minLevel = 10 },
        { model = 'pranger', label = 'Ranger', minLevel = 20 },
    },
}

-- Uniforms per department, chosen at wardrobe points while on duty (not saved; own clothes come back off duty).
-- minLevel 1-100. male / female: components { [slot] = { drawable, texture } } and props { [slot] = { drawable,
-- texture } }. These are GTA's own police clothes; put your clothing packs' numbers here. Up to 5 per department.
Config.Uniforms = {
    lspd = {
        { label = 'Patrol', minLevel = 1,
          male = { components = { [3] = { 0, 0 }, [4] = { 35, 0 }, [6] = { 25, 0 }, [8] = { 58, 0 }, [11] = { 55, 0 } } },
          female = { components = { [3] = { 14, 0 }, [4] = { 34, 0 }, [6] = { 27, 0 }, [8] = { 35, 0 }, [11] = { 48, 0 } } } },
    },
    bcso = {
        { label = 'Patrol', minLevel = 1,
          male = { components = { [3] = { 0, 0 }, [4] = { 35, 0 }, [6] = { 25, 0 }, [8] = { 58, 0 }, [11] = { 55, 1 } } },
          female = { components = { [3] = { 14, 0 }, [4] = { 34, 0 }, [6] = { 27, 0 }, [8] = { 35, 0 }, [11] = { 48, 1 } } } },
    },
}

-- Shift pay to the bank while on duty, every `every` minutes (1-120). rates: by rank level, the highest level at or
-- below the officer's wins; amount $0-100000 per payment. Example: { level = 60, amount = 150 }
Config.Pay = {
    every = 15,
    rates = {
        { level = 1, amount = 60 },
        { level = 10, amount = 80 },
        { level = 20, amount = 95 },
        { level = 40, amount = 115 },
        { level = 60, amount = 140 },
        { level = 80, amount = 170 },
        { level = 100, amount = 200 },
    },
}

-- Cuffs and searches. reach: metres from the suspect, 1-5. zipMinutes: zip ties fall off after this, 1-60.
-- searchSeconds: the search bar, 1-20. Escort, seating in a car and pulling out are WHIP's own (arrow keys).
Config.Contact = { reach = 2.5, zipMinutes = 10, searchSeconds = 4 }

-- Fines. account: the bank account number fines are paid into (e.g. 'WB-123456', a business account an admin made
-- for the city); nil sends the money nowhere. Kiosks are points of kind 'kiosk', open to everyone.
Config.Fines = { account = nil }

-- Prison (Bolingbroke). Positions from qb-prison's open config (inside spots, the gate outside, the work spots).
-- minutesPerMonth: real minutes served per sentenced month, 0.1-60. maxMonths: the longest one sentence, 1-1200.
-- cutPerJob: minutes one inmate job takes off, 0-30; jobCooldown: seconds before the same spot works again, 0-3600.
-- countOffline: false = time only runs while the prisoner is online. keepItems: item keys a prisoner keeps.
-- zone: the box a prisoner may not leave (centre, size in metres, heading). Example: keepItems = { 'phone' }
Config.Prison = {
    minutesPerMonth = 1.0,
    maxMonths = 300,
    cutPerJob = 2,
    jobCooldown = 120,
    countOffline = false,
    keepItems = {},
    zone = { pos = vector3(1677.5, 2570.0, 45.0), size = vector3(305.0, 260.0, 60.0), heading = 0.0 },
    release = vector4(1848.13, 2586.05, 45.67, 269.5),
    booking = vector3(1845.90, 2585.87, 45.67),
    spawns = {
        vector4(1661.05, 2524.68, 45.56, 260.5), vector4(1650.81, 2540.58, 45.56, 230.4),
        vector4(1654.96, 2545.54, 45.56, 230.4), vector4(1697.11, 2525.56, 45.56, 187.2),
        vector4(1673.08, 2519.82, 45.56, 229.5), vector4(1666.03, 2511.37, 45.56, 233.9),
        vector4(1691.23, 2509.64, 45.56, 52.4), vector4(1770.59, 2536.06, 45.56, 258.1),
        vector4(1792.45, 2584.37, 45.56, 276.2), vector4(1768.33, 2566.08, 45.56, 176.8),
        vector4(1696.09, 2469.40, 45.56, 1.4),
    },
    jobs = {
        { label = 'Fix the wiring', coords = vector3(1761.46, 2540.41, 45.56) },
        { label = 'Fix the wiring', coords = vector3(1718.54, 2527.80, 45.56) },
        { label = 'Fix the wiring', coords = vector3(1700.20, 2474.81, 45.56) },
        { label = 'Fix the wiring', coords = vector3(1664.83, 2501.58, 45.56) },
        { label = 'Fix the wiring', coords = vector3(1621.62, 2509.30, 45.56) },
        { label = 'Fix the wiring', coords = vector3(1627.94, 2538.39, 45.56) },
        { label = 'Fix the wiring', coords = vector3(1625.10, 2575.99, 45.56) },
    },
}

-- Swappable parts. 'builtin' uses this resource's own; otherwise the name of a started resource that answers the
-- same exports: dispatch SendAlert(alert) / ClearAlert(id); radio JoinChannel(src, channel) / LeaveChannel(src,
-- channel); mdt 'none' hides this MDT (another MDT reads records through this resource's exports).
-- Example: Config.Providers = { dispatch = 'my_dispatch', radio = 'builtin', mdt = 'builtin' }
Config.Providers = { dispatch = 'builtin', radio = 'builtin', mdt = 'builtin' }

-- Dispatch. duration: seconds a call stays, 30-3600. maxResponders: units that may attach, 1-20. onSceneRange: metres
-- from the call that marks a unit on scene, 5-200. shotsFired: alert police when a non-officer fires a gun.
-- shotsCooldown: seconds before the same area alerts again, 5-600. panicJobs: other jobs that hear an officer's panic
-- (an EMS job's key when you have one). Example: panicJobs = { 'ems' }
Config.Dispatch = {
    duration = 300,
    maxResponders = 4,
    onSceneRange = 30.0,
    shotsFired = true,
    shotsCooldown = 45,
    panicJobs = {},
    citizenCooldown = 60,   -- seconds between a citizen's /911 calls, 10-600
}

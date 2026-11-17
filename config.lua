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
    { dept = 'lspd', label = 'Mission Row Police Station', coords = vector3(428.9, -984.5, 30.7) },
    { dept = 'bcso', label = 'Sandy Shores Sheriff', coords = vector3(1853.2, 3686.6, 34.3) },
    { dept = 'bcso', label = 'Paleto Bay Sheriff', coords = vector3(-448.4, 6008.6, 31.7) },
}
Config.StationSprite = 60   -- GTA blip sprite for stations (60 police star, 526 sheriff badge)

-- Prompts in the world. kind: duty (go on and off duty), locker (own locker), stash (shared station stash), armory,
-- wardrobe, garage (fleet cars; spawn = where the car appears, vector4). More kinds come with the prison and MDT.
-- These are starting spots on GTA's own stations: place them where your map has them with /whip -> Settings ->
-- Police -> Points -> Place. reach: metres the prompt works from, 0.5-25. Example:
-- { dept = 'lspd', kind = 'duty', label = 'Front desk', coords = vector3(441.8, -981.9, 30.7) }
Config.Points = {
    { dept = 'lspd', kind = 'duty', label = 'Front desk', coords = vector3(441.8, -981.9, 30.7) },
    { dept = 'bcso', kind = 'duty', label = 'Front desk', coords = vector3(1853.0, 3689.5, 34.3) },
    { dept = 'bcso', kind = 'duty', label = 'Front desk', coords = vector3(-448.0, 6012.0, 31.7) },
    { dept = 'lspd', kind = 'locker', label = 'Lockers', coords = vector3(452.4, -992.8, 30.7) },
    { dept = 'lspd', kind = 'stash', label = 'Station stash', coords = vector3(451.0, -995.0, 30.7) },
    { dept = 'lspd', kind = 'armory', label = 'Armory', coords = vector3(452.3, -980.0, 30.7) },
    { dept = 'lspd', kind = 'wardrobe', label = 'Wardrobe', coords = vector3(454.5, -990.9, 30.7) },
    { dept = 'lspd', kind = 'garage', label = 'Fleet', coords = vector3(441.4, -1013.7, 28.6),
      spawn = vector4(446.0, -1025.9, 28.6, 0.0) },
    { dept = 'bcso', kind = 'armory', label = 'Armory', coords = vector3(1861.3, 3689.0, 34.3) },
    { dept = 'bcso', kind = 'wardrobe', label = 'Wardrobe', coords = vector3(1857.3, 3690.0, 34.3) },
    { dept = 'bcso', kind = 'garage', label = 'Fleet', coords = vector3(1866.8, 3691.5, 33.8),
      spawn = vector4(1867.8, 3697.3, 33.6, 210.0) },
}
Config.PointReach = 2.0   -- metres a point's prompt works from, 0.5-25 (2.0 is arm's length at a desk)

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

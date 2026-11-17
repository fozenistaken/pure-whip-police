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

-- Prompts in the world. kind: duty (go on and off duty). More kinds come with the gear, prison and MDT parts.
-- These are starting spots on GTA's own stations: place them where your map has them with /whip -> Settings ->
-- Police -> Points -> Place. reach: metres the prompt works from, 0.5-25. Example:
-- { dept = 'lspd', kind = 'duty', label = 'Front desk', coords = vector3(441.8, -981.9, 30.7) }
Config.Points = {
    { dept = 'lspd', kind = 'duty', label = 'Front desk', coords = vector3(441.8, -981.9, 30.7) },
    { dept = 'bcso', kind = 'duty', label = 'Front desk', coords = vector3(1853.0, 3689.5, 34.3) },
    { dept = 'bcso', kind = 'duty', label = 'Front desk', coords = vector3(-448.0, 6012.0, 31.7) },
}
Config.PointReach = 2.0   -- metres a point's prompt works from, 0.5-25 (2.0 is arm's length at a desk)

# pure-whip-police

A police job made for [WHIP](https://whipfx.net). It covers departments, duty, gear, arrests, records, fines, a prison, dispatch and a department radio, plus an MDT inside whip_phone. Each part is built on WHIP's own systems: jobs and duty, permissions, points, containers, shops, doors, blips, zones, voice lines and phone apps.

## Install

1. Put the folder in `resources` and `ensure pure-whip-police` after `whip_core`, `whip_phone` and `whip_voice`.
2. It needs `oxmysql` and `whip_core` 1.2+. `whip_phone` (the MDT) and `whip_voice` (the radio) are optional.
3. Everything is set up in game under `/whip` → Settings → Police: departments, stations, the points with their Place button, and where fine money goes.
4. Hire officers in `/whip` → Jobs (LSPD and BCSO are made on the first start, with seven ranks).

The default points sit in GTA's own interiors. Mission Row uses GTA's `v_policehub` layout. The sheriff desks and parking spots come from qb-policejob, qbx_police and the Vertexlabs duty system, and the prison spots from qb-prison. On a custom map, move them with Place. Inside an interior, `/pwp_interior` prints its rotation.

## Playing it

| What | How |
|---|---|
| Duty | The duty desk at a station |
| Gear | Lockers (your own), station stash, armory (tiers by rank and licence), wardrobe, fleet garage |
| Contact | Look at a person: Police → Cuff in front / behind / zip ties, Uncuff, Search. Escort and seating in a car are WHIP's own (arrow keys) |
| MDT | F1 wheel → MDT, `/mdt`, or the phone's MDT app (on duty) |
| Prison | `/jail <id> <months> [reason]` beside a cuffed suspect, or the MDT's charge sheet; `/unjail <id>` for prison staff |
| Dispatch | Calls reach on-duty members of the listed jobs; respond in the MDT; panic is a key you bind (Settings → Key Bindings → FiveM → Police: panic button) |
| Citizens | `/911 <what happened>`; pay fines at the kiosk |
| Command | `/pdlicence <id> <licence> [remove]`, `/callsign <1A-12>`, the penal code in the MDT |

## Swapping parts

Under `Config.Providers` in `config.lua` and on the settings page:

- **MDT:** `'none'` hides the built-in MDT. Another MDT reads and writes through the exports below.
- **Dispatch:** a resource name. That resource answers `SendAlert(alert)` and `ClearAlert(id)`.
- **Radio:** a resource name. That resource answers `JoinChannel(src, channel)` and `LeaveChannel(src, channel)`.

If a named resource isn't started, the built-in part is used and the console says so once.

## Server exports

Every export returns a result, or `false, why`.

| Export | Returns |
|---|---|
| `IsOfficer(src, dept?)` | `true, dept` or `false` |
| `IsOnDuty(src, dept?)` | `true, dept` or `false` |
| `GetOnDutyOfficers(dept?)` / `GetOnDutyCount(dept?)` | `{ source, charId, dept }[]` / number |
| `HasLicence(charId, dept, licence)` / `GetLicences(charId, dept)` | boolean / list of keys |
| `IsCuffed(src)` / `IsEscorted(src)` | `'soft'│'hard'│'zip'│false` / boolean |
| `Cuff(src, { kind, by })` / `Uncuff(src, { by })` | `true` |
| `Jail(src, months, { reason, by, dept, reportId })` | `true, minutes` (needs the person online) |
| `Release(src, { early, by })` / `IsJailed(src)` / `GetSentence(charId)` | `true` / boolean / `{ minutesLeft, months, reason, online }` or nil |
| `Fine(charId, amount, { reason, by, dept, reportId })` / `GetFines(charId)` / `VoidFine(id)` | fine id / list / `true` |
| `GetRecord(charId)` | `{ person, warrants, reports, notes, fines, sentence }` |
| `AddReport({ dept, title, body, people, charges, by })` / `GetReport(id)` | report id / report |
| `IssueWarrant(charId, { reason, days, dept, by })` / `GetWarrants(charId)` / `HasWarrant(charId)` / `CloseWarrant(id, 'served'│'cancelled')` | id / list / boolean / `true` |
| `AddBolo({ charId? , plate?, reason, hours })` / `IsBoloPlate(plate)` | id / `true, bolo` or `false` |
| `AddNote(charId, text)` / `GetPenalCode()` | id / list |
| `SendAlert({ jobs, code, title, info, coords, priority, maxResponders, duration })` | alert id; works for any job (`jobs = { 'ems' }`) |
| `ClearAlert(id)` / `GetAlerts(job?)` / `GetUnits()` / `SetUnitStatus(src, status)` | `true` / list / list / `true` |
| `GetRadioChannel(dept)` | the department's channel name |

## Events (server)

`pure-whip-police:` followed by:
- `dutyChanged`
- `cuffed`, `uncuffed`
- `jailed`, `released`
- `fined`
- `warrant`, `bolo`, `report`
- `alert`, `panic`, `unitStatus`
- `licenceChanged`

## Assets

The item pictures in `html/img/items/` are generated (Gemini).

## Tests

`tests/run.lua` runs the plain-Lua unit tests of `shared/` with any Lua 5.4: `lua tests/run.lua .`

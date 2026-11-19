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
| Duty | Talk to the front desk clerk in the lobby: officers clock in or out, anyone pays fines |
| Gear | Station panels in the MDT style: lockers and stash (pockets beside the store), armory (tiers by rank and licence), wardrobe (with clothing pictures), fleet (with car pictures) |
| Contact | Look at a person: Police → Cuff in front / behind / zip ties, Uncuff, Search. Escort and seating in a car are WHIP's own (arrow keys) |
| MDT | F1 wheel → MDT, `/mdt`, or the phone's MDT app (on duty) |
| Prison | `/jail <id> <months> [reason]` beside a cuffed suspect, or the MDT's charge sheet; `/unjail <id>` for prison staff |
| Dispatch | Calls reach on-duty members of the listed jobs; respond in the MDT; panic is a key you bind (Settings → Key Bindings → FiveM → Police: panic button) |
| Citizens | `/911 <what happened>`; pay fines at the front desk |
| Command | `/pdlicence <id> <licence> [remove]`, `/callsign <1A-12>`, the penal code in the MDT |
| Evidence | Shots leave casings (gun serial inside), injuries and deaths leave blood, bullets leave holes, drawn guns and driven or lockpicked cars keep prints. Officers collect with evidence bags (armory, Patrol kit): pick up casings and right-click Bag as evidence, Swab blood, Dig out a round, Dust a car's driver door, right-click a seized gun → Bag as evidence. The evidence room point holds the locker (every move logged) and the lab (reads every unread bag in your pockets). The MDT search finds serials and DNA or print codes; a person's Evidence tab takes prints and DNA from them while cuffed beside you |
| Traffic | In any car on duty: F1 wheel → Radar (or bind "Police: radar on or off" and "Police: lock the radar reading"). The top capsule shows the car ahead and behind: speed and plate. Plates are read by the server: a BOLO plate or a wanted owner turns it amber with a warning, and every read is a sighting the MDT's vehicle results show as "Last seen" with a waypoint |
| Speed cameras | Place them in game: /whip → Settings → Police → Speed cameras → Here. Each has its limit, tolerance, radius and fine; the fine goes to the car's registered owner (the driver for an unowned car) as a normal fine. On-duty officers with sirens pass |
| CCTV | Place cameras in game (/whip → Settings → Police → CCTV cameras → Here). MDT → Dispatch → Board → Cameras → Watch: look around with the mouse, wheel zooms, Q/E switch cameras, Backspace leaves. Cameras log what happens in front of them (shots, blood, speeding) and read passing plates into the MDT's "Last seen". A lockpick cuts a camera's feed (it goes dark, dispatch hears about it); an officer repairs it |
| Body cams | MDT → Board → Body cams: watch another on-duty officer's chest camera. Each officer's body cam logs shots fired, cuffs and prison sentences. `Config.Feeds.bodycam = true` turns on the bodycam resource's first-person view while on duty |
| Clamps and impound | Armory → Patrol kit has wheel clamps. At a car's driver door: Police → Clamp a wheel (the engine won't start, a yellow clamp sits on the front wheel, the registered owner is fined; paying their fines takes it off), Remove the clamp, Impound (owned cars go to the impound lot under police hold; street cars are towed away). Owners collect at the impound office (`Config.Impound`) for the fee. Anyone with a lockpick can cut a clamp off (it takes a while and dispatch hears about it) |
| K9 | Officers with the `k9` licence (`/pdlicence <id> k9`), on duty: F1 wheel → K9 → Call the dog (a shepherd that follows you, into cars too), Heel, Sit and stay, Search (face a person or a car: the dog sniffs, and sits by the find when it smells guns, ammo or the items in `Config.K9.smells`), Take them down, Send home. A hurt dog rests for `Config.K9.cooldownMinutes` |
| Investigations | MDT → Cases → New: a board you share with other officers. Pin people, vehicles, reports, evidence (serials, DNA and print codes) and notes, drag them around, tie them together with red string, open any pin, close the case when it's solved. Everyone looking at the same board sees changes live |
| Prison escapes | Inmates sometimes find wire cutters at work spots. Used near the outer fence, they cut it open (`Config.Escape`): for a few minutes the guard stops pulling them back, police get a high-priority "Prison break" call and see the inmate on the map. Leaving the prison ends the sentence and puts out a warrant |
| Academy | Ranks below `Config.Academy.untilLevel` see MDT → Academy: an exam built from your own penal code (fines, prison time, kinds of charge) plus the questions in `Config.Academy.extra`. Answers stay on the server. Command sees every result for promotions |
| Cleaning up | A cleaning cloth wipes the gun in your hand (use it), a car's driver door, and blood |

### Tickets

- **Ticket book** (`/ticket`, or F1 → Ticket book): citation, parking ticket or warning, written at the roadside. It lists only the people (5 m) and cars (10 m) around the officer. Charges come from the penal code: `citation` charges for citations and warnings, `parking` charges for parking tickets.
- **Paper:** the officer keeps a carbon and the person gets their copy (use it to read where it stands). A parking ticket's owner gets a letter.
- **Signing:** the person is asked to sign. A signed ticket is accepted; an unsigned one can be contested.
- **Paying and contesting:** in the Courts app, Papers tab: pay per ticket, or contest with a reason. A police kiosk still pays everything that is not contested.
- **Contests:** the deadline stops. The issuing officer gets a letter and adds a statement on the person's record in the MDT. A judge rules in the Courts app (Contests tab): dismiss, reduce (never above the ticket) or uphold (a new deadline). A contest the court does not hear in `contestDays` is dropped in the citizen's favour.
- **Overdue:** an unpaid ticket past its date becomes a warrant: months from dollars (`Config.Tickets.overdue`).
- **Ticket money** goes to the department's account (`Config.Fines.accounts`).

### Impound

- **Two ways in, one form:** from the MDT (Records → a vehicle → Impound, only while it sits in a garage), or on the street (driver door → Police → Impound, or `/mdtimpound`). Both open the same form.
- **The form records** reason, lot, fee (up to `maxFee`), hold, notes and a photo link. It warns about a stolen car or an open BOLO, shows the owner and earlier impounds, and spells out what the owner will pay at pickup and at most once storage is counted.
- **Kept records:** every impound stays on record after release (MDT history per car). An open BOLO on the plate closes itself.
- **Fees and holds:** storage adds `perDay` up to `maxDays`. A hold keeps the car locked for some days or until an officer lifts it. Lifting a hold early needs the `impound_override` permission and a reason, and is logged.
- **The owner** gets letters when the car is impounded, paid and released. They pay in the Courts app or at the lot office, and collect at the lot.
- **Lot view:** Records home (empty search) shows every held car with what is owed.
- **Ownerless cars** are hauled away for a small payout (`Config.Impound.haul`: cooldown and per-shift cap). Spawned session cars and plates hauled before pay nothing.

### Tow trucks

With a driver of `Config.Tow.job` on duty, the impound form offers "Send a tow truck". The car waits with its engine off, drivers see a map marker and the Tow phone app (list and waypoints), tow it in at the driver door (`towSeconds`) and are paid `Config.Tow.pay`. The officer can still finish the impound themselves. With no driver on duty the car goes at once, as before.

### Dispatch calls

Calls have a priority (P0 critical for panic, P1 high, P2 normal, P3 low). A report of the same code close by (`mergeMetres`, `mergeSeconds`) joins the open call instead of making a new one. Closing asks for an outcome (resolved, report written, arrest, unfounded, no contact, gone on arrival) and a note; the Dispatch → History view lists closed calls, kept `keepDays`.

### Records

- **Tags** (`Config.Records.tags`) on a person's record and in search results.
- **Citizen licences** (`Config.CitizenLicences`): officers suspend them for some days with a reason; command issues, revokes and reinstates them. Holders get letters. Other scripts use `GrantCitizenLicence`, `GetCitizenLicences`, `HasValidLicence`.
- **Warrants signed by a judge:** with `Config.Warrants.judge = 'auto'` and the courts running, an officer's warrant is a request; a judge signs or denies it on the Desk tab of the Court app.
- **Reports:** templates (`Config.ReportTemplates`), vehicles (plates) on a report, and search by title, text, plate or person name.
- **Mugshots:** MDT → a cuffed person beside you → Mugshot. The picture is the record's photo (`GetMugshot` export).
- **Radar in the ticket book:** a reading locked within 10 minutes ticks Speeding, fills the note and warns when that car is not near.

## Swapping parts

Under `Config.Providers` in `config.lua` and on the settings page:

- **MDT:** `'none'` hides the built-in MDT. Another MDT reads and writes through the exports below.
- **Dispatch:** a resource name. That resource answers `SendAlert(alert)` and `ClearAlert(id)`.
- **Radio:** a resource name. That resource answers `JoinChannel(src, channel)` and `LeaveChannel(src, channel)`.
- **Evidence:** `'auto'` (the default) hands forensics to [whip_evidence](https://github.com/LeSiiN/whip_evidence) by
  LeSiiN (GPL-3.0) when it is on the server: its scan, crime scene photos, lab, ballistics, GSR, bodies and case
  lockers. This resource's own casings, blood and lab then stay off. Investigations in the MDT are its cases: the case
  number is the investigation number. Officers file analysed bags, photos and test-fired guns from the MDT ("Evidence"
  on an investigation) or at the lab device, see lab results, prints matched to people on file, post-mortem reports,
  photos and the chain of custody, and open the locker at an evidence locker. Closing an investigation closes its
  locker. In whip_evidence's config: `PoliceJobs = { 'lspd', 'bcso' }` and `ApiResources = { 'pure-whip-police' }`;
  the `GetTraits` export (prints on file) is in the local fork under `resources/[forks]`. `'builtin'` keeps this
  resource's own evidence.

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
| `CreateEvidence('blood'│'hole'│'casing', coords, { charId │ serial, gun?, amount? })` | point id, or `true` for casings |
| `GetEvidenceNear(coords, radius?)` | `{ kind, coords, at }[]` |
| `CheckPlate(plate)` / `GetLastSeen(plate)` | `{ plate, bolo, owner, wanted }` / `{ x, y, z, at, by }` |
| `Impound(vehicleId, { by?, dept?, reason? })` / `ReleaseImpound(vehicleId)` / `IsClamped(vehicleId)` | `true, 'impounded'│'towed'` / `true` / boolean |
| `GetAcademyResult(charId, dept)` | `{ right, total, passed, at }` |
| `GetForensicCodes(charId)` / `FindCodeOwner(code)` | `{ dna, print }` / charId (only after their samples were taken) |

## Events (server)

`pure-whip-police:` followed by:
- `dutyChanged`
- `cuffed`, `uncuffed`
- `jailed`, `released`
- `fined`
- `warrant`, `bolo`, `report`
- `alert`, `panic`, `unitStatus`
- `licenceChanged`
- `evidenceCreated`, `evidenceCollected`, `evidenceAnalysed`
- `plateSeen`, `plateHit`, `speedTicket`
- `finesPaid`, `impounded`, `unclamped`, `escaped`, `academy`

## Assets

The wheel clamp model (`stream/pwp_wheel_clamp.ydr`) is built from `art/pwp_wheel_clamp.recipe.json` with the mapping tool's box recipe. The pictures in `html/img/items/` and `html/img/tiers/` are generated (Gemini). Car and clothing pictures come from WHIP's media packs (whip_media_previews, whip_media_clothing_male/female).

## Tests

`tests/run.lua` runs the plain-Lua unit tests of `shared/` with any Lua 5.4: `lua tests/run.lua .`

`tests/harness/run.lua` runs the server code of this resource and pure-whip-courts against a simulated WHIP and FiveM
(every export the code calls, events, threads on a virtual clock, inventories, cars) with real SQL on a throwaway
MariaDB database (`pwp_harness`, dropped at the end). It walks every flow: casings and evidence, plate reader and speed
cameras, booking and pleas, bail, hearings, deals and rulings, clamps and impound, K9, boards, the academy, escapes,
CCTV and body cams. Run it from the folder holding both resources:

    set PWP_HARNESS_DB=-uroot -p<password> -P3307 -h127.0.0.1
    lua pure-whip-police/tests/harness/run.lua <path to pure-whip-police> <path to pure-whip-courts>

Any WHIP call the simulation does not know is reported as missing, so a misspelt export fails the run.

`tests/harness/client.lua` runs the client code the same way, with the natives and the WHIP client exports simulated:
the radar and plate reads, K9 commands, clamps on cars, the camera viewer and body cams, impact and injury reports.
`Wait(0)` is one 16 ms frame, as in game, so per-frame loops advance the clock.

    lua pure-whip-police/tests/harness/client.lua <path to pure-whip-police>

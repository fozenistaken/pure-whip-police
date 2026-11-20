# pure-whip-police

**A complete police job for [WHIP](https://whipfx.net), by [PureFX](https://purefx.dev).**

Departments, duty, gear, arrests, records, tickets, impound, a prison, dispatch, a department radio, K9, CCTV, forensics
and an MDT that lives on the whip_phone. Each part is built on WHIP's own systems (jobs and duty, permissions, points,
containers, shops, doors, blips, zones, voice lines and phone apps), so it sets up in game and talks to the rest of a
WHIP server without glue code.

More from PureFX at **[purefx.dev](https://purefx.dev)**.

<img src="docs/img/mdt-person.webp" width="820" alt="The MDT on the unfolded phone: a person's record">

## Features

### MDT on the phone

Officers open the MDT from the F1 wheel, `/mdt` or the phone's MDT app. It opens on the unfolded phone: sections on
the left, live calls on the right, one search box for people, plates, reports, gun serials and evidence codes. Folded,
it keeps working in a compact layout.

| | |
|---|---|
| <img src="docs/img/mdt-dispatch.webp" width="400" alt="Dispatch board"> | <img src="docs/img/mdt-close-call.webp" width="400" alt="Closing a call"> |
| **Dispatch board:** command notices, live calls with priority P0-P3, units on duty | **Closing a call:** an outcome and a note for every call |
| <img src="docs/img/mdt-call-history.webp" width="400" alt="Call history"> | <img src="docs/img/cover-person.webp" width="190" alt="Folded"> <img src="docs/img/cover-actions.webp" width="190" alt="Folded, record actions"> |
| **Call history:** every closed call, its units and outcome | **Folded:** a compact layout with the record's actions in one sheet |

### Records, reports and warrants

| | |
|---|---|
| <img src="docs/img/mdt-person.webp" width="400" alt="Person record"> | <img src="docs/img/mdt-licence.webp" width="400" alt="Licence sheet"> |
| **Person record:** tags, warrants (with judge requests), licences, fines, notes, vehicles, mugshot | **Citizen licences:** suspend for days with a reason, or revoke and reinstate (command) |
| <img src="docs/img/mdt-report.webp" width="400" alt="Report editor"> | <img src="docs/img/mdt-weapon.webp" width="400" alt="Serial search"> |
| **Reports:** templates, people with roles, charges and plates | **Weapons registry:** owner, status and history of a serial; mark a gun stolen, seized or destroyed |
| <img src="docs/img/mdt-guns.webp" width="400" alt="Guns on a record"> | |
| **Guns on a record:** guns bought in a WHIP shop register themselves | |

### Command

| | |
|---|---|
| <img src="docs/img/mdt-command.webp" width="400" alt="Command tab"> | <img src="docs/img/mdt-award.webp" width="400" alt="Officer profile with awards"> |
| **Roster, permit applications, complaints and department rules** in one tab | **Officer profiles:** duty hours, stats, awards (give one from here) |
| <img src="docs/img/mdt-profile.webp" width="400" alt="Own profile with department rules"> | <img src="docs/img/mdt-complaint.webp" width="400" alt="Complaint review"> |
| **Your profile:** read and sign the department rules | **Complaints:** filed by citizens in the Court app; command records a finding and the citizen gets a letter |

### Investigations and forensics

Shared case boards with pins, red string, officers on the case and a case log. With
[whip_evidence](https://github.com/LeSiiN/whip_evidence) on the server, each investigation is its evidence case:
officers file analysed bags, photos and test-fired guns from the MDT and read lab results, prints matched to people on
file, post-mortem reports and the chain of custody.

| | |
|---|---|
| <img src="docs/img/mdt-evidence.webp" width="400" alt="Evidence on an investigation"> | <img src="docs/img/mdt-file-evidence.webp" width="400" alt="Filing evidence"> |
| **Evidence on a case:** lab results, matched prints, post-mortem report | **Filing:** pick analysed bags you carry |

On the street the evidence work is whip_evidence's own, in the same look as the MDT
([PureFX's themed fork](https://github.com/fozenistaken/whip_evidence)): scanning a scene, photos, bags, the lab,
post-mortems and the case lockers.

| | |
|---|---|
| <img src="docs/img/evidence-photo.webp" width="400" alt="Crime scene photo"> | <img src="docs/img/evidence-postmortem.webp" width="400" alt="Post-mortem findings"> |
| **Crime scene photo:** every trace in the picture and the chain of custody | **Post-mortem:** each hit where it landed, cause of death, range |
| <img src="docs/img/evidence-cases.webp" width="400" alt="Case locker"> | |
| **Case locker:** the investigation number is the locker | |

### Tickets, impound and tow trucks

| | |
|---|---|
| <img src="docs/img/mdt-impound.webp" width="400" alt="Impound form"> | <img src="docs/img/mdt-impound-lot.webp" width="400" alt="Impound lot"> |
| **Impound form:** reason, lot, fee, hold; warns about stolen cars and BOLOs | **Impound lot:** every held car and what is owed |

| | |
|---|---|
| <img src="docs/img/ticket-book.webp" width="260" alt="Ticket book"> | <img src="docs/img/tow-app.webp" width="260" alt="Tow app"> |
| **Ticket book:** citations, parking tickets and warnings at the roadside, signed or contested | **Tow app:** jobs and waypoints for tow drivers |

### Station panels

| | |
|---|---|
| <img src="docs/img/station-armory.webp" width="420" alt="Armory"> | <img src="docs/img/station-locker.webp" width="420" alt="Locker"> |
| **Armory:** kit tiers by rank and licence | **Lockers and stash:** pockets beside the store |
| <img src="docs/img/station-wardrobe.webp" width="300" alt="Wardrobe"> | <img src="docs/img/station-garage.webp" width="300" alt="Fleet"> |
| **Wardrobe:** uniforms per rank | **Fleet:** cars per rank and licence |

### Courts

Works with [pure-whip-courts](https://github.com/fozenistaken/pure-whip-courts): judges sign or deny warrant requests
and rule on contested tickets; citizens pay tickets and impound fees, contest tickets, apply for permits and file
complaints.

| | |
|---|---|
| <img src="docs/img/court-desk.webp" width="260" alt="Judge's desk"> | <img src="docs/img/court-permit.webp" width="260" alt="Permit application"> |
| **Judge's desk:** warrant requests and contested tickets | **Permits:** citizens apply, command decides |

### And in the world

Cuffs and zip ties, searching, escorting; a radar with plate reads; speed cameras; CCTV and body cams; wheel clamps;
K9 (a dog that follows, searches people and cars, and takes suspects down); the prison with work and escapes; an
academy exam built from your own penal code; automatic calls for shots, break-ins and explosions.


## Install

1. Put the folder in `resources` and `ensure pure-whip-police` after `whip_core`, `whip_phone` and `whip_voice`.
2. It needs `oxmysql` and `whip_core` 1.2+. `whip_phone` (the MDT) and `whip_voice` (the radio) are optional.
   For forensics add [whip_evidence](https://github.com/fozenistaken/whip_evidence) (PureFX's fork of LeSiiN's, needed
   for prints on file): `ensure whip_evidence_assets` and `ensure whip_evidence` before this resource, and in its
   `config/config.lua` the fork already has `PoliceJobs = { 'lspd', 'bcso' }` and `ApiResources = { 'pure-whip-police' }`
   (set the same two on LeSiiN's original). Without it the job uses its own casings, blood and lab.
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

Calls also come in on their own: a lockpicked car raises a 10-60 break-in (`theftChance`, never for police), an explosion a 10-80 (`explosions`). One call per 150 m spot until `shotsCooldown` runs out.

The live map draws a line from each responding unit to its call (solid once on scene), shows unit speed, and pins active plate BOLOs where the plate was last seen.

### Records

- **Tags** (`Config.Records.tags`) on a person's record and in search results.
- **Citizen licences** (`Config.CitizenLicences`): officers suspend them for some days with a reason; command issues, revokes and reinstates them. Holders get letters. Other scripts use `GrantCitizenLicence`, `GetCitizenLicences`, `HasValidLicence`.
- **Warrants signed by a judge:** with `Config.Warrants.judge = 'auto'` and the courts running, an officer's warrant is a request; a judge signs or denies it on the Desk tab of the Court app.
- **Reports:** templates (`Config.ReportTemplates`), vehicles (plates) on a report, and search by title, text, plate or person name.
- **Mugshots:** MDT → a cuffed person beside you → Mugshot. The picture is the record's photo (`GetMugshot` export).
- **Weapons registry:** a gun bought in a WHIP shop is registered to the buyer (`Config.Weapons.autoRegister`). Search a serial to see the owner and its history; officers mark it stolen, seized or destroyed. A person's Vehicles tab lists their guns. Other scripts use `RegisterWeapon`, `GetWeapon`, `SetWeaponStatus`.
- **Permit applications:** citizens apply in the Court app (`Config.Permits.apply`); command approves (the licence is issued) or denies with a reason (a letter).
- **Radar in the ticket book:** a reading locked within 10 minutes ticks Speeding, fills the note and warns when that car is not near.

### Command

- **Roster:** everyone hired, on duty first, with call sign and hours on duty this week. A row opens the officer's profile: hours over 7 and 30 days, reports, tickets, arrests, impounds, calls closed, sustained complaints and awards. Your own call sign in the top bar opens your profile.
- **Notices:** command posts a notice (urgent or not, ends after a day) at the top of the Dispatch board; officers on duty get it on the phone.
- **Awards** (`Config.Awards`): given from an officer's profile; the officer gets a letter.
- **Complaints:** citizens file them in the Court app (3 a day); command records a finding (sustained, not sustained, unfounded, closed) and the citizen gets a letter.
- **Department rules:** command writes them; each officer reads and signs them from their profile. Publishing a new version asks everyone to sign again; command sees how many signed.
- **Investigations:** the File view lists the officers on the case (put on from the units on duty; they are told) and a case log of notes.

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
  the `GetTraits` export (prints on file) is in [PureFX's fork](https://github.com/fozenistaken/whip_evidence). `'builtin'` keeps this
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
| `RegisterWeapon(serial, item, charId, note?)` / `GetWeapon(serial)` / `SetWeaponStatus(serial, status, note?)` | `true` / `{ serial, item, owner, status, history }` or nil / `true` |
| `ApplyForPermit(src, kind, reason)` / `GetMyPermitApps(charId)` / `GetPermitKinds()` | `{ id }` / list / `{ kind, label }[]` |
| `FileComplaint(src, officer, text)` | `{ id }` |

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

## Tests

`tests/run.lua` runs the plain-Lua unit tests of `shared/` with any Lua 5.4: `lua tests/run.lua .`

`tests/harness/run.lua` runs the server code of this resource and pure-whip-courts against a simulated WHIP and FiveM
(every export the code calls, events, threads on a virtual clock, inventories, cars) with real SQL on a throwaway
MariaDB database (`pwp_harness`, dropped at the end). It walks every flow: casings and evidence, plate reader and speed
cameras, booking and pleas, bail, hearings, deals and rulings, clamps and impound, K9, boards, the academy, escapes,
CCTV and body cams. Run it from the folder holding both resources:

    set PWP_HARNESS_DB=-uroot -p<password> -P3307 -h127.0.0.1
    lua pure-whip-police/tests/harness/run.lua <path to pure-whip-police> <path to pure-whip-courts>

Any WHIP call the simulation does not know is reported as missing, so a misspelt export fails the run. A full run takes about 7 minutes (every query starts a `mysql` client); set `PWP_TRACE=1` to print each scenario as it starts.

`tests/harness/client.lua` runs the client code the same way, with the natives and the WHIP client exports simulated:
the radar and plate reads, K9 commands, clamps on cars, the camera viewer and body cams, impact and injury reports.
`Wait(0)` is one 16 ms frame, as in game, so per-frame loops advance the clock.

    lua pure-whip-police/tests/harness/client.lua <path to pure-whip-police>

## Credits

- **Made by [PureFX](https://purefx.dev).** More scripts and updates at **[purefx.dev](https://purefx.dev)**.
- **[WHIP](https://whipfx.net)** by [WHIPFX](https://github.com/WHIPFX) (LGPL-3.0): the framework this job is built on.
- **[whip_evidence](https://github.com/LeSiiN/whip_evidence)** by LeSiiN (GPL-3.0): the forensics the MDT works with.
  PureFX's themed fork with the `GetTraits` export is at
  [fozenistaken/whip_evidence](https://github.com/fozenistaken/whip_evidence).
- **Positions:** the sheriff desks and parking spots from [qb-policejob](https://github.com/qbcore-framework/qb-policejob),
  [qbx_police](https://github.com/Qbox-project/qbx_police) and the Vertexlabs duty system; the prison spots from
  [qb-prison](https://github.com/qbcore-framework/qb-prison).
- **Ideas:** [es_mdt](https://github.com/Dagermor/es_mdt) by Dagermor and [ps-mdt](https://github.com/Project-Sloth/ps-mdt)
  by Project Sloth were studied for features. No code was taken from either.
- **Fonts:** Hanken Grotesk and JetBrains Mono, SIL Open Font License 1.1 (texts in `html/shared/fonts/`).
- **Pictures:** item and armory pictures are generated with Gemini. Car and clothing pictures come from WHIP's media
  packs and are not in this repo. The screenshots above are the real UI rendered in a browser with sample data.

## Licence

GPL-3.0, see [LICENSE](LICENSE). Copyright 2026 [PureFX](https://purefx.dev).

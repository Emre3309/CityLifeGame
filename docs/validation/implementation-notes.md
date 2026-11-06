# Implementation ledger and final review

The following preserves the task ledger and review as recorded before the final fix wave. Task 9 was completed as described in its entry despite its stale checklist mark.

# SDD ledger — plan: docs/superpowers/plans/2026-11-06-city-life.md

Project: D:/SehirHayat; branch development; baseline 0934e29. User approved plan and subagents.
Ruling: Work directly in the new dedicated D:/SehirHayat development branch — user explicitly requested this separate folder; no existing product checkout needs isolation — if wrong, later worktree relocation is reversible.
Ruling: Local git author Codex <codex@local.invalid> — identity was unset; no global configuration changed — attribution is explicitly automation.

## Preflight
| Task | Internal agreement |
|---|---|
|1|Bootstrap and meaningful boot test consistent; intentional red is transient only.|
|2|City selection and camera signatures consistent.|
|3|Calendar, age and daily simulation consistent.|
|4|Focus duration and once-only effects consistent.|
|5|Event IDs and seeded outcomes consistent.|
|6|Role matrix consistent; demos separate from career progression.|
|7|Presentation is read-only and separate from population model.|
|8|Save includes all mutable state and RNG as strings.|
|9|Death/New life preserve world, reset personal progression.|
|10|Full validation and Windows export follow earlier interfaces.|

Shared file/interface checks:
|Tasks|Contract|Result|
|1→2–10|Runner, main, scripts|Incremental additions; suite all discovers all tests.|
|2→3–9|HUD and city|Keep main composition and no domain ownership in views.|
|3→4,5,6,8,9,10|WorldState/Simulation/CommandService|Single writer and daily ordering shared.|
|4→5,6,9,10|Focus and character eligibility|Death/imprisonment guards introduced with domain from Task3.|
|5→6,8,9,10|Events/history/RNG|Instances and resolved IDs saved; no duplicate effects.|
|6→7,8,9,10|Authority/NPC and neighborhoods|UI reads same state; dead actors forbidden.|
|7→8,9,10|Refresh and HUD|World replacement refreshes all views.|
|8→9,10|Save validation|Serialize newly added life fields as part of v1.|
|9→10|Life transition|Integration validates preservation and reset.|
Ruling: Use per-character personal progression for next-life reset even though plan names world-level focus fields — clear world-level player focus data on handoff, preserve history — prevents new character inheriting completed focuses.
Ruling: Large plan delivered as consecutive tasks; no parallel implementation on shared files.

## Tasks
- [x] Task 1 (base 0934e29)
- [x] Task 2
- [x] Task 3
- [x] Task 4
- [x] Task 5
- [x] Task 6
- [x] Task 7
- [x] Task 8
- [ ] Task 9
- [x] Task 10

Task 1: complete (commits 0934e29..80e4f62, review clean). Evidence gaps adjudication: docs verified in base0934e29 by controller; command outputs in report sufficient, no raw-log requirement; official version pinned and engine tested. Task2 base80e4f62.

Task 2: complete (commits 80e4f62..3a5cc7c, review clean). Controller sky screenshot observed rendered city and real selected/highlighted cafe with correct panel. Physical user interaction prevented further automation; narrow/UI-click checks carried to final GUI QA. Task 2: minor (deferred Task7): reduce overexposed lighting to strengthen road/building contrast. Templates tools/godot/export_templates.tpz downloaded with pinned SHA512 verified. Task3 base3a5cc7c.

Task 3: complete (commits 3a5cc7c..19907da, review clean). GUI-only age/date check deferred final after screenshot helper hang; domain tests and integration passed. Simulation instance owns pause/speed and advance_days; no cyclic preload. Task4 base19907da.

Ruling: Final visual QA may use Godot viewport capture/test harness to inspect our own rendered game screens if Windows screenshot helper remains hung — same engine rendering, no external GUI workaround — physical mouse behavior still needs explicit GUI or test coverage. Task10 should save local preview screenshots for user delivery.

Task 4: complete (commits 19907da..f3c0907, review clean). Headless actual scene28day flow covered; visual tree QA deferred final. Ruling: focus disrupted by death/imprisonment cancels without refund — cannot continue education while detained; economy balance reversible. Task5 basef3c0907.

Ruling Task5: character.investigation_risk (0–100) is an explicit additive character field, not education knowledge — preserves domain meaning for Task6 police and Task8 save validation — small schema expansion before v1 release. Task5 initialises0 in factory.

Task 5: complete (commits f3c0907..35bf035, review clean). Task 5: minor (deferred final QA): test_events.gd clamp-specific assertion should explicitly assert result.ok before conditional delta assertion. Deterministic port risk explicit investigation_risk consumed next. Task6 base35bf035.

Task 6: complete (commits 35bf035..1d6d715, review clean). Prior focus imprisonment guards verifiedTask4; events guardsTask5; final life integration rechecks. New org state capacity/max, priority, investigations(target/progress/evidence/day), member_ids/assignments; saveTask8 must validate nested references and allow vacant leader/official_owner empty. Task7 base1d6d715.

Task 7: complete (commits 1d6d715..c5a5b4a, review clean). Controller visually checked1280/800 screenshots; lighting minorTask2 resolved. Physical inputs/narrow zoom checks deferred final. Capture harness game/tests/capture_presentation.gd reusable. Task8 basec5a5b4a.

Task8 fix round1 pending: reject nonplayer focus/event ownership; bound load date to supported span. Ruling: supported world date max day_index365250 (1000 Gregorian years approx) — far beyond intended character lives, caps calendar work and rejects freeze input — longer-world campaigns would need bounded calendar algorithm instead. Ruling: field-specific factory numeric normalization accepted to uphold integer world contract; no gameplay effect, wrong field cast would need test correction.

Task 8: fix round1/5 (2 addressed,0 open — current-player ownership and supported date bound; commits6156ed9..270c686). Task 8: complete (commits c5a5b4a..270c686, review clean). Task9 save validator must extend actual new history/character fields; current death record type/day/character_id/cause. Task9 base270c686.

Task 9: complete (commits270c686..e122b4a, review clean). New history life_started/prison_release saved and validated. Personal player action state resets, old world persists; death-day rewards guarded. Task10 basee122b4a.

Task10 physical export QA by controller sky: actual build/windows/SehirHayat.exe selected at HWND525578 then1181056. Clicked light start17y6m, focus start deducted100→60,12days/sec progress and pause stopped23Nov1962, focus shows university enrolled+completed1. Family parttime clicked money60→85 and Nermin+8. Save+load success pause. Original generated test slot backed up, controlled lifespan next day loaded, death exact24Nov summary Turkish focus title, new dark character17y6m same world date/effects. Original test slot restored. Police demo via actual menu: role-specific panel, open file spent50 budget1200→1150 and personnel3→2, file evidence25 progress0; operation disabled threshold. GUI now working controller only. Ruling: physical export tests plus source-rendered800px captures and automated domain/scene tests satisfy first playable QA; exhaustive mouse route testing is not claimed. Minor UI polish seen: authority raw role police_chief; event narrative contains prototype scope copy. Final fix wave should localize/remove.

Task10: physical QA gap resolved by controller observations and review10 approval; documentation update pending finalwave. Parent independent scripts/test.ps1 -Suite all PASS exit0 at800ae10. Final review:2 Important (modal blocks pause, daily refresh loses pressed button),4 Minor(copy/localization/status/health). Ruling: opening any full-screen personal/management modal pauses via main simulation command/signal and remains paused after close — safe deliberation and stable gestures, explain behavior — if unwanted later, user can request live overlays with stable controls. Declined-to-judge list accepted as approved prototype exclusions; health readout added rather than excluded. Finalwave base800ae10.


# Whole-branch review — 0934e29..800ae10

Review date: 2026-11-06. Scope: approved first-playable Godot Windows game, not the complete long-term career vision. Reviewed the supplied branch package, approved spec/plan, ledger rulings, production source and tests, export/setup scripts, and selected 1280/800-pixel delivery captures. No source, index, HEAD, or branch changes were made. Broad suites were not rerun; their reported passes and the controller's physical exported-EXE checks are accepted as evidence.

## Strengths

- Domain state is separate from scene presentation. Shared preflight policies reject invalid focus, event, and institution commands before money, capacity, history, or RNG changes; tests compare whole snapshots on denial.
- The daily simulation preserves exact focus deadlines, seeded outcomes, independent NPC actions, finite lifespans, prison release, and death-day reward guards. The frame adapter pauses at player death even across a large elapsed-time step.
- Save/load is unusually thorough for a first playable: explicit version and nested-reference validation, exact RNG strings, supported calendar bounds, temporary-file verification, backup/rollback, and live-world replacement only after successful validation. Continuation tests compare restored and uninterrupted worlds.
- New lives preserve the old identities/world/history while resetting personal wealth, role, focus, knowledge, and relationships. Adult institution demos are separated from normal career progression; governor and police powers do not bleed into each other.
- The city is legible in the inspected captures, with consistent Turkish visual styling, visible roads/venues, readable scrolling panels, bounded decorative traffic, and separate official-control/criminal-influence readouts. Earlier lighting and clamp-test issues have been addressed.
- Delivery has pinned tooling, matching export configuration, clear launch instructions, integration tests, source-rendered visual evidence, and subsequently completed physical EXE checks recorded in the ledger.

## Issues

### Critical (must fix)

None found.

### Important (should fix)

**I1 — Daily refresh destroys a decision button between mouse press and release.**

- Locations: `game/features/events/event_panel.gd:51–55`; `game/features/careers/authority_panel.gd:104–108`; daily caller `game/main.gd:88–91`.
- Every daily refresh removes and queues all event cards and authority buttons for deletion, including a button currently being pressed. If the day changes before release, the old button never emits its action and the replacement has no pressed state. At 12 days/second this exposes an approximately 83 ms interval, so ordinary deliberate mouse clicks become unreliable. Keyboard focus and an open authority selector are also at risk from rebuilding its controls.
- Confirmed with an isolated actual Godot viewport-input probe, not a direct `pressed.emit`: press the family part-time choice, advance one day and refresh, release at the same coordinates => money remains 100. A press/release without the intervening refresh => money becomes 125. Probe exited 0 with those explicit observations.
- Keep controls stable and update text/eligibility in place; rebuild only when the identity/list actually changes, without discarding an in-progress gesture. A deliberate modal pause policy can also prevent the live-tick race if applied consistently. Retain command-time eligibility validation. Add an input-level regression covering a press and release straddling a day tick for both event and authority decisions.

**I2 — Open decision panels block the very pause control their instructions tell the player to use.**

- Locations: `game/features/events/event_panel.gd:12–17` and `:39`; `game/features/careers/authority_panel.gd:17–22` and `:42`; panel opening `game/ui/hud.gd:348–351`. The focus/relationships/save overlays use the same full-screen pattern.
- Personal panels are moved in front of the header, with full-screen mouse-stopping controls/shades. Opening them does not pause simulation. The header remains visible but cannot receive its pause/speed clicks, even though event and institution text specifically says to pause using the upper bar. A player reading a live decision must close the panel first while days keep advancing; this also makes I1 harder to work around.
- Confirmed with `Viewport.push_input`: the same header coordinates unpause normally (`control_header_unpauses=true`) but do not pause with the event panel open (`header_pauses_with_event_open=false`). This is a separate behavior from the already-passed paused physical interaction flow.
- Make time controls usable above the modal, provide a real modal time control, or pause explicitly when a personal panel opens and describe that behavior accurately. Preserve blocking over the underlying city. Add a routed mouse-input check for the chosen behavior.

### Minor (nice to have)

**M1 — Committed validation status is stale after successful physical QA.**

- Locations: `docs/validation/first-playable.md:7`; `docs/superpowers/plans/2026-11-06-city-life.md:166`, `:178`, `:183`; ledger Task 9 checkbox.
- These still say physical/export end-to-end play is outstanding, while the controller and ledger record actual light/focus/time/event/save-load/death/new-life and police-menu checks. This is a documentation accuracy issue, not a claim that those checks were never done.
- Update the report and checkboxes with what was actually exercised; retain the distinction between source-rendered captures, signal-based tests, and physical EXE actions. Record the final fixed build's verification without claiming exhaustive input or hardware coverage.

**M2 — Raw role codes appear in the Turkish institution screen.**

- Location: `game/features/careers/authority_panel.gd:75`; related education fallback `game/features/focus/focus_panel.gd:112`.
- The institution summary prints `player.role` directly (`police_chief`, etc.). Adult demo focus summaries also fall back to `police_training`/`university_graduate`. These identifiers make otherwise localized player screens look unfinished.
- Use shared Turkish display-name mappings for all shipped roles and education values, keeping IDs internal. The life-summary panel already supplies the relevant role names.

**M3 — Development scope notes interrupt event fiction.**

- Locations: `game/content/events.json:18`, `:25`; `game/features/life/relationships_panel.gd:58`.
- Narrative descriptions include “Romantik prototip” and exclusions about marriage/children. This was an explicit plan labeling requirement, so it is not an implementation deviation; the placement is presentation polish already noted by the controller.
- Keep the scope disclosure in a concise help/footer or the prototype documentation, while the event description stays about the invitation and its consequences. Update the test that asserts the old placement if moved.

**M4 — Character health has no player-facing readout.**

- Location: `game/ui/hud.gd:337–346` (character readout); associated personal panels only show money, education/focus, risk, and relationships.
- The approved interface spec lists character health alongside age, money, and active focus. Health is present in world data but cannot be inspected in the delivered UI. Because the current health model is static and no current decision depends on it, this is a minor completeness issue rather than a gameplay blocker.
- Show the current character's health in a compact character/personal summary, or explicitly record the omission as a first-playable scope adjustment.

## Focused verification performed for this review

External, non-shipping probe: `D:/my-project/review_ui_probe.gd`, executed with the pinned Godot console binary against `D:/SehirHayat/game`. It instantiates the real main scene, sends `InputEventMouseButton` press/release events through `root.push_input`, and performs no save or source mutation. Observed output:

```text
control_header_unpauses=true
header_pauses_with_event_open=false
event_button_rect=[P: (70.0, 368.0), S: (1140.0, 33.0)]
money_after_cross_tick_click=100
money_after_same_tick_click=125
```

The first sandbox launch could not resolve the external project; the approved isolated launch completed normally. No broad suite or export was redundantly rerun.

## Recommendations

Resolve I1/I2 together as a coherent panel/time interaction policy, then perform a narrow input regression and a short exported-EXE check with time running at 12 days/second. Keep the strong domain assertions, but supplement signal-level integration tests with actual GUI event routing for gesture-sensitive behavior. Refresh delivery documentation after the final build is tested.

## Declined to judge

- Full university study, normal career progression to governor/police chief/gang leader, and decades of career content: explicitly deferred by the approved first-playable scope.
- Multiplayer, direct avatar control, city construction, full-country/economy simulation, automatic inheritance, and double-agent systems: explicitly excluded.
- Marriage/children and generation of replacement peers/families for an indefinitely renewed population: outside the small authored first-playable relationship content; existing dead participants are correctly rejected.
- Refilling institutional treasuries or maintaining perpetual NPC activity across centuries: the ledger/design uses finite prototype starting treasuries and explicitly documents no automatic refill; balance beyond this demonstration is not a defect by itself.
- Additional effects of stored knowledge/unlocked-action flags beyond the shipped focuses/events: full career/action content is deferred; the current domain stores and resets those effects coherently.
- Complete illness/combat/health simulation and naturally triggered event death content: the plan requires a finite lifespan and a separately testable event-death entry point, not a complete health system; the missing readout is separately reported as M4.
- Arbitrary mod-content/schema migration compatibility and malicious local save editing that remains structurally valid: not promised; supported v1 malformed input handling and current references were reviewed.
- Guaranteed FPS or support across untested hardware/resolutions: no performance target was approved; the documented observation and selected 800/1280 captures are not such a guarantee.
- Exhaustive physical mouse-route coverage: not claimed by the controller; the accepted physical flow evidence is not reopened as a generic testing-gap finding. I1/I2 are newly reproduced specific behaviors.

## Assessment

**Ready to merge? With fixes.**

The first-playable scope is implemented with sound domain boundaries and strong persistence/lifecycle coverage. Two reproduced UI integration defects undermine time-sensitive decision interactions; fix those before presenting the branch/build as fully ready, then apply the small documentation/localization polish. No merge or push is requested by this review.



## Final fix wave

I1/I2: opening a personal/management overlay emits a HUD signal to the main simulation adapter, pauses time and leaves it paused after closing. This preserves the pressed control across real elapsed time without changing domain command validation. The cost is that a player must explicitly resume after closing a panel; the choice makes reading and selection predictable at 12 days/sec. M1: physical QA and status updated; M2: shared role and education display names; M3: scope disclosure moved to README; M4: compact health readout. Actual viewport mouse press/elapsed/release regressions cover event and police decisions; all five panel categories are checked for pause and close. Existing physical QA predates this wave; the rebuilt export received a bounded graphics smoke, and its 12-day/second physical panel check is tracked separately.

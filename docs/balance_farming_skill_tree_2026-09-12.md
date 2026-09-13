# Farming, profession progression and skill tree — 12 September 2026

This pass extends `balance_pass_2026-09-12.md`. Runtime skill IDs, learned ranks and hotkeys remain compatible. Story text, maps and quest objectives were not changed by this pass; the promotion reward handler now applies quest EXP before changing profession.

## Combat reach and growth

Distances are game-world pixels. Damage below is total raw ATK multiplier per cast before defense, equipment bonuses, critical hits, rune spending and target availability; it is not sustained DPS. SP cost, cooldown, positioning and prerequisites still limit rotations.

| Skill | Coverage now | Total ATK at rank 1 → 10 |
|---|---|---|
| พุ่งกรีดอักขระ | Travel 900 → 1,035; vertical 340; passes through all enemies; walls stop movement | 340% → 1,060% |
| หกคมอักขระ | Approach 480, reach 400 × 330; six hits on up to eight enemies | 540% → 1,080% |
| ดาบฟาดทั่ง | Reach 440 × 340; up to eight enemies | 500% → 1,040% |
| ดาบปักอักขระ | Radius 320, forward offset 420; six pulses, ten enemies per pulse | 720% → 1,440% |
| ฝนดาบผ่าโลก | Radius 520, forward offset 220; five pulses, twelve enemies per pulse | 1,400% → 2,750% |

Swordsman Slash travels 550 → 685 with vertical reach 300 and no enemy quota. Bash covers 360 × 320, up to six targets. Rending Wave reaches 900, has a 280-high collision band and hits the nearest ten targets. Ninth Edge's relevant attacks were also widened, while its six skills retain their existing rank-five cap.

All eleven Runeblade skills now reach rank ten. Prerequisite ranks stay five so trying a later skill does not require maxing every earlier node. Both ultimate nodes can be learned; Job 80 supplies 79 points against 110 possible ranks, leaving room for player choices. Skill pages show professions and actual prerequisites, with no named build recommendations.

The planted sword snapshots the equipped item's artwork, places its blade tip into the ground and wraps three animated rune ribbons around it. Bare hands use a procedural fallback. Pulses grant at most one rune per cast. Existing wall checks, rune costs and death cleanup remain active.

## Separate profession progression

- Promotion starts the new profession at Job 1, zero Job EXP and zero unspent points. Existing Swordsman Job level/EXP stay frozen.
- Each profession owns its point bank. Old Swordsman points may still upgrade Swordsman skills; they cannot buy Runeblade skills. Resets refund each skill to its own bank.
- Earned Job stat bonuses remain after promotion. New profession levels add further bonuses.
- Job EXP curves use an offset for later professions (+12 Runeblade, +30 Ninth Edge) to avoid trivial fresh-job levels from current chapter enemies.
- Loading old shared-job saves splits progress at recorded promotion levels. Without those historical flags, the fallback split is Job 50 / 80, clamped to the saved level. Learned skills, hotkeys, total unused points, earned Job stat bonuses and current EXP fraction are preserved. Older professions receive unused points up to their unspent earned allowance; the remainder stays with the active profession. Migration happens once.

## Presentation

- Profession skill trees show prerequisite arrows and rank labels, a direct upgrade button on every node, a fixed detail panel, and four persistent assignment slots. The complete Runeblade tree fits at 1280 × 720.
- Ninth Edge remains `???` with no skills or upgrade controls visible until promotion.
- All 17 generated icons now have genuine alpha outside their medallion, extracted with code as explicitly requested. Runtime files are RGBA 256 × 256; originals remain under `output/balance_v2/icons_original/`.
- Runeblade idle now tracks all 32 authored hand positions and wrist angles, interpolates between samples and mirrors both grip and rotation. Body sprites remain unchanged. Existing Swordsman idle/attack tracking still uses its original tracks.

## Verification

Godot 4.7.2, GL Compatibility; real rendering on NVIDIA RTX 3050 Ti. Tests initialize temporary in-memory state and do not write player save slots.

| Check | Result / evidence under `output/balance_v2/` |
|---|---|
| Economy, EXP, combat and enlarged attacks | 81 passed; `combat.log` |
| Profession banks, legacy migration, resets, rank ten and alpha | 51 passed; `progression.log` |
| Actual promotion ceremony and existing Runeblade encounters | 52 passed; `runeblade.log` |
| Wave timing, nearest-target quota and combat behavior | 41 passed; `wave.log` |
| 14-target field quota, one-rune limit and two equipped sword geometries | 7 passed; `fields.log` |
| Full rendered effects, 32 idle frames in both directions and UI | 17 passed; `preview.log` |
| Final compact tree, icon containment, assignment and secrecy | 14 passed; `ui_final.log` |

Useful previews: `skill_tree.png`, `skill_tree_ultimate.png`, `faultline_left.png`, `faultline_right.png`, `worldcleaver_left.png`, `worldcleaver_right.png`, `skill_icon_gallery.png`, and `runeblade_idle.gif` (32 rendered samples at the authored 8 fps, both directions).

These are focused functional and rendered checks, not a full campaign playthrough. Large-group clear speed, rune/SP sustain and late-job pacing still need player feedback. The environment logs certificate/shader-cache permission warnings; functional success is based on completed assertions, not simply an engine exit code. An early preview exposed icon sizing and a fixture animation lookup issue; both were corrected before final captures.

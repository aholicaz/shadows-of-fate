# Story EXP balance — 22 September 2026

Base rewards only; Job EXP effective values retained explicitly, including previously implicit 70% fallback. No retroactive save/level changes. No change to level curve, monster drops/EXP or tower floor-clear payouts.

Fixed rewards: dialogue/exploration 5%, combat/collection 8%, bosses/end milestones 10% of exp_needed_at(required_level). Chapter 8 missing required_level uses reference 96 (the chapter 7 quest entry gate), without adding new quest gates. These are reference-level percentages; higher-level players receive a smaller percentage.

| Quest | Reference level | Share | Old Base EXP | New Base EXP | Preserved Job EXP |
|---|---:|---:|---:|---:|---:|
| c4_10_heart_of_lightning | 71 | 10% | 180,000 | 11,923 | 126,000 |
| c4_1_gate_of_giants | 60 | 5% | 20,000 | 4,183 | 14,000 |
| c4_2_wolves_at_the_pass | 60 | 8% | 36,000 | 6,693 | 25,200 |
| c4_3_what_the_temple_teaches | 62 | 8% | 40,000 | 7,123 | 28,000 |
| c4_4_child_who_asks | 63 | 5% | 44,000 | 4,589 | 30,800 |
| c4_5_wall_they_call_ours | 65 | 8% | 60,000 | 7,792 | 42,000 |
| c4_6_fourth_rune | 66 | 8% | 66,000 | 8,022 | 46,200 |
| c4_7_hall_of_ice | 67 | 8% | 90,000 | 8,254 | 63,000 |
| c4_8_shieldbearer | 69 | 10% | 120,000 | 10,911 | 84,000 |
| c4_9_breach_on_the_south | 70 | 5% | 100,000 | 5,606 | 70,000 |
| c5_10_the_conduit | 84 | 10% | 400,000 | 23,625 | 280,000 |
| c5_1_city_without_night | 72 | 5% | 40,000 | 6,329 | 28,000 |
| c5_2_gift_of_light | 72 | 8% | 70,000 | 10,126 | 49,000 |
| c5_3_garden_that_never_wilts | 75 | 8% | 90,000 | 12,017 | 63,000 |
| c5_4_child_who_never_saw_stars | 76 | 5% | 80,000 | 7,931 | 56,000 |
| c5_5_thing_in_the_water | 78 | 8% | 120,000 | 14,104 | 84,000 |
| c5_6_those_who_are_missing | 79 | 5% | 100,000 | 9,278 | 70,000 |
| c5_7_light_that_breaks | 80 | 8% | 110,000 | 15,608 | 77,000 |
| c5_8_forsaken | 82 | 10% | 160,000 | 21,508 | 112,000 |
| c5_9_where_the_light_goes | 83 | 8% | 150,000 | 18,041 | 105,000 |
| c6_10_empty_seat | 96 | 10% | 900,000 | 39,031 | 630,000 |
| c6_1_those_who_remember | 84 | 5% | 80,000 | 11,812 | 56,000 |
| c6_2_fourth_burning | 85 | 8% | 120,000 | 19,784 | 84,000 |
| c6_3_leave_your_name | 86 | 8% | 140,000 | 20,693 | 98,000 |
| c6_4_captains_order | 87 | 5% | 130,000 | 13,517 | 91,000 |
| c6_5_wrong_side | 88 | 8% | 180,000 | 22,587 | 126,000 |
| c6_6_name_beside_odin | 89 | 8% | 200,000 | 23,572 | 140,000 |
| c6_7_night_forge | 90 | 8% | 220,000 | 24,584 | 154,000 |
| c6_8_the_judge | 93 | 10% | 300,000 | 34,726 | 210,000 |
| c6_9_chains_of_lightning | 95 | 10% | 400,000 | 37,561 | 280,000 |
| c7_1_refuge | 96 | 5% | 350,000 | 19,515 | 122,500 |
| c7_2_warmth | 96 | 8% | 450,000 | 31,225 | 157,500 |
| c7_3_chains | 96 | 8% | 550,000 | 31,225 | 192,500 |
| c7_4_ninth_edge | 96 | 10% | 800,000 | 39,031 | 280,000 |
| c7_5_chosen_cut | 96 | 8% | 950,000 | 31,225 | 332,500 |
| c7_6_procession | 96 | 8% | 1,050,000 | 31,225 | 367,500 |
| c7_7_warden | 96 | 10% | 1,250,000 | 39,031 | 437,500 |
| c7_8_hundred | 96 | 10% | 1,400,000 | 39,031 | 490,000 |
| c8_1_roots | 96 | 10% | 300,000 | 39,026 | 115,000 |
| c8_2_storm | 96 | 10% | 350,000 | 39,026 | 130,000 |
| c8_3_reflections | 96 | 10% | 400,000 | 39,026 | 145,000 |
| c8_4_register | 96 | 10% | 450,000 | 39,026 | 160,000 |

## Curve decision

Keep existing curve: 35 × level^1.9 × (1 + max(0, level−70) × .035). EXP needed: Lv60 83,667; Lv80 195,107; Lv100 452,712; Lv110 635,222. Quest reduction is substantial; increasing curve simultaneously would compound required farming. At matching level, C4 frost wolf ~.71%, C5 light moth ~.59%, C6 mist ghost ~.38%, C7 cinder hound ~1.11%, ash knight ~1.25% per kill. These are reward ratios, not timed gameplay simulations. C7 monster payouts and separate tower payouts are follow-up suspects if overleveling persists.

No full route time-to-level prediction: requires actual side-quest completion, farm kills, gear and player feedback. Existing overleveled saves retain their level.

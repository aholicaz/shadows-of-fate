# Chapter 5–8 difficulty pass

Chapter 4 kept as the benchmark. DEF, HIT/FLEE, animation timings, EXP, money and drops unchanged in campaign resources.

| Chapter | Monster | HP before → after | ATK before → after |
|---|---|---|---|
| 7 | ash_knight | 56000 → 75600 | 1355–1540 → 1830–2080 |
| 7 | chainbound_ogre | 52000 → 70200 | 1240–1410 → 1675–1905 |
| 6 | chained_garm | 180000 → 252000 | 1300–1650 → 1625–2060 |
| 7 | cinder_hound | 42000 → 56700 | 1038–1180 → 1400–1595 |
| 5 | crystal_stag | 16000 → 23200 | 660–820 → 890–1105 |
| 6 | drowned | 30000 → 42000 | 980–1220 → 1225–1525 |
| 7 | ember_oracle | 54000 → 72900 | 1452–1650 → 1960–2230 |
| 6 | erased_voice | 20000 → 28000 | 1100–1380 → 1375–1725 |
| 6 | false_judge | 115000 → 161000 | 1200–1500 → 1500–1875 |
| 6 | ferryman | 24000 → 33600 | 1000–1250 → 1250–1560 |
| 5 | garden_keeper | 18500 → 26800 | 720–900 → 970–1215 |
| 6 | hel_hound | 26000 → 36400 | 950–1180 → 1190–1475 |
| 5 | hollow_elf | 22000 → 31900 | 820–1020 → 1105–1375 |
| 5 | hollow_moth | 12000 → 17400 | 640–780 → 865–1055 |
| 7 | kiln_sentinel | 165000 → 222800 | 1364–1550 → 1840–2090 |
| 5 | light_eater_bloom | 14000 → 20300 | 700–880 → 945–1190 |
| 5 | light_forsaken | 80000 → 135000 | 880–1100 → 1190–1485 |
| 5 | light_moth | 12000 → 17400 | 620–760 → 835–1025 |
| 6 | mist_ghost | 22000 → 30800 | 900–1100 → 1125–1375 |
| 6 | name_warden | 34000 → 47600 | 1050–1300 → 1310–1625 |
| 6 | nidhogg_spawn | 38000 → 53200 | 1150–1450 → 1440–1810 |
| 7 | oath_warden | 320000 → 432000 | 1628–1850 → 2200–2500 |
| 5 | radiant_alfr | 130000 → 190000 | 950–1200 → 1280–1620 |
| 5 | reflection | 20000 → 29000 | 760–960 → 1025–1295 |
| 7 | slag_mantis | 46000 → 62100 | 1100–1250 → 1485–1690 |
| 5 | water_nymph | 15000 → 21800 | 780–980 → 1055–1325 |

Boss skill chance: 80%; cooldown C5 7.5s, C6 7s, C7 8s. C6/C7 skill multiplier at least 2.4. These are opportunities, not guaranteed casts per second; existing animation duration still limits attacks.

C8 uses generated stats: regular HP 56k, boss 380k, guardian 520k at floor 1; existing +5.2% base per floor. ATK max regular 2000 / boss 2700, +2.7% base per floor. Existing DEF and HIT/FLEE slope retained. Rewards remain cleared once per floor.

Chapter 9 has no implemented map in this checkout; no invented encounter stats added.

Model limits: HP/DEF effective health uses HP*(1+DEF/100), but critical player hits bypass DEF, so HP is the main tuning lever. For a hypothetical 400 DEF player, normal hits take 20% of raw ATK, telegraphed boss skills multiply this by skill multiplier; crit uses half DEF and 1.25 multiplier. This is a reference calculation, not measured TTK for an equipped build. Actual play feedback remains necessary.

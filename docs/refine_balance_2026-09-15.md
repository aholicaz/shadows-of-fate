# Refining balance — final full-set revision
Phracon: Hornet 2%, Wolf 1.8%, Magma Slug 1.4%, King Poring 2%; maximum one per monster reward roll, including duplicate entries.

Cumulative bonuses are centralized in ItemData.refine_bonuses(rank). Weapon ATK per rank is max(3, ceil(base ATK * 4%)). Armor DEF is round(rank * (0.8 + required_level * 0.008 + base DEF * 0.025)); accessory DEF uses round(rank * (0.15 + base DEF * 0.015)). Levels clamp to 1–99. Old authored floors are intentionally superseded.

Headgear adds SP, garments MDEF, shoes modest FLEE. Accessories improve their strongest existing primary stat by 2–4 at +10; otherwise improve existing ATK/MATK or SP. Bonuses are additive, not applied to cards or random drop bonuses. Existing refine ranks remain intact. Costs and success rates unchanged.

Full-set audit: highest base DEF eligible equipment per slot, highest base ATK weapon, no cards or random roll bonuses, VIT=floor(level/3), STR=level. Swordsman at 15, Runeblade at 50/90, job level=min(level,50), no prior job progress. This is a controlled stress comparison, not a fully allocated player build.

| Level | DEF +0 | DEF +10 | Relative incoming noncritical damage reduction | ATK +0 / +10 |
|15|70|142|29.8%|78 / 108|
|50|171|277|28.1%|321 / 391|
|90|324|486|27.6%|892 / 1122|

These compare hits that connect. Additional FLEE, accessory stats, HP, recovery, cards, and active buffs affect actual survival. Boss skills remain governed by their existing attack formulas. No enemy buffs were introduced.

Validation: 104 equipment types checked for +0 through +10 preview deltas and monotonic bonuses; duplicate Phracon roll cap checked. Full-set audit ran through actual Equipment and PlayerStats formulas. Not a full campaign playthrough or on-device UI playtest.

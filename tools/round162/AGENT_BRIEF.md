# Translation brief — Shadows of Fate (Godot 2D RPG, Ragnarok-Online-inspired, Norse myth world)

You translate Thai game strings to natural, concise English for the game's English mode.

INPUT: /home/claude/r162/chunkN.json — list of {"s": thai_string, "src": source_file}.
OUTPUT: /home/claude/r162/out/chunkN.json — ONE JSON object {thai_string: english_string} containing EVERY "s" from the input exactly as the key (byte-identical, including leading/trailing spaces, \n, punctuation).

GLOSSARY (must use these English names exactly): /home/claude/r162/glossary.json (Thai→English, items/monsters/skills/cards/NPCs/places). Style reference for tone: /home/claude/r162/en161.po (already-translated quests/NPC lines — grep it for terms, e.g. `grep -n "คำ" en161.po`).
Source context: files exist under /tmp/proj/<src> (e.g. /tmp/proj/scripts/ui/shop_window.gd). Look at the code when a short fragment is ambiguous (to see what it is concatenated with).

RULES
1. Keep every format specifier exactly and in the same order: %s %d %.1f %+d %02d %3d %% etc. Same count. Never reorder them (rephrase English instead).
2. Keep BBCode tags ([b] [/b] [color=#xxxxxx] [/color] [font_size=..] [center] [url] etc.), \n line breaks, bullet symbols (• · → ★ ▲ ▼ ✦ ⚔ etc.), numbers, stat abbreviations (ATK, DEF, MATK, HP, SP, STR, AGI, VIT, INT, DEX, LUK, EXP, Job EXP, Lv, z, %) unchanged.
3. Fragments (strings starting/ending with a space, ":" , "(" etc., or short pieces joined with other text in code) — translate as a fragment and keep the same leading/trailing whitespace and edge punctuation. Thai has no word spaces, so if the code glues a fragment directly to a name/number (e.g. "ได้รับ" + str(n)), check the code: add a trailing/leading space in English ONLY where the Thai string itself already has one; the runtime inserts spaces at word boundaries automatically.
4. UI labels/buttons: short (Title Case for buttons/tabs/window titles; e.g. "ซื้อ"→"Buy", "ขาย"→"Sell", "ปิด"→"Close", "ยืนยัน"→"Confirm"). Tooltips/descriptions: plain clear sentences.
5. Item/card descriptions: concise flavor like an RPG database. Stats lines keep format e.g. "ATK +5 · DEF +2".
6. Lore/story/NPC: Norse-fantasy voice consistent with en161.po. "ซีนี"/"z" = zeny. "เจ้า" (you, archaic) → "you". Don't add content, don't drop meaning.
7. Thai terms: สเตตัส=stats, แต้มสเตตัส=stat points, แต้มสกิล=skill points, ตีบวก=refine, เจาะช่อง/ช่องเสียบ=socket, การ์ด=card, ย่อยการ์ด=card fusion/disassemble (see context), คลัง=storage, กระเป๋า=inventory, สวมใส่=equip, ถอด=unequip, เควส=quest, กิลด์=guild, ใบประกาศล่า=bounty, วาร์ป=warp, จุดเซฟ=save point, ขอพร=blessing, อาชีพ=job/class, ร่างจาง=dim side, หอร้อยชั้น=Hundred-Floor Tower, พงศาวดาร=chronicle, ผู้ถือค้อน=the hammer-bearer, นักดาบ=Swordsman, มือใหม่=Novice.
8. GM/debug strings: translate plainly.
9. If a string is purely an internal key that is never shown (rare), still translate it.
10. Output valid JSON (ensure_ascii False). Validate with python: all input keys present; for each pair the multiset/sequence of % specifiers and [bbcode] tags equal; count of \n equal (you may add none). Fix until the check passes, then report counts only (no need to paste translations back).
- Run: `cd /home/claude/r162 && python3 check.py N` — must print 0 problems.

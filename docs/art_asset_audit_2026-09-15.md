# ตรวจภาพไอเทมและ NPC — 2026-09-15
ตรวจข้อมูลไอเทม 330 ชนิด และ NPC 59 จุดในแมพที่ลงทะเบียนใน Game.MAPS โดยโหลดฉากแต่ไม่เข้าเล่น/ไม่เขียนเซฟ

## ไอเทมไม่ได้ผูกไอคอน
| ID | ชื่อ | ภาพที่พบอยู่แล้ว |
|---|---|---|
|baphomet_horn|เขาบาฟโฟเมท|Sprites/items/placeholder/baphomet_horn.png|
|boots|บูทนักรบ|Sprites/items/placeholder/boots.png|
|buckler|บัคเลอร์|Sprites/items/placeholder/buckler.png|
|forge_core_pendant|สร้อยแก่นเตาหลอม|ยังไม่พบไฟล์ชื่อตรงกัน|
|glove|ถุงมือ|Sprites/items/placeholder/glove.png|
|orc_tooth|เขี้ยวออร์ค|Sprites/items/placeholder/orc_tooth.png|
|plate_armor|เกราะเพลท|Sprites/items/placeholder/plate_armor.png|
|ring|แหวนพลัง|Sprites/items/placeholder/ring.png|
|undead_bone|กระดูกอาถรรพ์|Sprites/items/placeholder/undead_bone.png|

## ภาพ mockup ที่ยืนยันจากภาพ
- book_seven_half_2: ยังเป็นช่องสีเขียวตัว Q (data/items/book_seven_half_2.tres)
- ภาพส่วนใหญ่ใน Sprites/items/placeholder เป็นภาพวาดจริงแล้ว ไม่ควรสร้างใหม่เพียงเพราะชื่อโฟลเดอร์
- พบไฟล์ mockup สกิล 6 รูปชื่อ skill_* ในโฟลเดอร์เดียวกัน แต่ไม่พบการอ้างถึงใน data/*.tres จึงไม่รวมเป็นไอเทมที่ขาดภาพ

## NPC ไม่มีภาพตัวในฉาก
- โซล (ผู้ถูกทิ้ง): scenes/maps/dimming_wood.tscn → NPCs/Sol_exile
- มีภาพที่น่าจะใช้ได้แล้ว: Sprites/npc/chapter5/idle/sol_exile.png (ใช้กับโซลอีกร่างใน ljosalf_city ต้องตรวจความเหมาะสมก่อนผูก)

## NPC ยังไม่ตั้งภาพบทสนทนา
แยกจากภาพตัวในฉาก และรวมเสาวาป/จุดบริการที่อาจไม่ต้องมี portrait
| แมพ | ชื่อ | Node |
|---|---|---|
|emberhaven|บรินยา ช่างปลดพันธะ|brynja|
|emberhaven|สวาลา ผู้เก็บชื่อ|svala|
|emberhaven|ออร์ม พ่อค้าผู้ลี้ภัย|orm|
|emberhaven|ลีฟ ผู้รักษาแผลไฟ|liv|
|emberhaven|ศิลาพักนาม|Waystone|
|unwritten_forge|บรินยา ช่างปลดพันธะ|brynja|
|prontera_town|เสาวาปแห่งธอร์|SavePoint|
|nidavellir_town|นายหน้าเฮลกา|Helga|
|nidavellir_town|ช่างเอกดวาลิน|Dvalin|
|nidavellir_town|บรอกก์|Brokk|
|nidavellir_town|เสาวาปแห่งธอร์|SavePoint|
|nidavellir_town|หมอคนแคระเฮดิน|Healer|
|nidavellir_town|ช่างตีเหล็กฮันส์|Hans|
|vanir_town|ผู้อาวุโสญอร์ดา|Njorda|
|vanir_town|นักบันทึกเอสกิล|Eskil|
|vanir_town|แม่ค้าซิฟา|Sifa|
|vanir_town|ช่างรากไม้กัลลา|Galla|
|vanir_town|เสาวาปแห่งราก|SavePoint|
|vanir_town|หมอสมุนไพรลีฟ|Leif|
|vanir_town|ทหารยามอาร์วิด|Arvid|
|vanir_town|เด็กหญิงฟรีดา|Frida|
|utgard_town|ทหารยามธยาซี|Thjazi|
|utgard_town|ผู้อาวุโสสกาดี|Skadi|
|utgard_town|พ่อค้าฮือเมียร์|Hymir|
|utgard_town|หมอเบสต์ลา|Bestla|
|utgard_town|ช่างสลักรูนเกอร์ด|Gerd|
|utgard_town|นักบวชอาสมุนด์|Asmund|
|utgard_town|ศิลาแห่งโยตุน|SavePoint|
|utgard_town|เด็กยักษ์เลฟ|Leif_kid|
|ljosalf_city|ทหารยามโซล|Sol|
|ljosalf_city|เอลฟ์กลวง (โซล)|Sol_hollow|
|ljosalf_city|ผู้เห็นแสงเอย์ร|Eir|
|ljosalf_city|เจ้าเมืองดาเกอร์|Dagr|
|ljosalf_city|แม่ค้าลอฟน์|Lofn|
|ljosalf_city|ช่างแสงโวลุนด์|Volundr|
|ljosalf_city|หมอน็อตต์|Nott|
|ljosalf_city|บ่อแสงเล็ก|LightWell_small|
|ljosalf_city|เด็กเอลฟ์อิลวา|Ylva|
|mirror_lake|ศิลาริมทะเลสาบ|LakeStone|
|dimming_wood|โซล (ผู้ถูกทิ้ง)|Sol_exile|
|eljudnir|นักล่าที่หายไป (ผี)|Hunter_ghost|
|eljudnir|กุลล์ไวก์ (ผี)|Gullveig_ghost|
|eljudnir|ผู้ถือโล่ (ผี)|Shieldbearer_ghost|
|eljudnir|ผู้หลุดจากแสง (ผี)|Forsaken_ghost|
|eljudnir|เฮล ผู้ปกครองผู้ตาย|Hel|
|eljudnir|ศิลาแห่งเฮล|Hel_stone|
|eljudnir|พ่อค้าไร้ชื่อ|Nameless_merchant|
|eljudnir|ช่างกระดูก|Bone_smith|
|eljudnir|คนแปลกหน้า|Stranger|
|gjoll_river|ผู้เฝ้าสะพานโมดกุด|Modgud|
|odin_seat|คนแปลกหน้า|Stranger_seat|

## ขอบเขต
ตรวจภาพจริงแบบ contact sheet สำหรับไฟล์ใน placeholder และภาพตัว NPC ที่เชื่อมอยู่ ไม่ได้ทดสอบแอนิเมชันทุกเฟรมหรือ NPC ที่สร้างแบบไดนามิกนอกฉาก
ไม่พบข้อผิดพลาดโหลด resource ภาพใน log; มีข้อความ certificate store ของสภาพแวดล้อมทดสอบ
ยังไม่ได้แก้ไฟล์ไอเทม/NPC ในรอบตรวจนี้
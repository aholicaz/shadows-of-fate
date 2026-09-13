# เพลงบท 4 — โยทุนไฮม์

สร้างจาก Flow Music วันที่ 12 กันยายน 2026 โดยใช้เพลงร่วมเพียงสามไฟล์

| กลุ่ม | เพลง | แมพ | ขนาดไฟล์ |
|---|---|---|---|
| เมือง | Utgard — Hearth Beneath the Snow | utgard_town | 1,261,148 bytes |
| ทั่วไป | Jotunheim — Road of Silent Giants | frost_pass, giant_steppe, frozen_hall, broken_wall | 1,282,602 bytes |
| บอส | Hrungnir — Heart of Stone | hrungnir_crater | 1,318,316 bytes |

รวม 3,862,066 bytes (3.86 MB หรือ 3.68 MiB) ลดลงประมาณ 46% จากต้นฉบับ M4A รวม 7,134,572 bytes โดยลดความยาวและแปลงเป็น OGG Vorbis quality 2, stereo 44.1 kHz

## แนวเพลงที่ส่งสร้าง

- เมือง: Nordic folk fantasy instrumental, 76 BPM, gentle harp, bowed strings, wooden flute, warm low strings and subtle bells. เมืองหินของยักษ์ที่มีแสงไฟอบอุ่นกลางหิมะ สงบ ขรึม และสง่างาม ไม่ใช้กลองต่อสู้
- ทั่วไป: cold Nordic orchestral adventure instrumental, 104 BPM, restrained frame drums, plucked strings, low string ostinato, airy flute and icy ambience. เดินทางผ่านช่องเขาหิมะ ทุ่งยักษ์ โถงน้ำแข็ง และกำแพงพัง มีแรงขับพอสำหรับต่อสู้ทั่วไป
- บอส: dramatic orchestral battle instrumental, 138 BPM, pounding toms/taiko, low brass, urgent strings and metallic stone percussion. ต่อสู้ยักษ์หิน Hrungnir ในหลุมเยือกแข็ง เน้นจังหวะหนักแน่นและความกดดัน

คำสั่งร่วม: ไม่มีเนื้อร้อง เสียงพูด หรือเสียงร้อง ขอทำนองใหม่ เชื่อมอารมณ์ด้วย motif Nordic สั้น ๆ เสียงเครื่องดนตรีไม่กลบเอฟเฟกต์เกม และสร้างแยกสามเพลง

## ต้นทาง

- Session: https://www.flowmusic.app/session/04b17913-9df6-437c-95b3-33635da745bf?t=true
- เมือง: https://www.flowmusic.app/song/e34ea0cf-dea9-4a16-bead-e3497bc7a252
- ทั่วไป: https://www.flowmusic.app/song/1223df19-c00f-475b-84cc-17a4da8f467e
- บอส: https://www.flowmusic.app/song/aa22719b-89c0-429e-81a1-6d46ce94fefe

เก็บต้นฉบับใน output/flow_music/chapter4 ซึ่งมี .gdignore เพื่อไม่ให้ Godot นำไฟล์ต้นฉบับเข้าเกม ไฟล์ใช้งานอยู่ใน Sprites/music/chapter4_town.ogg, chapter4_field.ogg และ chapter4_boss.ogg

## การเล่นวนและระดับเสียง

เว็บสร้างเพลงยาวกว่าช่วง 90–120 วินาทีที่ขอ จึงใช้ช่วง 120 วินาที และทำ crossfade ท้ายเข้าต้น 0.8 วินาที เหลือไฟล์เล่นวน 119.2 วินาที ปรับ loudness เป้าหมาย -20 LUFS / true peak -2 dBTP แล้วเข้ารหัส OGG วิธีนี้ลดขอบเสียงกระโดด แต่ไม่ได้รับประกันว่าโครงสร้างทำนองต้นฉบับประพันธ์เป็น seamless loop

MusicPlayer.MAP_TRACKS เป็นตัวจับคู่แมพกับไฟล์ร่วม เมื่อย้ายระหว่างแมพทั่วไปทั้งสี่เพลงเล่นต่อจากตำแหน่งเดิม เมื่อเข้าเมืองหรือแมพบอสใช้ crossfade เดิมของเกม เพลงบอสใช้ตลอดแมพบอสตามคำขอ ไม่เพิ่มไฟล์ combat แยก

ฉาก chapter4_music_test.tscn ตรวจการค้นหา/ถอดรหัสไฟล์ครบหกแมพ การเปิด loop การรักษาเพลงข้ามแมพ และการกลับใช้เพลงบทเดิม โดยไม่บันทึกทับเซฟหรือค่าตั้งเสียงของผู้เล่น

# Forge Guardian — ทุบพื้นลาวา

ท่าธรรมดาทุบครั้งเดียว สกิลทุบ 5 ครั้งตามภาพ Skill ที่มีอยู่แล้ว ใช้เอฟเฟกต์ Godot ที่เคลื่อนไหวจริง: พื้นแตกลาวา เศษหิน หยดลาวาพุ่ง และแสงสีส้มที่ส่องฉาก/ตัวละคร

## ปรับค่าใน Godot

เปิด `data/monsters/forge_guardian.tres` ใน Inspector กลุ่ม **Ground Slam**:

- `Attack Slam Radius`: 210 — รัศมีดาเมจท่าธรรมดา
- `Skill Slam Radius`: 430 — รัศมีดาเมจแต่ละครั้งของสกิล
- `Slam Height`: 120 — ระยะตรวจเท้าผู้เล่นในแนวตั้ง
- `Ground Slam Anchor`: (130, 420) — จุดหัวค้อนในภาพต้นฉบับ ปรับตาม scale/flip อัตโนมัติ แล้วตรวจระดับพื้นจริงด้วย raycast
- `Skill Hit Frames`: 15, 21, 27, 33, 39 (นับจาก 0; อัปเดตหลังต่อเฟรมให้ลื่น)
- กลุ่ม Attack: `Attack Hit Frames` = 15
- กลุ่มสกิล: `Skill Damage Mult` = 0.7 ต่อฮิต และ `Skill Knockback` = 65

สกิลใช้ภาพค้อนเดิม ต่อช่วงยกกลับให้ครบ รวม 56 เฟรมที่ 20 FPS = 2.8 วินาที แต่ละการกระแทกห่าง 0.3 วินาที ท่าธรรมดาคง 29 FPS เอฟเฟกต์หนึ่งชุดอยู่ 0.85 วินาทีและลบตัวเอง

ดาเมจผ่านระบบ Combat และ Player.take_damage เดิม จึงยังมีการหลบ/MISS ตามระบบเกม จำนวน 5 ฮิตหมายถึง 5 จังหวะโจมตีเมื่อผู้เล่นอยู่ในระยะและไม่หลบ เอฟเฟกต์ไม่ทำดาเมจซ้ำเอง

## ไฟล์ระบบ

- `scripts/entities/monster_base.gd`: จับเฟรมกระแทก ตรวจระยะ และส่งดาเมจ
- `scripts/entities/lava_slam_fx.gd`: ลาวากระจาย เศษหิน และแสง
- `Sprites/shaders/lava_slam.gdshader`: พื้นแตกลาวาและการจาง
- `data/sprites/monsters/forge_guardian_frames.tres`: ลำดับท่าและความเร็ว; ดูรายละเอียดการแก้ภาพเด้งล่าสุดใน `output/forge_guardian_stability/README.md`

## ผลทดสอบ

รัน `forge_guardian_slam_test.tscn` ด้วย Godot 4.7.2 GUI / Compatibility ผ่าน 0 failures (`runtime_v2.log`): ท่าปกติ 1 ฮิตทั้งสองทิศ, สกิล 5 ฮิตตรงเฟรม, ระเบิดตรงพื้น collider, ระยะสกิลกว้างกว่า, ออกนอกวงไม่โดน, บอสตายหยุดฮิตที่เหลือ, เอฟเฟกต์หมดอายุ และบอสอื่นไม่เปิดระบบนี้โดยปริยาย

ภาพตรวจในเกม: `normal_left.png`, `normal_right.png`, `skill_lava.png` ส่วนไฟล์ `.before.*` เป็นสำรองก่อนแก้งานครั้งนี้

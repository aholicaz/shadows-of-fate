## NpcDirectory — NPC ชื่อนี้อยู่แมพไหน (★ รอบ 116 ★ สร้างอัตโนมัติด้วย tools/gen_npc_directory.py — อย่าแก้มือ รันสคริปต์ใหม่แทน)
class_name NpcDirectory

const MAP_NAMES := {
	&"asgard_forest_2": "ป่าสนธยา",
	&"ash_procession": "ทางขบวนเถ้า",
	&"blackhorn_rootcrypt": "วิหารเขาทมิฬใต้ราก",
	&"broken_wall": "กำแพงที่แตก",
	&"chain_quarry": "เหมืองโซ่คำสั่ง",
	&"cinder_crossing": "ทางข้ามเถ้า",
	&"cold_forge": "เตาหลอมร้าง",
	&"crystal_garden": "สวนผลึก",
	&"dark_forest": "ป่าเงาลึก",
	&"dark_forest_2": "ป่าเงาลึกชั้นใน",
	&"dimming_wood": "ป่าที่แสงจาง",
	&"eljudnir": "เอลยุดเนียร์ เมืองของผู้ตาย",
	&"ember_mine": "เหมืองถ่านไฟ",
	&"emberhaven": "อัมเบอร์เฮเวน นครใต้เถ้า",
	&"forgotten_battlefield": "สมรภูมิที่ถูกลืม",
	&"frost_pass": "ช่องเขาน้ำแข็ง",
	&"frozen_hall": "โถงภาพวาดน้ำแข็ง",
	&"garm_gate": "ประตูของการ์ม",
	&"giant_steppe": "ทุ่งหญ้ายักษ์",
	&"gjoll_river": "แม่น้ำเกียลล์",
	&"gm_room": "ห้อง GM (ทดสอบ)",
	&"hall_of_names": "โถงแห่งนาม",
	&"hall_of_silence": "ห้องโถงเงียบ",
	&"hrungnir_crater": "หลุมหัวใจสายฟ้า",
	&"iron_road": "ทางเหล็ก",
	&"lightwell_sanctum": "วิหารบ่อแสง",
	&"ljosalf_city": "ลโยซาลฟ์ นครแห่งแสง",
	&"mirror_lake": "ทะเลสาบกระจก",
	&"mist_shore": "ฝั่งหมอกน้ำแข็ง",
	&"nastrond": "นาสตรอนด์ ฝั่งศพ",
	&"nidavellir_town": "นิดาเวลลิร์ นครเตาหลอม",
	&"oathbreak_crucible": "เบ้าหลอมคำสาบาน",
	&"odin_seat": "บัลลังก์ว่างของโอดิน",
	&"prontera_field": "ทุ่งวิหาร",
	&"prontera_town": "พรอนเทรา นครแห่งสายฟ้า",
	&"root_road": "ทางสายราก",
	&"runeblade_training": "ลานทดสอบดาบรูน",
	&"shimmer_road": "ทางประกายแสง",
	&"silver_marsh": "บึงหมอกเงิน",
	&"spring_of_life": "บ่อน้ำแห่งชีวิต",
	&"thunder_scar": "รอยสายฟ้า",
	&"unwritten_forge": "เตาหลอมไร้คำสั่ง",
	&"utgard_town": "อุทการ์ด นครแห่งยักษ์",
	&"vanir_town": "วานาเฮม นครแห่งราก",
	&"withered_grove": "ป่าเหี่ยว",
}

const NPC_MAPS := {
	"กุลล์ไวก์ (ผี)": [&"eljudnir"],
	"คนแปลกหน้า": [&"eljudnir", &"odin_seat"],
	"ช่างกระดูก": [&"eljudnir"],
	"ช่างตีเหล็กฮันส์": [&"nidavellir_town", &"prontera_town"],
	"ช่างรากไม้กัลลา": [&"vanir_town"],
	"ช่างสลักรูนเกอร์ด": [&"utgard_town"],
	"ช่างเอกดวาลิน": [&"nidavellir_town"],
	"ช่างแสงโวลุนด์": [&"ljosalf_city"],
	"ตาแก่กุนนาร์": [&"prontera_town"],
	"ทหารยามธยาซี": [&"utgard_town"],
	"ทหารยามอาร์วิด": [&"vanir_town"],
	"ทหารยามเอริค": [&"prontera_town"],
	"ทหารยามโซล": [&"ljosalf_city"],
	"นักบวชสูงสุดวาลเดอร์": [&"prontera_town"],
	"นักบวชหญิงมาเรีย": [&"prontera_town"],
	"นักบวชอาสมุนด์": [&"utgard_town"],
	"นักบันทึกเอสกิล": [&"vanir_town"],
	"นักล่าที่หายไป (ผี)": [&"eljudnir"],
	"นายหน้าเฮลกา": [&"nidavellir_town"],
	"บรอกก์": [&"nidavellir_town"],
	"บรินยา ช่างปลดพันธะ": [&"emberhaven", &"unwritten_forge"],
	"บ่อแสงเล็ก": [&"ljosalf_city"],
	"ผู้ถือโล่ (ผี)": [&"eljudnir"],
	"ผู้หลุดจากแสง (ผี)": [&"eljudnir"],
	"ผู้อาวุโสญอร์ดา": [&"vanir_town"],
	"ผู้อาวุโสสกาดี": [&"utgard_town"],
	"ผู้เฝ้าสะพานโมดกุด": [&"gjoll_river"],
	"ผู้เห็นแสงเอย์ร": [&"ljosalf_city"],
	"พ่อค้าฮือเมียร์": [&"utgard_town"],
	"พ่อค้าโทนี่": [&"prontera_town"],
	"พ่อค้าไร้ชื่อ": [&"eljudnir"],
	"ลีฟ ผู้รักษาแผลไฟ": [&"emberhaven"],
	"ศิลาพักนาม": [&"emberhaven"],
	"ศิลาริมทะเลสาบ": [&"mirror_lake"],
	"ศิลาแห่งเฮล": [&"eljudnir"],
	"ศิลาแห่งโยตุน": [&"utgard_town"],
	"สวาลา ผู้เก็บชื่อ": [&"emberhaven"],
	"หมอคนแคระเฮดิน": [&"nidavellir_town"],
	"หมอน็อตต์": [&"ljosalf_city"],
	"หมอสมุนไพรลีฟ": [&"vanir_town"],
	"หมอเบสต์ลา": [&"utgard_town"],
	"หัวหน้ากิลด์บียอร์น": [&"prontera_town"],
	"ออร์ม พ่อค้าผู้ลี้ภัย": [&"emberhaven"],
	"อิงกริด": [&"prontera_town"],
	"เจ้าเมืองดาเกอร์": [&"ljosalf_city"],
	"เด็กยักษ์เลฟ": [&"utgard_town"],
	"เด็กหญิงฟรีดา": [&"vanir_town"],
	"เด็กเอลฟ์อิลวา": [&"ljosalf_city"],
	"เสาวาปแห่งธอร์": [&"nidavellir_town", &"prontera_town"],
	"เสาวาปแห่งราก": [&"vanir_town"],
	"เอลฟ์กลวง (โซล)": [&"ljosalf_city"],
	"เฮล ผู้ปกครองผู้ตาย": [&"eljudnir"],
	"แม่ค้าซิฟา": [&"vanir_town"],
	"แม่ค้าลอฟน์": [&"ljosalf_city"],
	"โซล (ผู้ถูกทิ้ง)": [&"dimming_wood"],
}


## แมพทั้งหมดที่มี NPC ชื่อนี้ (ว่าง = ไม่รู้จัก)
static func maps_of(npc_name: String) -> Array:
	return NPC_MAPS.get(npc_name, [])


## ชื่อแมพที่ NPC อยู่ — ถ้ามีหลายที่ เลือกแมพในบทที่ระบุ (chapter 0 = เอาที่แรก) · คืน "" ถ้าไม่รู้จัก
static func map_name_of(npc_name: String, chapter: int = 0) -> String:
	var ids: Array = maps_of(npc_name)
	if ids.is_empty():
		return ""
	var pick: StringName = ids[0]
	if chapter > 0:
		for id in ids:
			if MapAtlas.chapter_of(id) == chapter:
				pick = id
				break
	return String(MAP_NAMES.get(pick, String(pick)))

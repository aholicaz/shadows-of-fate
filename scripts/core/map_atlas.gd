## MapAtlas — สมุดแผนที่โลก (รอบ 102)
##
## ที่เดียวที่บอกว่า "แมพไหนอยู่บทไหน · ติดกับแมพไหน · มีมอนอะไร · เลเวลประมาณเท่าไหร่"
## ใช้ 2 ที่:
##   1. หน้า World Map (แท็บ "แผนที่") — โชว์แมพทั้งบท คลิกแล้วเห็นรายชื่อมอน
##   2. เสาวาป — เช็คว่าวาปไปแมพไหนได้ · ไกลกี่ทอด · ค่าวาปเท่าไหร่
##
## ★★ เพิ่มบทใหม่ (บท 4-9) ทำยังไง ★★
## 1. เพิ่ม id แมพใน `Game.MAPS` + `Game.MAP_NAMES` เหมือนเดิม
## 2. เพิ่ม 1 บรรทัดใน `MAPS` ข้างล่างนี้: chapter · kind · level · monsters · links
## 3. เพิ่มชื่อบทใน `CHAPTER_NAMES`
## เท่านั้น — หน้าแผนที่จะแบ่งหน้าให้เองตามจำนวนบท และเสาวาปจะคิดระยะ/ราคาให้เอง
##
## ★ ข้อมูลนี้มาจากไฟล์ฉากจริง ★ (ตัวสร้างมอนใน scenes/maps/*.tscn และประตูวาปในนั้น)
## ถ้าแก้ฉากแล้วมอน/ประตูเปลี่ยน ให้มาแก้ตารางนี้ตามด้วย
## (เทสต์ r102 มีข้อที่เตือนถ้าตารางกับ Game.MAPS ไม่ตรงกัน)
class_name MapAtlas
extends RefCounted

## ชนิดแมพ — ใช้เลือกสี/ไอคอนบนแผนที่โลก
const KIND_TOWN := "town"       # เมือง (ไม่มีมอน · ร้านค้า/NPC)
const KIND_FIELD := "field"     # ทุ่ง/ป่า/ถ้ำ ปกติ
const KIND_BOSS := "boss"       # ลานบอส
const KIND_HIDDEN := "hidden"   # ห้องทดสอบ ไม่โชว์บนแผนที่โลก

const CHAPTER_NAMES := {
	8: "บทที่ 8 — อิกดราซิล",
	7: "บทที่ 7 — มุสเปลเฮม",
	1: "บทที่ 1 — มิดการ์ด",
	2: "บทที่ 2 — สวาร์ทัลฟ์เฮม",
	3: "บทที่ 3 — วานาเฮม",
	4: "บทที่ 4 — โยตุนเฮม",
	5: "บทที่ 5 — อัลฟ์เฮม",
	6: "บทที่ 6 — นิฟล์เฮม",
}

## ★ ตารางหลัก ★  chapter · kind · level (ช่วงเลเวลมอน) · monsters · links (แมพที่ติดกัน)
const MAPS := {
	&"yggdrasil_root": {"chapter":8,"kind":KIND_FIELD,"level":[110,130],"monsters":[],"links":[&"emberhaven",&"yggdrasil_01"]},
	&"yggdrasil_01": {"chapter":8,"kind":KIND_HIDDEN,"level":[111,111],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_02"]},
	&"yggdrasil_02": {"chapter":8,"kind":KIND_HIDDEN,"level":[112,112],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_03"]},
	&"yggdrasil_03": {"chapter":8,"kind":KIND_HIDDEN,"level":[113,113],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_04"]},
	&"yggdrasil_04": {"chapter":8,"kind":KIND_HIDDEN,"level":[114,114],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_05"]},
	&"yggdrasil_05": {"chapter":8,"kind":KIND_HIDDEN,"level":[115,115],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_06"]},
	&"yggdrasil_06": {"chapter":8,"kind":KIND_HIDDEN,"level":[116,116],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_07"]},
	&"yggdrasil_07": {"chapter":8,"kind":KIND_HIDDEN,"level":[117,117],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_08"]},
	&"yggdrasil_08": {"chapter":8,"kind":KIND_HIDDEN,"level":[118,118],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_09"]},
	&"yggdrasil_09": {"chapter":8,"kind":KIND_HIDDEN,"level":[119,119],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_10"]},
	&"yggdrasil_10": {"chapter":8,"kind":KIND_HIDDEN,"level":[120,120],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_11"]},
	&"yggdrasil_11": {"chapter":8,"kind":KIND_HIDDEN,"level":[121,121],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_12"]},
	&"yggdrasil_12": {"chapter":8,"kind":KIND_HIDDEN,"level":[122,122],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_13"]},
	&"yggdrasil_13": {"chapter":8,"kind":KIND_HIDDEN,"level":[123,123],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_14"]},
	&"yggdrasil_14": {"chapter":8,"kind":KIND_HIDDEN,"level":[124,124],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_15"]},
	&"yggdrasil_15": {"chapter":8,"kind":KIND_HIDDEN,"level":[125,125],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_16"]},
	&"yggdrasil_16": {"chapter":8,"kind":KIND_HIDDEN,"level":[126,126],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_17"]},
	&"yggdrasil_17": {"chapter":8,"kind":KIND_HIDDEN,"level":[127,127],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_18"]},
	&"yggdrasil_18": {"chapter":8,"kind":KIND_HIDDEN,"level":[128,128],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_19"]},
	&"yggdrasil_19": {"chapter":8,"kind":KIND_HIDDEN,"level":[129,129],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_20"]},
	&"yggdrasil_20": {"chapter":8,"kind":KIND_HIDDEN,"level":[130,130],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_21"]},
	&"yggdrasil_21": {"chapter":8,"kind":KIND_HIDDEN,"level":[131,131],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_22"]},
	&"yggdrasil_22": {"chapter":8,"kind":KIND_HIDDEN,"level":[132,132],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_23"]},
	&"yggdrasil_23": {"chapter":8,"kind":KIND_HIDDEN,"level":[133,133],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_24"]},
	&"yggdrasil_24": {"chapter":8,"kind":KIND_HIDDEN,"level":[134,134],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_25"]},
	&"yggdrasil_25": {"chapter":8,"kind":KIND_HIDDEN,"level":[135,135],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_26"]},
	&"yggdrasil_26": {"chapter":8,"kind":KIND_HIDDEN,"level":[136,136],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_27"]},
	&"yggdrasil_27": {"chapter":8,"kind":KIND_HIDDEN,"level":[137,137],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_28"]},
	&"yggdrasil_28": {"chapter":8,"kind":KIND_HIDDEN,"level":[138,138],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_29"]},
	&"yggdrasil_29": {"chapter":8,"kind":KIND_HIDDEN,"level":[139,139],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_30"]},
	&"yggdrasil_30": {"chapter":8,"kind":KIND_HIDDEN,"level":[140,140],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_31"]},
	&"yggdrasil_31": {"chapter":8,"kind":KIND_HIDDEN,"level":[141,141],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_32"]},
	&"yggdrasil_32": {"chapter":8,"kind":KIND_HIDDEN,"level":[142,142],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_33"]},
	&"yggdrasil_33": {"chapter":8,"kind":KIND_HIDDEN,"level":[143,143],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_34"]},
	&"yggdrasil_34": {"chapter":8,"kind":KIND_HIDDEN,"level":[144,144],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_35"]},
	&"yggdrasil_35": {"chapter":8,"kind":KIND_HIDDEN,"level":[145,145],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_36"]},
	&"yggdrasil_36": {"chapter":8,"kind":KIND_HIDDEN,"level":[146,146],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_37"]},
	&"yggdrasil_37": {"chapter":8,"kind":KIND_HIDDEN,"level":[147,147],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_38"]},
	&"yggdrasil_38": {"chapter":8,"kind":KIND_HIDDEN,"level":[148,148],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_39"]},
	&"yggdrasil_39": {"chapter":8,"kind":KIND_HIDDEN,"level":[149,149],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_40"]},
	&"yggdrasil_40": {"chapter":8,"kind":KIND_HIDDEN,"level":[150,150],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_41"]},
	&"yggdrasil_41": {"chapter":8,"kind":KIND_HIDDEN,"level":[151,151],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_42"]},
	&"yggdrasil_42": {"chapter":8,"kind":KIND_HIDDEN,"level":[152,152],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_43"]},
	&"yggdrasil_43": {"chapter":8,"kind":KIND_HIDDEN,"level":[153,153],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_44"]},
	&"yggdrasil_44": {"chapter":8,"kind":KIND_HIDDEN,"level":[154,154],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_45"]},
	&"yggdrasil_45": {"chapter":8,"kind":KIND_HIDDEN,"level":[155,155],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_46"]},
	&"yggdrasil_46": {"chapter":8,"kind":KIND_HIDDEN,"level":[156,156],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_47"]},
	&"yggdrasil_47": {"chapter":8,"kind":KIND_HIDDEN,"level":[157,157],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_48"]},
	&"yggdrasil_48": {"chapter":8,"kind":KIND_HIDDEN,"level":[158,158],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_49"]},
	&"yggdrasil_49": {"chapter":8,"kind":KIND_HIDDEN,"level":[159,159],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_50"]},
	&"yggdrasil_50": {"chapter":8,"kind":KIND_HIDDEN,"level":[160,160],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_51"]},
	# ★ รอบ 179 ★ ชั้น 51-100
	&"yggdrasil_51": {"chapter":8,"kind":KIND_HIDDEN,"level":[161,161],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_52"]},
	&"yggdrasil_52": {"chapter":8,"kind":KIND_HIDDEN,"level":[162,162],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_53"]},
	&"yggdrasil_53": {"chapter":8,"kind":KIND_HIDDEN,"level":[163,163],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_54"]},
	&"yggdrasil_54": {"chapter":8,"kind":KIND_HIDDEN,"level":[164,164],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_55"]},
	&"yggdrasil_55": {"chapter":8,"kind":KIND_HIDDEN,"level":[165,165],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_56"]},
	&"yggdrasil_56": {"chapter":8,"kind":KIND_HIDDEN,"level":[166,166],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_57"]},
	&"yggdrasil_57": {"chapter":8,"kind":KIND_HIDDEN,"level":[167,167],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_58"]},
	&"yggdrasil_58": {"chapter":8,"kind":KIND_HIDDEN,"level":[168,168],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_59"]},
	&"yggdrasil_59": {"chapter":8,"kind":KIND_HIDDEN,"level":[169,169],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_60"]},
	&"yggdrasil_60": {"chapter":8,"kind":KIND_HIDDEN,"level":[170,170],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_61"]},
	&"yggdrasil_61": {"chapter":8,"kind":KIND_HIDDEN,"level":[171,171],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_62"]},
	&"yggdrasil_62": {"chapter":8,"kind":KIND_HIDDEN,"level":[172,172],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_63"]},
	&"yggdrasil_63": {"chapter":8,"kind":KIND_HIDDEN,"level":[173,173],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_64"]},
	&"yggdrasil_64": {"chapter":8,"kind":KIND_HIDDEN,"level":[174,174],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_65"]},
	&"yggdrasil_65": {"chapter":8,"kind":KIND_HIDDEN,"level":[175,175],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_66"]},
	&"yggdrasil_66": {"chapter":8,"kind":KIND_HIDDEN,"level":[176,176],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_67"]},
	&"yggdrasil_67": {"chapter":8,"kind":KIND_HIDDEN,"level":[177,177],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_68"]},
	&"yggdrasil_68": {"chapter":8,"kind":KIND_HIDDEN,"level":[178,178],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_69"]},
	&"yggdrasil_69": {"chapter":8,"kind":KIND_HIDDEN,"level":[179,179],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_70"]},
	&"yggdrasil_70": {"chapter":8,"kind":KIND_HIDDEN,"level":[180,180],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_71"]},
	&"yggdrasil_71": {"chapter":8,"kind":KIND_HIDDEN,"level":[181,181],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_72"]},
	&"yggdrasil_72": {"chapter":8,"kind":KIND_HIDDEN,"level":[182,182],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_73"]},
	&"yggdrasil_73": {"chapter":8,"kind":KIND_HIDDEN,"level":[183,183],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_74"]},
	&"yggdrasil_74": {"chapter":8,"kind":KIND_HIDDEN,"level":[184,184],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_75"]},
	&"yggdrasil_75": {"chapter":8,"kind":KIND_HIDDEN,"level":[185,185],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_76"]},
	&"yggdrasil_76": {"chapter":8,"kind":KIND_HIDDEN,"level":[186,186],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_77"]},
	&"yggdrasil_77": {"chapter":8,"kind":KIND_HIDDEN,"level":[187,187],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_78"]},
	&"yggdrasil_78": {"chapter":8,"kind":KIND_HIDDEN,"level":[188,188],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_79"]},
	&"yggdrasil_79": {"chapter":8,"kind":KIND_HIDDEN,"level":[189,189],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_80"]},
	&"yggdrasil_80": {"chapter":8,"kind":KIND_HIDDEN,"level":[190,190],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_81"]},
	&"yggdrasil_81": {"chapter":8,"kind":KIND_HIDDEN,"level":[191,191],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_82"]},
	&"yggdrasil_82": {"chapter":8,"kind":KIND_HIDDEN,"level":[192,192],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_83"]},
	&"yggdrasil_83": {"chapter":8,"kind":KIND_HIDDEN,"level":[193,193],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_84"]},
	&"yggdrasil_84": {"chapter":8,"kind":KIND_HIDDEN,"level":[194,194],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_85"]},
	&"yggdrasil_85": {"chapter":8,"kind":KIND_HIDDEN,"level":[195,195],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_86"]},
	&"yggdrasil_86": {"chapter":8,"kind":KIND_HIDDEN,"level":[196,196],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_87"]},
	&"yggdrasil_87": {"chapter":8,"kind":KIND_HIDDEN,"level":[197,197],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_88"]},
	&"yggdrasil_88": {"chapter":8,"kind":KIND_HIDDEN,"level":[198,198],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_89"]},
	&"yggdrasil_89": {"chapter":8,"kind":KIND_HIDDEN,"level":[199,199],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_90"]},
	&"yggdrasil_90": {"chapter":8,"kind":KIND_HIDDEN,"level":[200,200],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_91"]},
	&"yggdrasil_91": {"chapter":8,"kind":KIND_HIDDEN,"level":[201,201],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_92"]},
	&"yggdrasil_92": {"chapter":8,"kind":KIND_HIDDEN,"level":[202,202],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_93"]},
	&"yggdrasil_93": {"chapter":8,"kind":KIND_HIDDEN,"level":[203,203],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_94"]},
	&"yggdrasil_94": {"chapter":8,"kind":KIND_HIDDEN,"level":[204,204],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_95"]},
	&"yggdrasil_95": {"chapter":8,"kind":KIND_HIDDEN,"level":[205,205],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_96"]},
	&"yggdrasil_96": {"chapter":8,"kind":KIND_HIDDEN,"level":[206,206],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_97"]},
	&"yggdrasil_97": {"chapter":8,"kind":KIND_HIDDEN,"level":[207,207],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_98"]},
	&"yggdrasil_98": {"chapter":8,"kind":KIND_HIDDEN,"level":[208,208],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_99"]},
	&"yggdrasil_99": {"chapter":8,"kind":KIND_HIDDEN,"level":[209,209],"monsters":[],"links":[&"yggdrasil_root",&"yggdrasil_100"]},
	&"yggdrasil_100": {"chapter":8,"kind":KIND_HIDDEN,"level":[210,210],"monsters":[],"links":[&"yggdrasil_root"]},


	&"runeblade_training": {"chapter":3,"kind":KIND_HIDDEN,"level":[48,50],"monsters":[],"links":[&"vanir_town"]},
	&"blackhorn_rootcrypt": {"chapter":3, "kind":KIND_BOSS, "level":[50,54], "monsters":[&"baphomet_jr",&"baphomet"], "links":[&"silver_marsh"]},
	# ---------- บทที่ 1 — มิดการ์ด ----------
	&"prontera_town": {
		"chapter": 1, "kind": KIND_TOWN, "level": [0, 0], "monsters": [],
		"links": [&"prontera_field"],
	},
	&"prontera_field": {
		"chapter": 1, "kind": KIND_FIELD, "level": [1, 6],
		"monsters": [&"poring", &"drops", &"fabre"],
		"links": [&"prontera_town", &"asgard_forest_2"],
	},
	&"asgard_forest_2": {
		"chapter": 1, "kind": KIND_FIELD, "level": [6, 14],
		"monsters": [&"chonchon", &"drops", &"wolf"],
		"links": [&"prontera_field", &"dark_forest"],
	},
	&"dark_forest": {
		"chapter": 1, "kind": KIND_FIELD, "level": [12, 20],
		"monsters": [&"lunatic", &"hornet", &"wolf", &"king_poring"],
		"links": [&"asgard_forest_2", &"dark_forest_2", &"thunder_scar"],
	},
	&"thunder_scar": {
		"chapter": 1, "kind": KIND_BOSS, "level": [25, 30],
		"monsters": [&"stormscar"],
		"links": [&"dark_forest"],
	},
	&"dark_forest_2": {
		"chapter": 1, "kind": KIND_FIELD, "level": [20, 28],
		"monsters": [&"munak", &"orc_warrior"],
		"links": [&"dark_forest", &"iron_road"],
	},

	# ---------- บทที่ 2 — สวาร์ทัลฟ์เฮม ----------
	&"iron_road": {
		"chapter": 2, "kind": KIND_FIELD, "level": [28, 34],
		"monsters": [&"pitman", &"steel_beetle"],
		"links": [&"dark_forest_2", &"nidavellir_town"],
	},
	&"nidavellir_town": {
		"chapter": 2, "kind": KIND_TOWN, "level": [0, 0], "monsters": [],
		"links": [&"iron_road", &"ember_mine"],
	},
	&"ember_mine": {
		"chapter": 2, "kind": KIND_FIELD, "level": [32, 38],
		"monsters": [&"ember_bat", &"magma_slug"],
		"links": [&"nidavellir_town", &"hall_of_silence"],
	},
	&"hall_of_silence": {
		"chapter": 2, "kind": KIND_FIELD, "level": [36, 44],
		"monsters": [&"forge_golem", &"rune_watcher", &"silent_wraith"],
		"links": [&"ember_mine", &"cold_forge"],
	},
	&"cold_forge": {
		"chapter": 2, "kind": KIND_BOSS, "level": [44, 50],
		"monsters": [&"forge_guardian"],
		"links": [&"hall_of_silence", &"root_road"],
	},

	# ---------- บทที่ 3 — วานาเฮม ----------
	&"root_road": {
		"chapter": 3, "kind": KIND_FIELD, "level": [39, 43],
		"monsters": [&"root_crawler", &"thorn_hound"],
		"links": [&"cold_forge", &"vanir_town"],
	},
	&"vanir_town": {
		"chapter": 3, "kind": KIND_TOWN, "level": [0, 0], "monsters": [],
		"links": [&"root_road", &"silver_marsh", &"frost_pass"],
	},
	&"silver_marsh": {
		"chapter": 3, "kind": KIND_FIELD, "level": [44, 48],
		"monsters": [&"mist_sprite", &"bog_lurker"],
		"links": [&"vanir_town", &"withered_grove", &"blackhorn_rootcrypt"],
	},
	&"withered_grove": {
		"chapter": 3, "kind": KIND_FIELD, "level": [49, 54],
		"monsters": [&"withered_treant", &"vanir_sentinel"],
		"links": [&"silver_marsh", &"forgotten_battlefield"],
	},
	&"forgotten_battlefield": {
		"chapter": 3, "kind": KIND_FIELD, "level": [55, 58],
		"monsters": [&"war_wraith", &"thorn_matriarch"],
		"links": [&"withered_grove", &"spring_of_life"],
	},
	&"spring_of_life": {
		"chapter": 3, "kind": KIND_BOSS, "level": [60, 60],
		"monsters": [&"gullveig_ember"],
		"links": [&"forgotten_battlefield"],
	},

	# ---------- บทที่ 4 — โยตุนเฮม (รอบ 105) ----------
	&"frost_pass": {"chapter": 4, "kind": KIND_FIELD, "level": [60, 63], "monsters": [&"frost_wolf", &"snow_hawk"], "links": [&"vanir_town", &"utgard_town"]},
	&"utgard_town": {"chapter": 4, "kind": KIND_TOWN, "level": [0, 0], "monsters": [], "links": [&"frost_pass", &"giant_steppe"]},
	&"giant_steppe": {"chapter": 4, "kind": KIND_FIELD, "level": [63, 66], "monsters": [&"snow_mammoth", &"ice_troll", &"snow_hawk"], "links": [&"utgard_town", &"frozen_hall"]},
	&"frozen_hall": {"chapter": 4, "kind": KIND_FIELD, "level": [66, 69], "monsters": [&"stone_soldier", &"echo_wraith"], "links": [&"giant_steppe", &"broken_wall"]},
	&"broken_wall": {"chapter": 4, "kind": KIND_FIELD, "level": [69, 71], "monsters": [&"ice_troll", &"stone_soldier", &"wall_shieldbearer"], "links": [&"frozen_hall", &"hrungnir_crater"]},
	&"hrungnir_crater": {"chapter": 4, "kind": KIND_BOSS, "level": [72, 72], "monsters": [&"stone_hrungnir"], "links": [&"broken_wall", &"shimmer_road"]},

	# ---------- บทที่ 5 — อัลฟ์เฮม (รอบ 105) ----------
	&"shimmer_road": {"chapter": 5, "kind": KIND_FIELD, "level": [72, 75], "monsters": [&"light_moth", &"crystal_stag"], "links": [&"hrungnir_crater", &"ljosalf_city"]},
	&"ljosalf_city": {"chapter": 5, "kind": KIND_TOWN, "level": [0, 0], "monsters": [], "links": [&"shimmer_road", &"crystal_garden"]},
	&"crystal_garden": {"chapter": 5, "kind": KIND_FIELD, "level": [75, 78], "monsters": [&"crystal_stag", &"light_eater_bloom", &"garden_keeper"], "links": [&"ljosalf_city", &"mirror_lake"]},
	&"mirror_lake": {"chapter": 5, "kind": KIND_FIELD, "level": [78, 81], "monsters": [&"reflection", &"water_nymph"], "links": [&"crystal_garden", &"dimming_wood"]},
	&"dimming_wood": {"chapter": 5, "kind": KIND_FIELD, "level": [81, 83], "monsters": [&"hollow_elf", &"hollow_moth", &"light_forsaken"], "links": [&"mirror_lake", &"lightwell_sanctum"]},
	&"lightwell_sanctum": {"chapter": 5, "kind": KIND_BOSS, "level": [84, 84], "monsters": [&"radiant_alfr"], "links": [&"dimming_wood", &"mist_shore"]},

	# ---------- บทที่ 6 — นิฟล์เฮม + เฮลเฮม (รอบ 105) ----------
	&"mist_shore": {"chapter": 6, "kind": KIND_FIELD, "level": [84, 86], "monsters": [&"mist_ghost", &"hel_hound"], "links": [&"lightwell_sanctum", &"eljudnir"]},
	&"eljudnir": {"chapter": 6, "kind": KIND_TOWN, "level": [0, 0], "monsters": [], "links": [&"mist_shore", &"gjoll_river"]},
	&"gjoll_river": {"chapter": 6, "kind": KIND_FIELD, "level": [86, 89], "monsters": [&"drowned", &"ferryman", &"hel_hound"], "links": [&"eljudnir", &"hall_of_names"]},
	&"hall_of_names": {"chapter": 6, "kind": KIND_FIELD, "level": [89, 91], "monsters": [&"name_warden", &"erased_voice"], "links": [&"gjoll_river", &"nastrond"]},
	&"nastrond": {"chapter": 6, "kind": KIND_FIELD, "level": [91, 94], "monsters": [&"drowned", &"nidhogg_spawn", &"false_judge"], "links": [&"hall_of_names", &"garm_gate"]},
	&"garm_gate": {"chapter": 6, "kind": KIND_BOSS, "level": [96, 96], "monsters": [&"chained_garm"], "links": [&"nastrond", &"odin_seat"]},
	&"odin_seat": {"chapter": 6, "kind": KIND_HIDDEN, "level": [0, 0], "monsters": [], "links": [&"garm_gate", &"cinder_crossing"]},

	&"cinder_crossing": {"chapter": 7, "kind": KIND_FIELD, "level": [96, 98], "monsters": [&"cinder_hound", &"slag_mantis"], "links": [&"odin_seat", &"emberhaven"]},
	&"emberhaven": {"chapter": 7, "kind": KIND_TOWN, "level": [96, 110], "monsters": [], "links": [&"yggdrasil_root",&"cinder_crossing", &"chain_quarry"]},
	&"chain_quarry": {"chapter": 7, "kind": KIND_FIELD, "level": [98, 100], "monsters": [&"chainbound_ogre", &"slag_mantis"], "links": [&"emberhaven", &"unwritten_forge"]},
	&"unwritten_forge": {"chapter": 7, "kind": KIND_BOSS, "level": [99, 101], "monsters": [&"kiln_sentinel"], "links": [&"chain_quarry", &"ash_procession"]},
	&"ash_procession": {"chapter": 7, "kind": KIND_FIELD, "level": [102, 106], "monsters": [&"ash_knight", &"ember_oracle"], "links": [&"unwritten_forge", &"oathbreak_crucible"]},
	&"oathbreak_crucible": {"chapter": 7, "kind": KIND_BOSS, "level": [108, 110], "monsters": [&"oath_warden"], "links": [&"ash_procession"]},

	# ---------- ไม่โชว์บนแผนที่โลก ----------
	&"gm_room": {
		"chapter": 0, "kind": KIND_HIDDEN, "level": [0, 0], "monsters": [], "links": [],
	},
}

# =========================================================
# ★★ ค่าวาปของเสาวาป ★★
# =========================================================
## ค่าวาปขั้นต้น (แมพที่ใกล้สุดเท่าที่วาปได้ = ห่าง 2 ทอด)
const WARP_BASE_COST := 300      # ★ รอบ 119 ★ 2000 → 300 (ผู้ใช้ลดราคาขายไอเทมแล้ว)
## ไกลขึ้นทุก 1 ทอด บวกเท่านี้
const WARP_COST_PER_HOP := 200   # ★ รอบ 119 ★ 1600 → 200
## เพดานค่าวาป
const WARP_MAX_COST := 3000      # ★ รอบ 119 ★ 25000 → 3000
## ★ ต้องห่างอย่างน้อยกี่ทอดถึงจะวาปได้ ★ 2 = "เว้นแมพที่ติดกัน" (เดินเอาสิ อยู่ข้าง ๆ เอง)
const WARP_MIN_HOPS := 2


static func has(map_id: StringName) -> bool:
	return MAPS.has(map_id)


static func info(map_id: StringName) -> Dictionary:
	return MAPS.get(map_id, {})


static func chapter_of(map_id: StringName) -> int:
	return int(info(map_id).get("chapter", 0))


static func kind_of(map_id: StringName) -> String:
	return String(info(map_id).get("kind", KIND_FIELD))


static func level_range(map_id: StringName) -> Array:
	var lv: Array = info(map_id).get("level", [0, 0])
	return lv if lv.size() >= 2 else [0, 0]


static func monsters_of(map_id: StringName) -> Array:
	return info(map_id).get("monsters", [])


static func links_of(map_id: StringName) -> Array:
	return info(map_id).get("links", [])


## บททั้งหมดที่มีแมพอยู่จริง เรียงจากน้อยไปมาก (ไม่รวมบท 0 = ห้องทดสอบ)
static func chapters() -> Array:
	var seen: Dictionary = {}
	for mid in MAPS.keys():
		var c := chapter_of(mid)
		if c > 0:
			seen[c] = true
	var out: Array = seen.keys()
	out.sort()
	return out


static func chapter_name(no: int) -> String:
	return String(CHAPTER_NAMES.get(no, "บทที่ %d" % no))


## แมพในบทนั้น (เรียงตามลำดับที่ประกาศไว้ใน MAPS = ลำดับการเดินทางจริง)
static func maps_of_chapter(no: int) -> Array:
	var out: Array = []
	for mid in MAPS.keys():
		if chapter_of(mid) == no and kind_of(mid) != KIND_HIDDEN:
			if mid == &"blackhorn_rootcrypt" and not PlayerState.has_flag(&"rb_dungeon_open"): continue
			out.append(mid)
	return out


# =========================================================
# ระยะทาง (นับ "ทอด" = ต้องผ่านประตูกี่บาน) — BFS บนเส้นเชื่อมของแมพ
# =========================================================
## −1 = ไปไม่ถึง (คนละเกาะ)
static func hops(from_id: StringName, to_id: StringName) -> int:
	if from_id == to_id:
		return 0
	if not has(from_id) or not has(to_id):
		return -1
	var dist: Dictionary = {from_id: 0}
	var queue: Array = [from_id]
	var head := 0
	while head < queue.size():
		var cur: StringName = queue[head]
		head += 1
		var d: int = dist[cur]
		for nxt in links_of(cur):
			var n := StringName(nxt)
			if dist.has(n):
				continue
			dist[n] = d + 1
			if n == to_id:
				return d + 1
			queue.append(n)
	return -1


## ค่าวาปจาก a ไป b (บาท/เซนี) — 0 = วาปไม่ได้
static func warp_cost(from_id: StringName, to_id: StringName) -> int:
	var h := hops(from_id, to_id)
	if h < WARP_MIN_HOPS:
		return 0
	return mini(WARP_MAX_COST, WARP_BASE_COST + (h - WARP_MIN_HOPS) * WARP_COST_PER_HOP)


# =========================================================
# เงื่อนไขปลดล็อกปลายทาง
# =========================================================
## เคยไปแมพนี้แล้วหรือยัง (ธง visited_map_<id> ตั้งตอนเข้าแมพ — ดู MapBase._ready)
static func visited_flag(map_id: StringName) -> StringName:
	return StringName("visited_map_" + String(map_id))


static func is_visited(map_id: StringName) -> bool:
	return PlayerState.has_flag(visited_flag(map_id))


## ★ ฆ่ามอนในแมพนี้ครบทุกชนิดแล้วหรือยัง ★ (เมืองไม่มีมอน = ถือว่าเคลียร์แล้ว)
static func is_cleared(map_id: StringName) -> bool:
	var list: Array = monsters_of(map_id)
	if list.is_empty():
		return true
	for mid in list:
		if PlayerState.kill_count(StringName(mid)) <= 0:
			return false
	return true


## ฆ่าไปกี่ชนิดจากทั้งหมดกี่ชนิด (เอาไว้โชว์ "3/4" บนหน้าแผนที่)
static func clear_progress(map_id: StringName) -> Array:
	var list: Array = monsters_of(map_id)
	var got := 0
	for mid in list:
		if PlayerState.kill_count(StringName(mid)) > 0:
			got += 1
	return [got, list.size()]


## ★★ ปลายทางที่เสาวาปในแมพ from_id ยอมให้ไป ★★
## คืน Array ของ { id, name, hops, cost, ok, why }
##   ok = ไปได้เลย · why = เหตุผลที่ยังไปไม่ได้ (เอาไว้โชว์เป็นข้อความจาง ๆ)
static func warp_destinations(from_id: StringName) -> Array:
	var out: Array = []
	for mid in MAPS.keys():
		var id := StringName(mid)
		if id == from_id or kind_of(id) == KIND_HIDDEN:
			continue
		var h := hops(from_id, id)
		if h < WARP_MIN_HOPS:
			continue                      # ★ เว้นแมพที่ติดกัน ★ (และแมพที่ไปไม่ถึง h = −1)
		var cost := BountyBoard.guild_price(warp_cost(from_id, id))   # ★ รอบ 158 ★ ส่วนลดขั้นกิลด์
		var why := ""
		if not is_visited(id):
			why = "ยังไม่เคยไปถึง"
		elif not is_cleared(id):
			var p := clear_progress(id)
			why = "ล่ามอนยังไม่ครบ (%d/%d ชนิด)" % [p[0], p[1]]
		elif PlayerState.zeny < cost:
			why = "เงินไม่พอ"
		out.append({
			"id": id, "name": Game.map_display_name(id),
			"hops": h, "cost": cost, "ok": why == "", "why": why,
			"chapter": chapter_of(id), "kind": kind_of(id),   # ★ รอบ 119 ★
		})
	# ★ รอบ 119 ★ เรียงตามบท → เมืองก่อนแมพหน้าบอส → ระยะทาง (เดิมเรียงตามราคา)
	out.sort_custom(func(a, b): return warp_sort_key(a) < warp_sort_key(b))
	return out


## ★ รอบ 119 ★ คีย์เรียงปลายทางวาป: [บท, เมือง=0/อื่น=1, ระยะทาง, ชื่อ]
static func warp_sort_key(d: Dictionary) -> Array:
	return [int(d.get("chapter", 0)), 0 if String(d.get("kind", "")) == KIND_TOWN else 1, int(d.get("hops", 0)), String(d.get("name", ""))]


## ★ รอบ 119 ★ แมพหน้าลานบอส = แมพธรรมดาที่มีทางต่อไปลานบอส "ในบทเดียวกัน" (ฝั่งขาเข้า ไม่ใช่ทางออกหลังบอสของบทก่อน)
static func boss_gate_maps() -> Array:
	var out: Array = []
	for mid in MAPS.keys():
		var id := StringName(mid)
		if kind_of(id) != KIND_FIELD:
			continue
		for l in links_of(id):
			var lid := StringName(l)
			if kind_of(lid) == KIND_BOSS and chapter_of(lid) == chapter_of(id):
				out.append(id)
				break
	return out


## ★ รอบ 119 ★ ปลายทางมาตรฐานของเสาวาปทุกเมือง = ทุกเมือง + แมพหน้าลานบอสทุกบท (เรียงตามบท)
static func warp_hub_targets() -> Array:
	var out: Array = []
	for mid in MAPS.keys():
		var id := StringName(mid)
		if kind_of(id) == KIND_TOWN:
			out.append(id)
	out.append_array(boss_gate_maps())
	out.sort_custom(func(a, b):
		var ka := [chapter_of(a), 0 if kind_of(a) == KIND_TOWN else 1, String(a)]
		var kb := [chapter_of(b), 0 if kind_of(b) == KIND_TOWN else 1, String(b)]
		return ka < kb)
	return out

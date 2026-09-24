## Game — ตัวจัดการฉาก/การเปลี่ยนแมพ (Autoload ชื่อ "Game")
## หมายเหตุ: ไฟล์นี้ห้ามใส่ class_name เพราะจะชนกับชื่อ Autoload
extends Node

## ทะเบียนแมพทั้งหมด: id -> path ของไฟล์ .tscn
## เพิ่มแมพใหม่ = เพิ่ม 1 บรรทัดตรงนี้
const MAPS := {
	&"yggdrasil_21": "res://scenes/maps/yggdrasil_21.tscn",
	&"yggdrasil_22": "res://scenes/maps/yggdrasil_22.tscn",
	&"yggdrasil_23": "res://scenes/maps/yggdrasil_23.tscn",
	&"yggdrasil_24": "res://scenes/maps/yggdrasil_24.tscn",
	&"yggdrasil_25": "res://scenes/maps/yggdrasil_25.tscn",
	&"yggdrasil_26": "res://scenes/maps/yggdrasil_26.tscn",
	&"yggdrasil_27": "res://scenes/maps/yggdrasil_27.tscn",
	&"yggdrasil_28": "res://scenes/maps/yggdrasil_28.tscn",
	&"yggdrasil_29": "res://scenes/maps/yggdrasil_29.tscn",
	&"yggdrasil_30": "res://scenes/maps/yggdrasil_30.tscn",
	&"yggdrasil_31": "res://scenes/maps/yggdrasil_31.tscn",
	&"yggdrasil_32": "res://scenes/maps/yggdrasil_32.tscn",
	&"yggdrasil_33": "res://scenes/maps/yggdrasil_33.tscn",
	&"yggdrasil_34": "res://scenes/maps/yggdrasil_34.tscn",
	&"yggdrasil_35": "res://scenes/maps/yggdrasil_35.tscn",
	&"yggdrasil_36": "res://scenes/maps/yggdrasil_36.tscn",
	&"yggdrasil_37": "res://scenes/maps/yggdrasil_37.tscn",
	&"yggdrasil_38": "res://scenes/maps/yggdrasil_38.tscn",
	&"yggdrasil_39": "res://scenes/maps/yggdrasil_39.tscn",
	&"yggdrasil_40": "res://scenes/maps/yggdrasil_40.tscn",
	&"yggdrasil_41": "res://scenes/maps/yggdrasil_41.tscn",
	&"yggdrasil_42": "res://scenes/maps/yggdrasil_42.tscn",
	&"yggdrasil_43": "res://scenes/maps/yggdrasil_43.tscn",
	&"yggdrasil_44": "res://scenes/maps/yggdrasil_44.tscn",
	&"yggdrasil_45": "res://scenes/maps/yggdrasil_45.tscn",
	&"yggdrasil_46": "res://scenes/maps/yggdrasil_46.tscn",
	&"yggdrasil_47": "res://scenes/maps/yggdrasil_47.tscn",
	&"yggdrasil_48": "res://scenes/maps/yggdrasil_48.tscn",
	&"yggdrasil_49": "res://scenes/maps/yggdrasil_49.tscn",
	&"yggdrasil_50": "res://scenes/maps/yggdrasil_50.tscn",
	# ★ รอบ 179 ★ ชั้น 51-100
	&"yggdrasil_51": "res://scenes/maps/yggdrasil_51.tscn",
	&"yggdrasil_52": "res://scenes/maps/yggdrasil_52.tscn",
	&"yggdrasil_53": "res://scenes/maps/yggdrasil_53.tscn",
	&"yggdrasil_54": "res://scenes/maps/yggdrasil_54.tscn",
	&"yggdrasil_55": "res://scenes/maps/yggdrasil_55.tscn",
	&"yggdrasil_56": "res://scenes/maps/yggdrasil_56.tscn",
	&"yggdrasil_57": "res://scenes/maps/yggdrasil_57.tscn",
	&"yggdrasil_58": "res://scenes/maps/yggdrasil_58.tscn",
	&"yggdrasil_59": "res://scenes/maps/yggdrasil_59.tscn",
	&"yggdrasil_60": "res://scenes/maps/yggdrasil_60.tscn",
	&"yggdrasil_61": "res://scenes/maps/yggdrasil_61.tscn",
	&"yggdrasil_62": "res://scenes/maps/yggdrasil_62.tscn",
	&"yggdrasil_63": "res://scenes/maps/yggdrasil_63.tscn",
	&"yggdrasil_64": "res://scenes/maps/yggdrasil_64.tscn",
	&"yggdrasil_65": "res://scenes/maps/yggdrasil_65.tscn",
	&"yggdrasil_66": "res://scenes/maps/yggdrasil_66.tscn",
	&"yggdrasil_67": "res://scenes/maps/yggdrasil_67.tscn",
	&"yggdrasil_68": "res://scenes/maps/yggdrasil_68.tscn",
	&"yggdrasil_69": "res://scenes/maps/yggdrasil_69.tscn",
	&"yggdrasil_70": "res://scenes/maps/yggdrasil_70.tscn",
	&"yggdrasil_71": "res://scenes/maps/yggdrasil_71.tscn",
	&"yggdrasil_72": "res://scenes/maps/yggdrasil_72.tscn",
	&"yggdrasil_73": "res://scenes/maps/yggdrasil_73.tscn",
	&"yggdrasil_74": "res://scenes/maps/yggdrasil_74.tscn",
	&"yggdrasil_75": "res://scenes/maps/yggdrasil_75.tscn",
	&"yggdrasil_76": "res://scenes/maps/yggdrasil_76.tscn",
	&"yggdrasil_77": "res://scenes/maps/yggdrasil_77.tscn",
	&"yggdrasil_78": "res://scenes/maps/yggdrasil_78.tscn",
	&"yggdrasil_79": "res://scenes/maps/yggdrasil_79.tscn",
	&"yggdrasil_80": "res://scenes/maps/yggdrasil_80.tscn",
	&"yggdrasil_81": "res://scenes/maps/yggdrasil_81.tscn",
	&"yggdrasil_82": "res://scenes/maps/yggdrasil_82.tscn",
	&"yggdrasil_83": "res://scenes/maps/yggdrasil_83.tscn",
	&"yggdrasil_84": "res://scenes/maps/yggdrasil_84.tscn",
	&"yggdrasil_85": "res://scenes/maps/yggdrasil_85.tscn",
	&"yggdrasil_86": "res://scenes/maps/yggdrasil_86.tscn",
	&"yggdrasil_87": "res://scenes/maps/yggdrasil_87.tscn",
	&"yggdrasil_88": "res://scenes/maps/yggdrasil_88.tscn",
	&"yggdrasil_89": "res://scenes/maps/yggdrasil_89.tscn",
	&"yggdrasil_90": "res://scenes/maps/yggdrasil_90.tscn",
	&"yggdrasil_91": "res://scenes/maps/yggdrasil_91.tscn",
	&"yggdrasil_92": "res://scenes/maps/yggdrasil_92.tscn",
	&"yggdrasil_93": "res://scenes/maps/yggdrasil_93.tscn",
	&"yggdrasil_94": "res://scenes/maps/yggdrasil_94.tscn",
	&"yggdrasil_95": "res://scenes/maps/yggdrasil_95.tscn",
	&"yggdrasil_96": "res://scenes/maps/yggdrasil_96.tscn",
	&"yggdrasil_97": "res://scenes/maps/yggdrasil_97.tscn",
	&"yggdrasil_98": "res://scenes/maps/yggdrasil_98.tscn",
	&"yggdrasil_99": "res://scenes/maps/yggdrasil_99.tscn",
	&"yggdrasil_100": "res://scenes/maps/yggdrasil_100.tscn",

	&"yggdrasil_root": "res://scenes/maps/yggdrasil_root.tscn",
	&"yggdrasil_01": "res://scenes/maps/yggdrasil_01.tscn",
	&"yggdrasil_02": "res://scenes/maps/yggdrasil_02.tscn",
	&"yggdrasil_03": "res://scenes/maps/yggdrasil_03.tscn",
	&"yggdrasil_04": "res://scenes/maps/yggdrasil_04.tscn",
	&"yggdrasil_05": "res://scenes/maps/yggdrasil_05.tscn",
	&"yggdrasil_06": "res://scenes/maps/yggdrasil_06.tscn",
	&"yggdrasil_07": "res://scenes/maps/yggdrasil_07.tscn",
	&"yggdrasil_08": "res://scenes/maps/yggdrasil_08.tscn",
	&"yggdrasil_09": "res://scenes/maps/yggdrasil_09.tscn",
	&"yggdrasil_10": "res://scenes/maps/yggdrasil_10.tscn",
	&"yggdrasil_11": "res://scenes/maps/yggdrasil_11.tscn",
	&"yggdrasil_12": "res://scenes/maps/yggdrasil_12.tscn",
	&"yggdrasil_13": "res://scenes/maps/yggdrasil_13.tscn",
	&"yggdrasil_14": "res://scenes/maps/yggdrasil_14.tscn",
	&"yggdrasil_15": "res://scenes/maps/yggdrasil_15.tscn",
	&"yggdrasil_16": "res://scenes/maps/yggdrasil_16.tscn",
	&"yggdrasil_17": "res://scenes/maps/yggdrasil_17.tscn",
	&"yggdrasil_18": "res://scenes/maps/yggdrasil_18.tscn",
	&"yggdrasil_19": "res://scenes/maps/yggdrasil_19.tscn",
	&"yggdrasil_20": "res://scenes/maps/yggdrasil_20.tscn",

	&"cinder_crossing": "res://scenes/maps/cinder_crossing.tscn",
	&"emberhaven": "res://scenes/maps/emberhaven.tscn",
	&"chain_quarry": "res://scenes/maps/chain_quarry.tscn",
	&"unwritten_forge": "res://scenes/maps/unwritten_forge.tscn",
	&"ash_procession": "res://scenes/maps/ash_procession.tscn",
	&"oathbreak_crucible": "res://scenes/maps/oathbreak_crucible.tscn",

	&"runeblade_training": "res://scenes/maps/runeblade_training.tscn",
	&"blackhorn_rootcrypt": "res://scenes/maps/blackhorn_rootcrypt.tscn",
	&"prontera_town": "res://scenes/maps/prontera_town.tscn",
	# ★ แมพนี้คือฉากที่คุณทำเอง (พื้นหลัง + TileMap ของคุณ)
	# รอบ 40: ย้ายจาก Sprites/world_node_2d.tscn มาไว้ให้ถูกที่ถูกชื่อ
	&"prontera_field": "res://scenes/maps/prontera_field.tscn",
	## ★ แมพใหม่ ★ Asgard Forest 2 (ต่อจากทุ่งของคุณไปทางขวา)
	&"asgard_forest_2": "res://scenes/maps/asgard_forest_2.tscn",
	&"dark_forest": "res://scenes/maps/dark_forest.tscn",
	## ★ บทที่ 2 — สวาร์ทัลฟ์เฮม (รอบ 31) ★
	&"iron_road": "res://scenes/maps/iron_road.tscn",
	&"nidavellir_town": "res://scenes/maps/nidavellir_town.tscn",
	&"ember_mine": "res://scenes/maps/ember_mine.tscn",
	&"hall_of_silence": "res://scenes/maps/hall_of_silence.tscn",
	&"cold_forge": "res://scenes/maps/cold_forge.tscn",
	## ★ ลานบอสบทที่ 1 (รอบ 38) ★
	&"thunder_scar": "res://scenes/maps/thunder_scar.tscn",
	## ★ ป่าเงาลึกชั้นใน (รอบ 44) — มอนบท 1 ที่เหลือ + บาฟโฟเมทเฝ้าทางไปบท 2 ★
	&"dark_forest_2": "res://scenes/maps/dark_forest_2.tscn",
	## ★ บทที่ 3 — วานาเฮม (รอบ 79) ★
	&"root_road": "res://scenes/maps/root_road.tscn",
	&"vanir_town": "res://scenes/maps/vanir_town.tscn",
	&"silver_marsh": "res://scenes/maps/silver_marsh.tscn",
	&"withered_grove": "res://scenes/maps/withered_grove.tscn",
	&"forgotten_battlefield": "res://scenes/maps/forgotten_battlefield.tscn",
	&"spring_of_life": "res://scenes/maps/spring_of_life.tscn",
	## ★ บทที่ 4 — โยตุนเฮม (รอบ 105) ★
	&"frost_pass": "res://scenes/maps/frost_pass.tscn",
	&"utgard_town": "res://scenes/maps/utgard_town.tscn",
	&"giant_steppe": "res://scenes/maps/giant_steppe.tscn",
	&"frozen_hall": "res://scenes/maps/frozen_hall.tscn",
	&"broken_wall": "res://scenes/maps/broken_wall.tscn",
	&"hrungnir_crater": "res://scenes/maps/hrungnir_crater.tscn",
	## ★ บทที่ 5 — อัลฟ์เฮม (รอบ 105) ★
	&"shimmer_road": "res://scenes/maps/shimmer_road.tscn",
	&"ljosalf_city": "res://scenes/maps/ljosalf_city.tscn",
	&"crystal_garden": "res://scenes/maps/crystal_garden.tscn",
	&"mirror_lake": "res://scenes/maps/mirror_lake.tscn",
	&"dimming_wood": "res://scenes/maps/dimming_wood.tscn",
	&"lightwell_sanctum": "res://scenes/maps/lightwell_sanctum.tscn",
	## ★ บทที่ 6 — นิฟล์เฮม + เฮลเฮม (รอบ 105) ★
	&"mist_shore": "res://scenes/maps/mist_shore.tscn",
	&"eljudnir": "res://scenes/maps/eljudnir.tscn",
	&"gjoll_river": "res://scenes/maps/gjoll_river.tscn",
	&"hall_of_names": "res://scenes/maps/hall_of_names.tscn",
	&"nastrond": "res://scenes/maps/nastrond.tscn",
	&"garm_gate": "res://scenes/maps/garm_gate.tscn",
	&"odin_seat": "res://scenes/maps/odin_seat.tscn",
	## ★ รอบ 80 — ห้องทดสอบ GM (ไม่เชื่อมกับแมพไหน เข้าได้จากหน้าต่าง F10 เท่านั้น) ★
	&"gm_room": "res://scenes/maps/gm_room.tscn",
}

## ★ รอบ 57 ★ ชื่อไทยของแมพ (ใช้ในเสาวาป/มินิแมพ) — ไม่มีในนี้จะใช้ id แทน
const MAP_NAMES := {
	&"yggdrasil_21": "อิกดราซิล ชั้น 21",
	&"yggdrasil_22": "อิกดราซิล ชั้น 22",
	&"yggdrasil_23": "อิกดราซิล ชั้น 23",
	&"yggdrasil_24": "อิกดราซิล ชั้น 24",
	&"yggdrasil_25": "อิกดราซิล ชั้น 25",
	&"yggdrasil_26": "อิกดราซิล ชั้น 26",
	&"yggdrasil_27": "อิกดราซิล ชั้น 27",
	&"yggdrasil_28": "อิกดราซิล ชั้น 28",
	&"yggdrasil_29": "อิกดราซิล ชั้น 29",
	&"yggdrasil_30": "อิกดราซิล ชั้น 30",
	&"yggdrasil_31": "อิกดราซิล ชั้น 31",
	&"yggdrasil_32": "อิกดราซิล ชั้น 32",
	&"yggdrasil_33": "อิกดราซิล ชั้น 33",
	&"yggdrasil_34": "อิกดราซิล ชั้น 34",
	&"yggdrasil_35": "อิกดราซิล ชั้น 35",
	&"yggdrasil_36": "อิกดราซิล ชั้น 36",
	&"yggdrasil_37": "อิกดราซิล ชั้น 37",
	&"yggdrasil_38": "อิกดราซิล ชั้น 38",
	&"yggdrasil_39": "อิกดราซิล ชั้น 39",
	&"yggdrasil_40": "อิกดราซิล ชั้น 40",
	&"yggdrasil_41": "อิกดราซิล ชั้น 41",
	&"yggdrasil_42": "อิกดราซิล ชั้น 42",
	&"yggdrasil_43": "อิกดราซิล ชั้น 43",
	&"yggdrasil_44": "อิกดราซิล ชั้น 44",
	&"yggdrasil_45": "อิกดราซิล ชั้น 45",
	&"yggdrasil_46": "อิกดราซิล ชั้น 46",
	&"yggdrasil_47": "อิกดราซิล ชั้น 47",
	&"yggdrasil_48": "อิกดราซิล ชั้น 48",
	&"yggdrasil_49": "อิกดราซิล ชั้น 49",
	&"yggdrasil_50": "อิกดราซิล ชั้น 50",
	&"yggdrasil_51": "อิกดราซิล ชั้น 51",
	&"yggdrasil_52": "อิกดราซิล ชั้น 52",
	&"yggdrasil_53": "อิกดราซิล ชั้น 53",
	&"yggdrasil_54": "อิกดราซิล ชั้น 54",
	&"yggdrasil_55": "อิกดราซิล ชั้น 55",
	&"yggdrasil_56": "อิกดราซิล ชั้น 56",
	&"yggdrasil_57": "อิกดราซิล ชั้น 57",
	&"yggdrasil_58": "อิกดราซิล ชั้น 58",
	&"yggdrasil_59": "อิกดราซิล ชั้น 59",
	&"yggdrasil_60": "อิกดราซิล ชั้น 60",
	&"yggdrasil_61": "อิกดราซิล ชั้น 61",
	&"yggdrasil_62": "อิกดราซิล ชั้น 62",
	&"yggdrasil_63": "อิกดราซิล ชั้น 63",
	&"yggdrasil_64": "อิกดราซิล ชั้น 64",
	&"yggdrasil_65": "อิกดราซิล ชั้น 65",
	&"yggdrasil_66": "อิกดราซิล ชั้น 66",
	&"yggdrasil_67": "อิกดราซิล ชั้น 67",
	&"yggdrasil_68": "อิกดราซิล ชั้น 68",
	&"yggdrasil_69": "อิกดราซิล ชั้น 69",
	&"yggdrasil_70": "อิกดราซิล ชั้น 70",
	&"yggdrasil_71": "อิกดราซิล ชั้น 71",
	&"yggdrasil_72": "อิกดราซิล ชั้น 72",
	&"yggdrasil_73": "อิกดราซิล ชั้น 73",
	&"yggdrasil_74": "อิกดราซิล ชั้น 74",
	&"yggdrasil_75": "อิกดราซิล ชั้น 75",
	&"yggdrasil_76": "อิกดราซิล ชั้น 76",
	&"yggdrasil_77": "อิกดราซิล ชั้น 77",
	&"yggdrasil_78": "อิกดราซิล ชั้น 78",
	&"yggdrasil_79": "อิกดราซิล ชั้น 79",
	&"yggdrasil_80": "อิกดราซิล ชั้น 80",
	&"yggdrasil_81": "อิกดราซิล ชั้น 81",
	&"yggdrasil_82": "อิกดราซิล ชั้น 82",
	&"yggdrasil_83": "อิกดราซิล ชั้น 83",
	&"yggdrasil_84": "อิกดราซิล ชั้น 84",
	&"yggdrasil_85": "อิกดราซิล ชั้น 85",
	&"yggdrasil_86": "อิกดราซิล ชั้น 86",
	&"yggdrasil_87": "อิกดราซิล ชั้น 87",
	&"yggdrasil_88": "อิกดราซิล ชั้น 88",
	&"yggdrasil_89": "อิกดราซิล ชั้น 89",
	&"yggdrasil_90": "อิกดราซิล ชั้น 90",
	&"yggdrasil_91": "อิกดราซิล ชั้น 91",
	&"yggdrasil_92": "อิกดราซิล ชั้น 92",
	&"yggdrasil_93": "อิกดราซิล ชั้น 93",
	&"yggdrasil_94": "อิกดราซิล ชั้น 94",
	&"yggdrasil_95": "อิกดราซิล ชั้น 95",
	&"yggdrasil_96": "อิกดราซิล ชั้น 96",
	&"yggdrasil_97": "อิกดราซิล ชั้น 97",
	&"yggdrasil_98": "อิกดราซิล ชั้น 98",
	&"yggdrasil_99": "อิกดราซิล ชั้น 99",
	&"yggdrasil_100": "อิกดราซิล ชั้น 100",

	&"yggdrasil_root": "อิกดราซิล จุดพักราก",
	&"yggdrasil_01": "อิกดราซิล ชั้น 1",
	&"yggdrasil_02": "อิกดราซิล ชั้น 2",
	&"yggdrasil_03": "อิกดราซิล ชั้น 3",
	&"yggdrasil_04": "อิกดราซิล ชั้น 4",
	&"yggdrasil_05": "อิกดราซิล ชั้น 5",
	&"yggdrasil_06": "อิกดราซิล ชั้น 6",
	&"yggdrasil_07": "อิกดราซิล ชั้น 7",
	&"yggdrasil_08": "อิกดราซิล ชั้น 8",
	&"yggdrasil_09": "อิกดราซิล ชั้น 9",
	&"yggdrasil_10": "อิกดราซิล ชั้น 10",
	&"yggdrasil_11": "อิกดราซิล ชั้น 11",
	&"yggdrasil_12": "อิกดราซิล ชั้น 12",
	&"yggdrasil_13": "อิกดราซิล ชั้น 13",
	&"yggdrasil_14": "อิกดราซิล ชั้น 14",
	&"yggdrasil_15": "อิกดราซิล ชั้น 15",
	&"yggdrasil_16": "อิกดราซิล ชั้น 16",
	&"yggdrasil_17": "อิกดราซิล ชั้น 17",
	&"yggdrasil_18": "อิกดราซิล ชั้น 18",
	&"yggdrasil_19": "อิกดราซิล ชั้น 19",
	&"yggdrasil_20": "อิกดราซิล ชั้น 20",

	&"cinder_crossing": "ทางข้ามเถ้า",
	&"emberhaven": "อัมเบอร์เฮเวน นครใต้เถ้า",
	&"chain_quarry": "เหมืองโซ่คำสั่ง",
	&"unwritten_forge": "เตาหลอมไร้คำสั่ง",
	&"ash_procession": "ทางขบวนเถ้า",
	&"oathbreak_crucible": "เบ้าหลอมคำสาบาน",

	&"runeblade_training": "ลานทดสอบดาบรูน",
	&"blackhorn_rootcrypt": "วิหารเขาทมิฬใต้ราก",
	&"prontera_town": "เมืองพรอนเทรา",
	&"prontera_field": "ทุ่งวิหาร",
	&"asgard_forest_2": "ป่าแอสการ์ด 2",
	&"dark_forest": "ป่าเงาลึก",
	&"dark_forest_2": "ป่าเงาลึกชั้นใน",
	&"thunder_scar": "รอยสายฟ้า",
	&"iron_road": "ถนนเหล็ก",
	&"nidavellir_town": "เมืองนิดาเวลลีร์",
	&"ember_mine": "เหมืองถ่านไฟ",
	&"hall_of_silence": "ห้องโถงแห่งความเงียบ",
	&"cold_forge": "เตาหลอมเย็น",
	&"root_road": "ทางสายราก",
	&"vanir_town": "วานาเฮม นครแห่งราก",
	&"silver_marsh": "บึงหมอกเงิน",
	&"withered_grove": "ป่าเหี่ยว",
	&"forgotten_battlefield": "สมรภูมิที่ถูกลืม",
	&"spring_of_life": "บ่อน้ำแห่งชีวิต",
	&"frost_pass": "ช่องเขาน้ำแข็ง",
	&"utgard_town": "อุทการ์ด นครแห่งยักษ์",
	&"giant_steppe": "ทุ่งหญ้ายักษ์",
	&"frozen_hall": "โถงภาพวาดน้ำแข็ง",
	&"broken_wall": "กำแพงที่แตก",
	&"hrungnir_crater": "หลุมหัวใจสายฟ้า",
	&"shimmer_road": "ทางประกายแสง",
	&"ljosalf_city": "ลโยซาลฟ์ นครแห่งแสง",
	&"crystal_garden": "สวนผลึก",
	&"mirror_lake": "ทะเลสาบกระจก",
	&"dimming_wood": "ป่าที่แสงจาง",
	&"lightwell_sanctum": "วิหารบ่อแสง",
	&"mist_shore": "ฝั่งหมอกน้ำแข็ง",
	&"eljudnir": "เอลยุดเนียร์ เมืองของผู้ตาย",
	&"gjoll_river": "แม่น้ำเกียลล์",
	&"hall_of_names": "โถงแห่งนาม",
	&"nastrond": "นาสตรอนด์ ฝั่งศพ",
	&"garm_gate": "ประตูของการ์ม",
	&"odin_seat": "บัลลังก์ว่างของโอดิน",
	&"gm_room": "★ ห้อง GM (ทดสอบ)",
}


## ★ รอบ 60 ★ แมพไหนนับเป็น "เมือง" (ใช้กับปีกแห่งวาลคีรี · จุดเกิดใหม่ตอนตาย)
## เพิ่มเมืองใหม่ = เพิ่ม id ตรงนี้บรรทัดเดียว
const TOWNS := [&"emberhaven", &"prontera_town", &"nidavellir_town", &"vanir_town", &"utgard_town", &"ljosalf_city", &"eljudnir"]


## ชื่อแมพที่เอาไว้โชว์ให้ผู้เล่นอ่าน
func map_display_name(map_id: StringName) -> String:
	return String(MAP_NAMES.get(map_id, String(map_id)))


func is_town(map_id: StringName) -> bool:
	return TOWNS.has(map_id)


## ★ วาปกลับเมือง ★ ★ รอบ 120 ★ กลับ "เมืองที่บันทึกจุดเกิดไว้" (เสาวาป → บันทึกจุดเกิด · ไม่เคยบันทึก = พรอนเทรา) — เดิมเป็นเมืองล่าสุดที่แวะ
## ใช้โดยปีกแห่งวาลคีรี — คืน false ถ้าวาปไม่ได้ (อยู่ในเมืองนั้นอยู่แล้ว / กำลังเปลี่ยนแมพ)
func warp_to_town(spawn_point: StringName = &"default") -> bool:
	if _is_changing:
		return false
	var town := PlayerState.saved_respawn_town()
	if PlayerState.current_map_id == town:
		return false
	change_map(town, spawn_point)
	return true


var _spawn_point_name: StringName = &"default"
var _is_changing := false
var _fade: ColorRect
var _loading_label: Label
## ฉากเปล่าที่ใช้คั่นระหว่างโหลดแมพ (ปล่อยแมพเก่าทิ้งก่อน แล้วค่อยโหลดแมพใหม่)
var _loading_scene: PackedScene

## ★ รอบ 40 — จำแมพที่เคยโหลดไว้ (เข้า-ออกแมพเดิมไม่ต้องโหลดซ้ำ = ไม่กระตุก) ★
## เก็บสูงสุด MAX_CACHED แมพล่าสุด กันกินแรมเกินไป
##
## ★★ รอบ 90 ★★ ลด 4 → 2 และเว็บไม่แคชเลย
## แมพที่ค้างในแคชยัง "ถือ" ชีทภาพมอนของแมพนั้นไว้ทั้งหมด (ตัวละ 30-50 MB)
## แคช 4 แมพ = ชีทมอนค้างในหน่วยความจำถึง 4 แมพพร้อมกัน — บนเว็บทำให้แท็บเด้ง
const MAX_CACHED_DESKTOP := 2
const MAX_CACHED_WEB := 0
var _scene_cache: Dictionary = {}      # path -> PackedScene
var _cache_order: Array[String] = []

func _max_cached() -> int:
	return MAX_CACHED_WEB if OS.has_feature("web") else MAX_CACHED_DESKTOP


## ★ รอบ 52 — เพลงประจำแมพ ★ เรียกใช้ผ่าน Game.music (ดู scripts/core/music_player.gd)
var music: MusicPlayer
## ★ รอบ 57 — เสียงเอฟเฟกต์ ★ เรียกใช้ผ่าน Game.sfx.play("attack_blade")
var sfx: SfxPlayer
## ★ รอบ 59 — เสียงพากย์ NPC ★ วางไฟล์ Sprites/voice/<voice_id>/<key>.ogg → Game.voice.play("hans", "greeting")
var voice: VoicePlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Loc.init()   # ★ รอบ 161 ★ ภาษา (ไทย/English)
	InputSetup.ensure()
	_build_fade()
	music = MusicPlayer.new()
	add_child(music)
	sfx = SfxPlayer.new()
	add_child(sfx)
	voice = VoicePlayer.new()
	add_child(voice)
	var loading_root := Node.new()
	loading_root.name = "Loading"
	_loading_scene = PackedScene.new()
	_loading_scene.pack(loading_root)
	loading_root.free()


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)

	# ป้าย "กำลังโหลด..." โผล่เฉพาะตอนโหลดแมพที่ยังไม่เคยโหลดจริง ๆ
	_loading_label = Label.new()
	_loading_label.text = "กำลังโหลด..."
	_loading_label.add_theme_font_size_override("font_size", 22)
	_loading_label.add_theme_color_override("font_color", Color("#e8e2d0"))
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_loading_label.offset_left = -220
	_loading_label.offset_top = -60
	_loading_label.offset_right = -28
	_loading_label.offset_bottom = -24
	_loading_label.hide()
	layer.add_child(_loading_label)


## ชื่อจุดเกิดที่แมพปลายทางควรวางผู้เล่นไว้
func requested_spawn_point() -> StringName:
	return _spawn_point_name


func change_map(map_id: StringName, spawn_point: StringName = &"default") -> void:
	if not String(map_id).begins_with("yggdrasil_"): preload("res://scripts/world/chapter8_tower_data.gd").gm_test = false
	Engine.time_scale = 1.0   # ★ รอบ 150 ★ กันสโลว์โมชั่นคริค้างข้ามแมพ
	if _is_changing:
		return
	var path: String = MAPS.get(map_id, "")
	if path == "":
		push_error("[Game] ไม่รู้จักแมพ: " + String(map_id))
		return

	_is_changing = true
	_spawn_point_name = spawn_point
	SaveManager.end_session()
	PlayerState.current_map_id = map_id

	await _fade_to(1.0, 0.25)
	# ★★ รอบ 40 — โหลดแมพแบบเบื้องหลัง (ไม่ค้างเกมระหว่างอ่านไฟล์ภาพใหญ่) ★★
	# ★ ต้องสลับไปฉากเปล่าก่อนโหลด ★ ถ้าปล่อยแมพเก่าทำงานระหว่างโหลดเธรด
	# ตัวโหลดจะแย่งแตะรีซอร์สชุดเดียวกันแล้วแครช (signal 11 — เจอตอนเทสต์รอบ 40)
	if not _scene_cache.has(path):
		get_tree().change_scene_to_packed(_loading_scene)
		await get_tree().process_frame
		await get_tree().process_frame
		# Old scene is gone: release cached sheets before loading the next map.
		GameData.release_monsters_except([])
		await get_tree().process_frame
	var scene: PackedScene = await _load_map_scene(path)
	if scene == null:
		push_error("[Game] โหลดแมพไม่สำเร็จ: " + path)
		_is_changing = false
		await _fade_to(0.0, 0.2)
		return
	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	# ★ รอบ 90 ★ ปล่อยชีทมอนของแมพก่อนหน้าที่แมพนี้ไม่ได้ใช้
	_release_unused_monsters()
	Events.map_changed.emit(map_id)
	await _fade_to(0.0, 0.3)
	_is_changing = false
	SaveManager.activate()


## ★ รอบ 90 ★ คืนหน่วยความจำชีทมอนที่แมพปัจจุบันไม่ได้ใช้
## แมพถือ MonsterData ของตัวเองอยู่แล้ว (ช่อง monster_types ของ MapSpawner)
## ตัวที่ค้างอยู่ในแคชของ GameData เฉย ๆ จึงปล่อยได้ — ถูกเรียกใหม่เมื่อไหร่ก็โหลดกลับมาเอง
func _release_unused_monsters() -> void:
	var keep: Array = []
	var root := get_tree().current_scene
	if root != null:
		for node in _walk(root):
			if "monster_types" in node:
				for md in node.monster_types:
					if md != null:
						keep.append(StringName(md.id))
			if "data" in node and node.data != null and node.data is MonsterData:
				keep.append(StringName(node.data.id))
	var dropped: int = GameData.release_monsters_except(keep)
	if dropped > 0:
		print("[Game] ปล่อยชีทมอนที่ไม่ได้ใช้ %d ตัว (แมพนี้ใช้ %d)" % [dropped, keep.size()])


func _walk(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_walk(c))
	return out


## โหลดไฟล์ฉากแบบไม่บล็อกเกม + จำไว้ในแคช
func _load_map_scene(path: String) -> PackedScene:
	if _scene_cache.has(path):
		# ขยับขึ้นเป็นตัวล่าสุด
		_cache_order.erase(path)
		_cache_order.append(path)
		return _scene_cache[path]

	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		return load(path) as PackedScene   # ทางถอย: โหลดแบบเดิม

	_loading_label.show()
	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_loading_label.hide()
			return load(path) as PackedScene
		await get_tree().process_frame
	_loading_label.hide()

	var scene := ResourceLoader.load_threaded_get(path) as PackedScene
	if scene != null and _max_cached() > 0:
		_scene_cache[path] = scene
		_cache_order.append(path)
		while _cache_order.size() > _max_cached():
			var old_path: String = _cache_order.pop_front()
			_scene_cache.erase(old_path)
	return scene


## ★ กลับหน้าหลัก (รอบ 32) ★
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

func go_title() -> void:
	if _is_changing:
		return
	SaveManager.save_auto()
	SaveManager.end_session()
	_is_changing = true
	get_tree().paused = false
	if UI != null:
		UI.set_in_game(false)
	await _fade_to(1.0, 0.3)
	get_tree().change_scene_to_file(TITLE_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, 0.3)
	_is_changing = false


func reload_map() -> void:
	await change_map(PlayerState.current_map_id, _spawn_point_name)


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, duration)
	await tween.finished


## เรียกตอนผู้เล่นตาย: กลับเมืองพร้อมฟื้นเลือดครึ่งหนึ่ง
func respawn_in_town() -> void:
	PlayerState.revive(0.5)
	await change_map(PlayerState.saved_respawn_town(), &"default")
